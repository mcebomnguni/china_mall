-- ============================================================
-- China Stall — A6 Orders, Roles, Financial, Account Mgmt, Security
-- Run AFTER admin_a3_a4_a5_migration.sql
-- ============================================================


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  ADMIN ROLES: super_admin / admin / staff                   ║
-- ╚══════════════════════════════════════════════════════════════╝

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS admin_level text;
-- Values: 'super_admin', 'admin', NULL (base staff)
-- Only meaningful when role IN ('admin','staff')

-- Super admin can create other admins
CREATE OR REPLACE FUNCTION admin_create_admin(
  p_caller_id  uuid,
  p_email      text,
  p_full_name  text,
  p_role       text DEFAULT 'admin',
  p_admin_level text DEFAULT 'admin'
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_caller_level text;
  v_new_id       uuid;
BEGIN
  SELECT admin_level INTO v_caller_level FROM profiles WHERE id = p_caller_id;
  IF v_caller_level != 'super_admin' THEN
    RAISE EXCEPTION 'Only super_admin can create admin accounts';
  END IF;

  -- Find or verify user exists in auth
  SELECT id INTO v_new_id FROM profiles WHERE email = p_email;
  IF v_new_id IS NULL THEN
    RAISE EXCEPTION 'User with email % must register first, then be promoted', p_email;
  END IF;

  UPDATE profiles
  SET role        = p_role,
      admin_level = p_admin_level,
      full_name   = COALESCE(NULLIF(p_full_name,''), full_name),
      updated_at  = now()
  WHERE id = v_new_id;

  INSERT INTO notifications (profile_id, title, body, data) VALUES (
    v_new_id,
    'Admin Access Granted',
    'You have been granted ' || p_admin_level || ' access to China Stall admin portal.',
    jsonb_build_object('type','admin_promoted','level', p_admin_level)
  );

  RETURN v_new_id;
END;
$$;

-- List all admin/staff users
CREATE OR REPLACE FUNCTION admin_list_admins()
RETURNS TABLE (
  profile_id  uuid,
  email       text,
  full_name   text,
  role        text,
  admin_level text,
  created_at  timestamptz
) LANGUAGE sql SECURITY DEFINER AS $$
  SELECT id, email, full_name, role, admin_level, created_at
  FROM profiles
  WHERE role IN ('admin','staff')
  ORDER BY admin_level DESC NULLS LAST, created_at;
$$;


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  A6: ORDER MONITORING + HANDOFF CONFIRMATIONS               ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Delivery handoff confirmations with codes
CREATE TABLE IF NOT EXISTS delivery_handoffs (
  id              bigserial PRIMARY KEY,
  delivery_id     bigint REFERENCES deliveries(id) ON DELETE CASCADE,
  order_id        bigint REFERENCES orders(id) ON DELETE CASCADE,
  stage           text NOT NULL CHECK (stage IN (
    'store_packed','courier_picked_up','in_transit','delivered'
  )),
  confirmation_code text NOT NULL,          -- 6-digit code
  confirmed_by    uuid REFERENCES profiles(id),
  confirmed_at    timestamptz,
  notes           text,
  created_at      timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_handoffs_order    ON delivery_handoffs(order_id);
CREATE INDEX IF NOT EXISTS idx_handoffs_delivery ON delivery_handoffs(delivery_id);

ALTER TABLE delivery_handoffs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_all_handoffs" ON delivery_handoffs;
CREATE POLICY "admin_all_handoffs" ON delivery_handoffs FOR ALL
  USING  (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')));

-- Vendors/couriers can confirm their own handoffs
DROP POLICY IF EXISTS "participants_confirm_handoffs" ON delivery_handoffs;
CREATE POLICY "participants_confirm_handoffs" ON delivery_handoffs FOR ALL
  USING (
    confirmed_by = auth.uid()
    OR order_id IN (SELECT id FROM orders WHERE profile_id = auth.uid())
  )
  WITH CHECK (confirmed_by = auth.uid());

-- Generate handoff codes when order status changes
CREATE OR REPLACE FUNCTION generate_handoff_code()
RETURNS text LANGUAGE sql AS $$
  SELECT lpad(floor(random() * 1000000)::text, 6, '0');
$$;

-- Create handoff entry for an order
CREATE OR REPLACE FUNCTION create_order_handoff(
  p_order_id    bigint,
  p_delivery_id bigint,
  p_stage       text
) RETURNS text LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_code text;
BEGIN
  v_code := generate_handoff_code();

  INSERT INTO delivery_handoffs (delivery_id, order_id, stage, confirmation_code)
  VALUES (p_delivery_id, p_order_id, p_stage, v_code);

  RETURN v_code;
END;
$$;

-- Confirm a handoff with code
CREATE OR REPLACE FUNCTION confirm_handoff(
  p_order_id bigint,
  p_stage    text,
  p_code     text,
  p_user_id  uuid
) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_handoff delivery_handoffs%ROWTYPE;
BEGIN
  SELECT * INTO v_handoff FROM delivery_handoffs
  WHERE order_id = p_order_id AND stage = p_stage AND confirmed_at IS NULL
  ORDER BY created_at DESC LIMIT 1;

  IF NOT FOUND THEN RETURN false; END IF;
  IF v_handoff.confirmation_code != p_code THEN RETURN false; END IF;

  UPDATE delivery_handoffs
  SET confirmed_by = p_user_id, confirmed_at = now()
  WHERE id = v_handoff.id;

  RETURN true;
END;
$$;

-- Admin: list all orders with status + handoff info
CREATE OR REPLACE FUNCTION admin_orders_overview(
  p_status text DEFAULT NULL,
  p_days   integer DEFAULT 30
) RETURNS TABLE (
  order_id         bigint,
  customer_name    text,
  customer_email   text,
  total_amount     numeric,
  order_status     text,
  item_count       bigint,
  store_names      text,
  created_at       timestamptz,
  delivery_status  text,
  last_handoff     text,
  courier_name     text
) LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    o.id,
    pr.full_name,
    pr.email,
    o.total_amount,
    o.status::text,
    (SELECT count(*) FROM order_items WHERE order_id = o.id),
    (SELECT string_agg(DISTINCT s.name, ', ')
     FROM order_items oi2
     JOIN products p2 ON p2.id = oi2.product_id
     JOIN stores s ON s.id = p2.store_id
     WHERE oi2.order_id = o.id),
    o.created_at,
    d.status,
    (SELECT stage FROM delivery_handoffs
     WHERE order_id = o.id AND confirmed_at IS NOT NULL
     ORDER BY confirmed_at DESC LIMIT 1),
    (SELECT pr2.full_name FROM drivers dr
     JOIN profiles pr2 ON pr2.id = dr.profile_id
     WHERE dr.id = d.driver_id LIMIT 1)
  FROM orders o
  LEFT JOIN profiles pr ON pr.id = o.profile_id
  LEFT JOIN deliveries d ON d.order_id = o.id
  WHERE o.created_at >= now() - (p_days || ' days')::interval
    AND (p_status IS NULL OR o.status::text = p_status)
  ORDER BY o.created_at DESC;
$$;

-- Admin: get handoff trail for a single order
CREATE OR REPLACE FUNCTION admin_order_handoffs(p_order_id bigint)
RETURNS TABLE (
  stage             text,
  confirmation_code text,
  confirmed_by_name text,
  confirmed_at      timestamptz,
  created_at        timestamptz
) LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    dh.stage,
    dh.confirmation_code,
    pr.full_name,
    dh.confirmed_at,
    dh.created_at
  FROM delivery_handoffs dh
  LEFT JOIN profiles pr ON pr.id = dh.confirmed_by
  WHERE dh.order_id = p_order_id
  ORDER BY dh.created_at;
$$;


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  ENHANCED FINANCIAL: Refunds, Ledger, Geographic            ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ── Refunds table ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS refunds (
  id            bigserial PRIMARY KEY,
  order_id      bigint REFERENCES orders(id) ON DELETE SET NULL,
  payment_id    bigint REFERENCES payments(id) ON DELETE SET NULL,
  profile_id    uuid REFERENCES profiles(id) ON DELETE SET NULL,
  amount        numeric(12,2) NOT NULL,
  reason        text,
  status        text DEFAULT 'pending' CHECK (status IN ('pending','approved','processed','rejected')),
  processed_by  uuid REFERENCES profiles(id),
  processed_at  timestamptz,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now()
);

ALTER TABLE refunds ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_all_refunds" ON refunds;
CREATE POLICY "admin_all_refunds" ON refunds FOR ALL
  USING  (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')));

DROP POLICY IF EXISTS "users_own_refunds" ON refunds;
CREATE POLICY "users_own_refunds" ON refunds FOR SELECT
  USING (profile_id = auth.uid());

-- ── Financial ledger (super_admin bookkeeping) ──────────────
CREATE TABLE IF NOT EXISTS financial_entries (
  id              bigserial PRIMARY KEY,
  entry_date      date NOT NULL DEFAULT current_date,
  category        text NOT NULL CHECK (category IN (
    'revenue','cost_of_goods','operating_expense','commission_income',
    'payout_expense','refund_expense','delivery_fee_income','other_income','other_expense'
  )),
  description     text NOT NULL,
  debit_amount    numeric(12,2) DEFAULT 0,
  credit_amount   numeric(12,2) DEFAULT 0,
  reference_type  text,  -- 'order','payout','refund','manual'
  reference_id    bigint,
  created_by      uuid REFERENCES profiles(id),
  created_at      timestamptz DEFAULT now()
);

ALTER TABLE financial_entries ENABLE ROW LEVEL SECURITY;

-- Only super_admin can access financial entries
DROP POLICY IF EXISTS "super_admin_financial" ON financial_entries;
CREATE POLICY "super_admin_financial" ON financial_entries FOR ALL
  USING  (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND admin_level = 'super_admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND admin_level = 'super_admin'));

-- ── Store geographic data ───────────────────────────────────
ALTER TABLE stores ADD COLUMN IF NOT EXISTS province text;
ALTER TABLE stores ADD COLUMN IF NOT EXISTS city text;
ALTER TABLE stores ADD COLUMN IF NOT EXISTS area text;

-- ── Financial summary functions (super_admin only) ──────────

-- Revenue by store (with geographic breakdown)
CREATE OR REPLACE FUNCTION admin_financial_by_store(p_days integer DEFAULT 30)
RETURNS TABLE (
  store_id     bigint,
  store_name   text,
  province     text,
  city         text,
  gross_sales  numeric,
  commission   numeric,
  net_to_store numeric,
  order_count  bigint
) LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    s.id,
    s.name,
    s.province,
    s.city,
    COALESCE(sum(oi.quantity * oi.unit_price), 0)  AS gross_sales,
    COALESCE(sum(oi.quantity * oi.unit_price), 0) *
      COALESCE((SELECT commission_pct FROM payout_schedules
                WHERE entity_type = 'store' AND entity_id = s.id LIMIT 1), 10) / 100
      AS commission,
    COALESCE(sum(oi.quantity * oi.unit_price), 0) *
      (1 - COALESCE((SELECT commission_pct FROM payout_schedules
                     WHERE entity_type = 'store' AND entity_id = s.id LIMIT 1), 10) / 100)
      AS net_to_store,
    count(DISTINCT o.id)::bigint
  FROM stores s
  LEFT JOIN products p ON p.store_id = s.id
  LEFT JOIN order_items oi ON oi.product_id = p.id
  LEFT JOIN orders o ON o.id = oi.order_id
    AND o.created_at >= now() - (p_days || ' days')::interval
    AND o.status NOT IN ('pending_payment','cancelled')
  GROUP BY s.id, s.name, s.province, s.city
  ORDER BY 5 DESC NULLS LAST;
$$;

-- Revenue by courier
CREATE OR REPLACE FUNCTION admin_financial_by_courier(p_days integer DEFAULT 30)
RETURNS TABLE (
  driver_id        bigint,
  courier_name     text,
  deliveries_done  bigint,
  gross_earnings   numeric,
  commission       numeric,
  net_to_courier   numeric
) LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    dr.id,
    pr.full_name,
    count(d.id)::bigint AS deliveries_done,
    count(d.id) * 50.00 AS gross_earnings,  -- flat R50 per delivery (configurable)
    count(d.id) * 50.00 *
      COALESCE((SELECT commission_pct FROM payout_schedules
                WHERE entity_type = 'courier' AND entity_id = dr.id LIMIT 1), 5) / 100
      AS commission,
    count(d.id) * 50.00 *
      (1 - COALESCE((SELECT commission_pct FROM payout_schedules
                     WHERE entity_type = 'courier' AND entity_id = dr.id LIMIT 1), 5) / 100)
      AS net_to_courier
  FROM drivers dr
  JOIN profiles pr ON pr.id = dr.profile_id
  LEFT JOIN deliveries d ON d.driver_id = dr.id
    AND d.status = 'delivered'
    AND d.created_at >= now() - (p_days || ' days')::interval
  GROUP BY dr.id, pr.full_name
  ORDER BY 3 DESC;
$$;

-- Refund summary
CREATE OR REPLACE FUNCTION admin_refund_summary(p_days integer DEFAULT 30)
RETURNS TABLE (
  refund_id      bigint,
  customer_name  text,
  customer_email text,
  order_id       bigint,
  amount         numeric,
  reason         text,
  status         text,
  created_at     timestamptz
) LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    r.id, pr.full_name, pr.email, r.order_id, r.amount, r.reason, r.status, r.created_at
  FROM refunds r
  LEFT JOIN profiles pr ON pr.id = r.profile_id
  WHERE r.created_at >= now() - (p_days || ' days')::interval
  ORDER BY r.created_at DESC;
$$;

-- Process refund
CREATE OR REPLACE FUNCTION admin_process_refund(
  p_refund_id bigint,
  p_admin_id  uuid,
  p_action    text  -- 'approved','rejected'
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_ref refunds%ROWTYPE;
BEGIN
  SELECT * INTO v_ref FROM refunds WHERE id = p_refund_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Refund not found'; END IF;

  UPDATE refunds
  SET status       = CASE WHEN p_action = 'approved' THEN 'processed' ELSE 'rejected' END,
      processed_by = p_admin_id,
      processed_at = now(),
      updated_at   = now()
  WHERE id = p_refund_id;

  INSERT INTO notifications (profile_id, title, body, data) VALUES (
    v_ref.profile_id,
    CASE WHEN p_action = 'approved' THEN 'Refund Approved' ELSE 'Refund Declined' END,
    CASE WHEN p_action = 'approved'
      THEN 'Your refund of R ' || v_ref.amount || ' has been approved and will be processed.'
      ELSE 'Your refund request of R ' || v_ref.amount || ' was declined.'
    END,
    jsonb_build_object('type','refund_' || p_action, 'refund_id', p_refund_id)
  );
END;
$$;

-- Geographic demand analysis (province/city level)
CREATE OR REPLACE FUNCTION admin_geographic_demand(p_days integer DEFAULT 30)
RETURNS TABLE (
  province     text,
  city         text,
  order_count  bigint,
  revenue      numeric,
  store_count  bigint
) LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    COALESCE(s.province, 'Unknown'),
    COALESCE(s.city, 'Unknown'),
    count(DISTINCT o.id)::bigint,
    COALESCE(sum(oi.quantity * oi.unit_price), 0),
    count(DISTINCT s.id)::bigint
  FROM stores s
  LEFT JOIN products p ON p.store_id = s.id
  LEFT JOIN order_items oi ON oi.product_id = p.id
  LEFT JOIN orders o ON o.id = oi.order_id
    AND o.created_at >= now() - (p_days || ' days')::interval
    AND o.status NOT IN ('pending_payment','cancelled')
  GROUP BY s.province, s.city
  ORDER BY 4 DESC NULLS LAST;
$$;

-- Financial books: Income Statement summary
CREATE OR REPLACE FUNCTION admin_income_statement(p_from date, p_to date)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER AS $$
  SELECT jsonb_build_object(
    'revenue',           COALESCE((SELECT sum(credit_amount) FROM financial_entries WHERE category = 'revenue' AND entry_date BETWEEN p_from AND p_to), 0),
    'commission_income', COALESCE((SELECT sum(credit_amount) FROM financial_entries WHERE category = 'commission_income' AND entry_date BETWEEN p_from AND p_to), 0),
    'delivery_fee_income', COALESCE((SELECT sum(credit_amount) FROM financial_entries WHERE category = 'delivery_fee_income' AND entry_date BETWEEN p_from AND p_to), 0),
    'other_income',      COALESCE((SELECT sum(credit_amount) FROM financial_entries WHERE category = 'other_income' AND entry_date BETWEEN p_from AND p_to), 0),
    'cost_of_goods',     COALESCE((SELECT sum(debit_amount) FROM financial_entries WHERE category = 'cost_of_goods' AND entry_date BETWEEN p_from AND p_to), 0),
    'operating_expense', COALESCE((SELECT sum(debit_amount) FROM financial_entries WHERE category = 'operating_expense' AND entry_date BETWEEN p_from AND p_to), 0),
    'payout_expense',    COALESCE((SELECT sum(debit_amount) FROM financial_entries WHERE category = 'payout_expense' AND entry_date BETWEEN p_from AND p_to), 0),
    'refund_expense',    COALESCE((SELECT sum(debit_amount) FROM financial_entries WHERE category = 'refund_expense' AND entry_date BETWEEN p_from AND p_to), 0),
    'other_expense',     COALESCE((SELECT sum(debit_amount) FROM financial_entries WHERE category = 'other_expense' AND entry_date BETWEEN p_from AND p_to), 0)
  );
$$;

-- Financial books: Trial Balance
CREATE OR REPLACE FUNCTION admin_trial_balance(p_as_of date DEFAULT current_date)
RETURNS TABLE (
  category      text,
  total_debits  numeric,
  total_credits numeric,
  balance       numeric
) LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    category,
    COALESCE(sum(debit_amount), 0),
    COALESCE(sum(credit_amount), 0),
    COALESCE(sum(credit_amount), 0) - COALESCE(sum(debit_amount), 0)
  FROM financial_entries
  WHERE entry_date <= p_as_of
  GROUP BY category
  ORDER BY category;
$$;

-- Add financial entry (super_admin only)
CREATE OR REPLACE FUNCTION admin_add_financial_entry(
  p_admin_id      uuid,
  p_entry_date    date,
  p_category      text,
  p_description   text,
  p_debit         numeric DEFAULT 0,
  p_credit        numeric DEFAULT 0,
  p_ref_type      text DEFAULT 'manual',
  p_ref_id        bigint DEFAULT NULL
) RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_level text;
  v_id    bigint;
BEGIN
  SELECT admin_level INTO v_level FROM profiles WHERE id = p_admin_id;
  IF v_level != 'super_admin' THEN
    RAISE EXCEPTION 'Only super_admin can create financial entries';
  END IF;

  INSERT INTO financial_entries (entry_date, category, description, debit_amount, credit_amount, reference_type, reference_id, created_by)
  VALUES (p_entry_date, p_category, p_description, p_debit, p_credit, p_ref_type, p_ref_id, p_admin_id)
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  ACCOUNT DELETION / SUSPENSION                              ║
-- ╚══════════════════════════════════════════════════════════════╝

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS account_status text DEFAULT 'active';
  -- active, suspended, pending_deletion, deleted
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS suspended_at timestamptz;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS deletion_requested_at timestamptz;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS deletion_scheduled_at timestamptz;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS original_email text;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS original_phone text;

-- Soft-delete: moves account to suspended state
CREATE OR REPLACE FUNCTION request_account_deletion(p_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE profiles
  SET account_status        = 'suspended',
      suspended_at          = now(),
      deletion_requested_at = now(),
      deletion_scheduled_at = now() + interval '6 months',
      original_email        = email,
      original_phone        = phone,
      updated_at            = now()
  WHERE id = p_user_id;
END;
$$;

-- Restore account within 6-month window
CREATE OR REPLACE FUNCTION restore_account(p_user_id uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_profile profiles%ROWTYPE;
BEGIN
  SELECT * INTO v_profile FROM profiles WHERE id = p_user_id;
  IF NOT FOUND THEN RETURN false; END IF;

  IF v_profile.account_status != 'suspended' THEN RETURN false; END IF;
  IF v_profile.deletion_scheduled_at < now() THEN RETURN false; END IF;

  UPDATE profiles
  SET account_status        = 'active',
      suspended_at          = NULL,
      deletion_requested_at = NULL,
      deletion_scheduled_at = NULL,
      email                 = COALESCE(original_email, email),
      phone                 = COALESCE(original_phone, phone),
      original_email        = NULL,
      original_phone        = NULL,
      updated_at            = now()
  WHERE id = p_user_id;

  RETURN true;
END;
$$;

-- Scheduled job: after 6 months move to pending_deletion, after 5 years hard delete
-- (Run via pg_cron or Supabase scheduled function)
CREATE OR REPLACE FUNCTION process_account_deletions()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- After 6 months: anonymize but keep data
  UPDATE profiles
  SET account_status = 'pending_deletion',
      email          = 'deleted_' || id || '@deleted.local',
      phone          = NULL,
      full_name      = 'Deleted User',
      avatar_url     = NULL,
      updated_at     = now()
  WHERE account_status = 'suspended'
    AND deletion_scheduled_at <= now();

  -- After 5 years from deletion request: hard delete
  DELETE FROM profiles
  WHERE account_status = 'pending_deletion'
    AND deletion_requested_at <= now() - interval '5 years';
END;
$$;


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SECURITY: Login PIN                                        ║
-- ╚══════════════════════════════════════════════════════════════╝

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS login_pin_hash text;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS pin_set_at timestamptz;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS security_method text DEFAULT 'none';
  -- none, pin, biometric, both

-- Set login PIN (hashed with pgcrypto)
CREATE OR REPLACE FUNCTION set_login_pin(p_user_id uuid, p_pin text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF length(p_pin) < 4 OR length(p_pin) > 6 THEN
    RAISE EXCEPTION 'PIN must be 4-6 digits';
  END IF;

  UPDATE profiles
  SET login_pin_hash   = crypt(p_pin, gen_salt('bf')),
      pin_set_at       = now(),
      security_method  = CASE
        WHEN security_method = 'biometric' THEN 'both'
        ELSE 'pin'
      END,
      updated_at       = now()
  WHERE id = p_user_id;
END;
$$;

-- Verify login PIN
CREATE OR REPLACE FUNCTION verify_login_pin(p_user_id uuid, p_pin text)
RETURNS boolean LANGUAGE sql SECURITY DEFINER AS $$
  SELECT login_pin_hash = crypt(p_pin, login_pin_hash)
  FROM profiles WHERE id = p_user_id;
$$;

-- Update security method preference
CREATE OR REPLACE FUNCTION set_security_method(p_user_id uuid, p_method text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF p_method NOT IN ('none','pin','biometric','both') THEN
    RAISE EXCEPTION 'Invalid security method: %', p_method;
  END IF;

  UPDATE profiles
  SET security_method = p_method, updated_at = now()
  WHERE id = p_user_id;
END;
$$;


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  UPDATED admin_stats() with all new counts                  ║
-- ╚══════════════════════════════════════════════════════════════╝

CREATE OR REPLACE FUNCTION admin_stats()
RETURNS jsonb LANGUAGE sql SECURITY DEFINER AS $$
SELECT jsonb_build_object(
  'pending_vendor_apps', (SELECT count(*) FROM vendor_applications WHERE status = 'pending'),
  'pending_products',    (SELECT count(*) FROM products WHERE status = 'pending'),
  'total_stores',        (SELECT count(*) FROM stores WHERE is_active = true),
  'total_products',      (SELECT count(*) FROM products WHERE is_active = true),
  'total_users',         (SELECT count(*) FROM profiles WHERE account_status = 'active'),
  'total_orders_today',  (SELECT count(*) FROM orders WHERE created_at::date = current_date),
  'revenue_today',       (SELECT COALESCE(sum(total_amount),0) FROM orders
                           WHERE created_at::date = current_date
                             AND status NOT IN ('pending_payment','cancelled')),
  'revenue_30d',         (SELECT COALESCE(sum(total_amount),0) FROM orders
                           WHERE created_at >= now() - interval '30 days'
                             AND status NOT IN ('pending_payment','cancelled')),
  'revenue_all_time',    (SELECT COALESCE(sum(total_amount),0) FROM orders
                           WHERE status NOT IN ('pending_payment','cancelled')),
  'open_tickets',        (SELECT count(*) FROM support_tickets WHERE status IN ('open','in_progress')),
  'unassigned_tickets',  (SELECT count(*) FROM support_tickets WHERE assigned_to IS NULL AND status IN ('open','in_progress')),
  'low_stock_items',     (SELECT count(*) FROM products WHERE stock_quantity > 0 AND stock_quantity <= 3 AND status = 'active'),
  'out_of_stock_items',  (SELECT count(*) FROM products WHERE stock_quantity = 0 AND status = 'active'),
  'pending_payouts',     (SELECT count(*) FROM payouts WHERE status = 'pending'),
  'pending_payout_total',(SELECT COALESCE(sum(net_amount),0) FROM payouts WHERE status = 'pending'),
  'active_orders',       (SELECT count(*) FROM orders WHERE status NOT IN ('pending_payment','delivered','cancelled','returned')),
  'pending_refunds',     (SELECT count(*) FROM refunds WHERE status = 'pending'),
  'suspended_accounts',  (SELECT count(*) FROM profiles WHERE account_status = 'suspended')
);
$$;
