-- ============================================================
-- China Stall — A3 Payments, A4 Help Desk, A5 Inventory
-- Run AFTER admin_web_migration.sql
-- ============================================================

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  A3: PAYMENT MANAGEMENT (Ozow + Payouts)                   ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ── Payments (customer transactions via Ozow) ───────────────
CREATE TABLE IF NOT EXISTS payments (
  id              bigserial PRIMARY KEY,
  order_id        bigint REFERENCES orders(id) ON DELETE SET NULL,
  profile_id      uuid REFERENCES profiles(id) ON DELETE SET NULL,
  ozow_reference  text,
  ozow_transaction_id text,
  amount          numeric(12,2) NOT NULL,
  currency        text DEFAULT 'ZAR',
  status          text DEFAULT 'pending',  -- pending, complete, failed, refunded
  payment_method  text,                     -- ozow_eft, ozow_card, etc
  metadata        jsonb DEFAULT '{}',
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payments_order    ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_profile  ON payments(profile_id);
CREATE INDEX IF NOT EXISTS idx_payments_status   ON payments(status);

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_own_payments" ON payments;
CREATE POLICY "users_own_payments" ON payments FOR SELECT
  USING (profile_id = auth.uid());

DROP POLICY IF EXISTS "admin_all_payments" ON payments;
CREATE POLICY "admin_all_payments" ON payments FOR ALL
  USING  (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')));

-- ── Payout schedules (per store or courier) ─────────────────
CREATE TABLE IF NOT EXISTS payout_schedules (
  id              bigserial PRIMARY KEY,
  entity_type     text NOT NULL CHECK (entity_type IN ('store','courier')),
  entity_id       bigint NOT NULL,            -- stores.id or drivers.id
  frequency       text DEFAULT 'weekly' CHECK (frequency IN ('weekly','biweekly')),
  day_of_week     integer DEFAULT 5,          -- 0=Sun … 5=Fri
  commission_pct  numeric(5,2) DEFAULT 10.00, -- platform commission %
  is_active       boolean DEFAULT true,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now(),
  UNIQUE (entity_type, entity_id)
);

ALTER TABLE payout_schedules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_all_payout_schedules" ON payout_schedules;
CREATE POLICY "admin_all_payout_schedules" ON payout_schedules FOR ALL
  USING  (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')));

-- Vendors can read their own schedule
DROP POLICY IF EXISTS "vendor_own_schedule" ON payout_schedules;
CREATE POLICY "vendor_own_schedule" ON payout_schedules FOR SELECT
  USING (
    entity_type = 'store'
    AND entity_id IN (SELECT id FROM stores WHERE owner = auth.uid())
  );

-- ── Payouts (actual disbursements) ──────────────────────────
CREATE TABLE IF NOT EXISTS payouts (
  id                bigserial PRIMARY KEY,
  entity_type       text NOT NULL CHECK (entity_type IN ('store','courier')),
  entity_id         bigint NOT NULL,
  schedule_id       bigint REFERENCES payout_schedules(id) ON DELETE SET NULL,
  period_start      date NOT NULL,
  period_end        date NOT NULL,
  gross_amount      numeric(12,2) NOT NULL DEFAULT 0,
  commission_amount numeric(12,2) NOT NULL DEFAULT 0,
  net_amount        numeric(12,2) NOT NULL DEFAULT 0,
  status            text DEFAULT 'pending', -- pending, processing, completed, failed
  reference         text,                   -- bank transfer reference
  processed_at      timestamptz,
  processed_by      uuid REFERENCES profiles(id),
  notes             text,
  created_at        timestamptz DEFAULT now(),
  updated_at        timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payouts_entity   ON payouts(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_payouts_status   ON payouts(status);

ALTER TABLE payouts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_all_payouts" ON payouts;
CREATE POLICY "admin_all_payouts" ON payouts FOR ALL
  USING  (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')));

-- Vendors can see their own payouts
DROP POLICY IF EXISTS "vendor_own_payouts" ON payouts;
CREATE POLICY "vendor_own_payouts" ON payouts FOR SELECT
  USING (
    entity_type = 'store'
    AND entity_id IN (SELECT id FROM stores WHERE owner = auth.uid())
  );

-- ── A3 Admin functions ──────────────────────────────────────

-- Payment stats
CREATE OR REPLACE FUNCTION admin_payment_stats(p_days integer DEFAULT 30)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER AS $$
  SELECT jsonb_build_object(
    'total_transactions',  (SELECT count(*) FROM payments WHERE created_at >= now() - (p_days || ' days')::interval),
    'total_collected',     (SELECT COALESCE(sum(amount),0) FROM payments WHERE status = 'complete' AND created_at >= now() - (p_days || ' days')::interval),
    'pending_amount',      (SELECT COALESCE(sum(amount),0) FROM payments WHERE status = 'pending'),
    'failed_count',        (SELECT count(*) FROM payments WHERE status = 'failed' AND created_at >= now() - (p_days || ' days')::interval),
    'refunded_amount',     (SELECT COALESCE(sum(amount),0) FROM payments WHERE status = 'refunded' AND created_at >= now() - (p_days || ' days')::interval),
    'pending_payouts',     (SELECT count(*) FROM payouts WHERE status = 'pending'),
    'pending_payout_total',(SELECT COALESCE(sum(net_amount),0) FROM payouts WHERE status = 'pending'),
    'paid_out_period',     (SELECT COALESCE(sum(net_amount),0) FROM payouts WHERE status = 'completed' AND processed_at >= now() - (p_days || ' days')::interval),
    'commission_earned',   (SELECT COALESCE(sum(commission_amount),0) FROM payouts WHERE status = 'completed' AND processed_at >= now() - (p_days || ' days')::interval)
  );
$$;

-- Process a payout (mark as completed)
CREATE OR REPLACE FUNCTION admin_process_payout(
  p_payout_id bigint,
  p_admin_id  uuid,
  p_reference text DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_payout payouts%ROWTYPE;
  v_owner  uuid;
  v_name   text;
BEGIN
  SELECT * INTO v_payout FROM payouts WHERE id = p_payout_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Payout % not found', p_payout_id; END IF;

  UPDATE payouts
  SET status       = 'completed',
      reference    = COALESCE(p_reference, reference),
      processed_at = now(),
      processed_by = p_admin_id,
      updated_at   = now()
  WHERE id = p_payout_id;

  -- Notify the recipient
  IF v_payout.entity_type = 'store' THEN
    SELECT owner, name INTO v_owner, v_name FROM stores WHERE id = v_payout.entity_id;
    INSERT INTO notifications (profile_id, title, body, data) VALUES (
      v_owner,
      'Payout Processed',
      'R ' || v_payout.net_amount || ' has been paid to "' || v_name || '".',
      jsonb_build_object('type','payout_completed','payout_id', p_payout_id)
    );
  ELSIF v_payout.entity_type = 'courier' THEN
    SELECT profile_id INTO v_owner FROM drivers WHERE id = v_payout.entity_id;
    INSERT INTO notifications (profile_id, title, body, data) VALUES (
      v_owner,
      'Payout Processed',
      'R ' || v_payout.net_amount || ' has been paid to your account.',
      jsonb_build_object('type','payout_completed','payout_id', p_payout_id)
    );
  END IF;
END;
$$;

-- Update payout schedule (commission / frequency)
CREATE OR REPLACE FUNCTION admin_update_payout_schedule(
  p_schedule_id   bigint,
  p_frequency     text DEFAULT NULL,
  p_commission_pct numeric DEFAULT NULL,
  p_is_active     boolean DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE payout_schedules
  SET frequency      = COALESCE(p_frequency, frequency),
      commission_pct = COALESCE(p_commission_pct, commission_pct),
      is_active      = COALESCE(p_is_active, is_active),
      updated_at     = now()
  WHERE id = p_schedule_id;
END;
$$;


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  A4: HELP DESK (Ticketing System)                          ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Ticket number sequence
CREATE SEQUENCE IF NOT EXISTS ticket_number_seq START 1;

-- ── Support tickets ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS support_tickets (
  id              bigserial PRIMARY KEY,
  ticket_number   text UNIQUE,
  profile_id      uuid REFERENCES profiles(id) ON DELETE SET NULL,
  category        text NOT NULL CHECK (category IN (
    'order_issue','delivery_problem','product_complaint','account_issue','payment_dispute'
  )),
  subject         text NOT NULL,
  status          text DEFAULT 'open' CHECK (status IN ('open','in_progress','resolved','closed')),
  priority        text DEFAULT 'medium' CHECK (priority IN ('low','medium','high','urgent')),
  order_id        bigint REFERENCES orders(id) ON DELETE SET NULL,
  store_id        bigint REFERENCES stores(id) ON DELETE SET NULL,
  assigned_to     uuid REFERENCES profiles(id) ON DELETE SET NULL,
  resolved_at     timestamptz,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tickets_profile  ON support_tickets(profile_id);
CREATE INDEX IF NOT EXISTS idx_tickets_status   ON support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_tickets_category ON support_tickets(category);

-- Auto-generate ticket number
CREATE OR REPLACE FUNCTION generate_ticket_number()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.ticket_number := 'TK-' || LPAD(nextval('ticket_number_seq')::text, 6, '0');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ticket_number ON support_tickets;
CREATE TRIGGER trg_ticket_number
  BEFORE INSERT ON support_tickets
  FOR EACH ROW EXECUTE FUNCTION generate_ticket_number();

ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

-- Users can see their own tickets
DROP POLICY IF EXISTS "users_own_tickets" ON support_tickets;
CREATE POLICY "users_own_tickets" ON support_tickets FOR SELECT
  USING (profile_id = auth.uid());

-- Users can create tickets
DROP POLICY IF EXISTS "users_create_tickets" ON support_tickets;
CREATE POLICY "users_create_tickets" ON support_tickets FOR INSERT
  WITH CHECK (profile_id = auth.uid());

-- Admin/staff can do everything
DROP POLICY IF EXISTS "admin_all_tickets" ON support_tickets;
CREATE POLICY "admin_all_tickets" ON support_tickets FOR ALL
  USING  (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')));

-- ── Ticket messages ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ticket_messages (
  id          bigserial PRIMARY KEY,
  ticket_id   bigint REFERENCES support_tickets(id) ON DELETE CASCADE NOT NULL,
  sender_id   uuid REFERENCES profiles(id) ON DELETE SET NULL,
  message     text NOT NULL,
  is_internal boolean DEFAULT false,  -- admin-only internal notes
  attachments jsonb DEFAULT '[]',     -- array of file URLs
  created_at  timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tmsg_ticket ON ticket_messages(ticket_id);

ALTER TABLE ticket_messages ENABLE ROW LEVEL SECURITY;

-- Users see messages on their own tickets (excluding internal notes)
DROP POLICY IF EXISTS "users_own_ticket_messages" ON ticket_messages;
CREATE POLICY "users_own_ticket_messages" ON ticket_messages FOR SELECT
  USING (
    is_internal = false
    AND ticket_id IN (SELECT id FROM support_tickets WHERE profile_id = auth.uid())
  );

-- Users can insert messages on their own tickets
DROP POLICY IF EXISTS "users_send_ticket_messages" ON ticket_messages;
CREATE POLICY "users_send_ticket_messages" ON ticket_messages FOR INSERT
  WITH CHECK (
    is_internal = false
    AND sender_id = auth.uid()
    AND ticket_id IN (SELECT id FROM support_tickets WHERE profile_id = auth.uid())
  );

-- Admin/staff full access
DROP POLICY IF EXISTS "admin_all_ticket_messages" ON ticket_messages;
CREATE POLICY "admin_all_ticket_messages" ON ticket_messages FOR ALL
  USING  (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')));

-- ── A4 Admin functions ──────────────────────────────────────

-- Ticket stats
CREATE OR REPLACE FUNCTION admin_ticket_stats()
RETURNS jsonb LANGUAGE sql SECURITY DEFINER AS $$
  SELECT jsonb_build_object(
    'open',        (SELECT count(*) FROM support_tickets WHERE status = 'open'),
    'in_progress', (SELECT count(*) FROM support_tickets WHERE status = 'in_progress'),
    'resolved',    (SELECT count(*) FROM support_tickets WHERE status = 'resolved'),
    'closed',      (SELECT count(*) FROM support_tickets WHERE status = 'closed'),
    'total',       (SELECT count(*) FROM support_tickets),
    'unassigned',  (SELECT count(*) FROM support_tickets WHERE assigned_to IS NULL AND status IN ('open','in_progress')),
    'avg_resolve_hours', (
      SELECT COALESCE(
        round(EXTRACT(EPOCH FROM avg(resolved_at - created_at)) / 3600, 1),
        0
      )
      FROM support_tickets WHERE resolved_at IS NOT NULL
    )
  );
$$;

-- Assign ticket to admin
CREATE OR REPLACE FUNCTION admin_assign_ticket(
  p_ticket_id bigint,
  p_admin_id  uuid
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE support_tickets
  SET assigned_to = p_admin_id,
      status      = CASE WHEN status = 'open' THEN 'in_progress' ELSE status END,
      updated_at  = now()
  WHERE id = p_ticket_id;
END;
$$;

-- Update ticket status
CREATE OR REPLACE FUNCTION admin_update_ticket_status(
  p_ticket_id bigint,
  p_status    text,
  p_admin_id  uuid
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_profile_id uuid;
  v_ticket_no  text;
BEGIN
  SELECT profile_id, ticket_number INTO v_profile_id, v_ticket_no
  FROM support_tickets WHERE id = p_ticket_id;

  UPDATE support_tickets
  SET status      = p_status,
      resolved_at = CASE WHEN p_status IN ('resolved','closed') THEN now() ELSE resolved_at END,
      updated_at  = now()
  WHERE id = p_ticket_id;

  -- Notify the ticket creator
  IF p_status = 'resolved' THEN
    INSERT INTO notifications (profile_id, title, body, data) VALUES (
      v_profile_id,
      'Ticket Resolved',
      'Your support ticket ' || v_ticket_no || ' has been resolved.',
      jsonb_build_object('type','ticket_resolved','ticket_id', p_ticket_id)
    );
  END IF;
END;
$$;

-- Admin reply on ticket (also creates a message)
CREATE OR REPLACE FUNCTION admin_reply_ticket(
  p_ticket_id  bigint,
  p_admin_id   uuid,
  p_message    text,
  p_is_internal boolean DEFAULT false
) RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_msg_id     bigint;
  v_profile_id uuid;
  v_ticket_no  text;
BEGIN
  INSERT INTO ticket_messages (ticket_id, sender_id, message, is_internal)
  VALUES (p_ticket_id, p_admin_id, p_message, p_is_internal)
  RETURNING id INTO v_msg_id;

  -- Update ticket timestamp
  UPDATE support_tickets SET updated_at = now() WHERE id = p_ticket_id;

  -- Notify user (only for non-internal messages)
  IF NOT p_is_internal THEN
    SELECT profile_id, ticket_number INTO v_profile_id, v_ticket_no
    FROM support_tickets WHERE id = p_ticket_id;

    INSERT INTO notifications (profile_id, title, body, data) VALUES (
      v_profile_id,
      'New reply on ' || v_ticket_no,
      left(p_message, 100),
      jsonb_build_object('type','ticket_reply','ticket_id', p_ticket_id)
    );
  END IF;

  RETURN v_msg_id;
END;
$$;


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  A5: INVENTORY & STOCK OVERSIGHT                           ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Low stock items (threshold default 3)
CREATE OR REPLACE FUNCTION admin_low_stock_items(p_threshold integer DEFAULT 3)
RETURNS TABLE (
  product_id     bigint,
  product_name   text,
  store_id       bigint,
  store_name     text,
  stock_quantity integer,
  is_active      boolean,
  price          numeric,
  category_label text
) LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    p.id,
    p.name,
    s.id,
    s.name,
    p.stock_quantity,
    p.is_active,
    p.price,
    c.label
  FROM products p
  JOIN stores s ON s.id = p.store_id
  LEFT JOIN categories c ON c.id = p.category_id
  WHERE p.stock_quantity <= p_threshold
    AND p.status = 'active'
  ORDER BY p.stock_quantity ASC, s.name;
$$;

-- Inventory overview grouped by store
CREATE OR REPLACE FUNCTION admin_inventory_overview()
RETURNS TABLE (
  store_id          bigint,
  store_name        text,
  owner_name        text,
  total_products    bigint,
  total_stock       bigint,
  low_stock_count   bigint,
  out_of_stock      bigint,
  is_active         boolean
) LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    s.id,
    s.name,
    pr.full_name,
    count(p.id)::bigint                                                       AS total_products,
    COALESCE(sum(p.stock_quantity), 0)::bigint                                AS total_stock,
    count(CASE WHEN p.stock_quantity > 0 AND p.stock_quantity <= 3 THEN 1 END)::bigint AS low_stock_count,
    count(CASE WHEN p.stock_quantity = 0 THEN 1 END)::bigint                  AS out_of_stock,
    s.is_active
  FROM stores s
  LEFT JOIN profiles pr ON pr.id = s.owner
  LEFT JOIN products p  ON p.store_id = s.id AND p.status = 'active'
  GROUP BY s.id, s.name, pr.full_name, s.is_active
  ORDER BY low_stock_count DESC, out_of_stock DESC;
$$;

-- Send restock notification to store owner
CREATE OR REPLACE FUNCTION admin_notify_restock(
  p_product_id bigint,
  p_admin_id   uuid,
  p_message    text DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_owner   uuid;
  v_pname   text;
  v_sname   text;
  v_stock   integer;
BEGIN
  SELECT s.owner, p.name, s.name, p.stock_quantity
  INTO   v_owner, v_pname, v_sname, v_stock
  FROM   products p JOIN stores s ON s.id = p.store_id
  WHERE  p.id = p_product_id;

  INSERT INTO notifications (profile_id, title, body, data) VALUES (
    v_owner,
    'Restock Alert: ' || v_pname,
    COALESCE(p_message,
      '"' || v_pname || '" in "' || v_sname || '" has only ' || v_stock || ' units left. Please restock soon.'
    ),
    jsonb_build_object('type','restock_alert','product_id', p_product_id, 'stock', v_stock)
  );
END;
$$;

-- Inventory stats for dashboard
CREATE OR REPLACE FUNCTION admin_inventory_stats()
RETURNS jsonb LANGUAGE sql SECURITY DEFINER AS $$
  SELECT jsonb_build_object(
    'total_products',   (SELECT count(*) FROM products WHERE status = 'active'),
    'total_stock_units',(SELECT COALESCE(sum(stock_quantity),0) FROM products WHERE status = 'active'),
    'low_stock_items',  (SELECT count(*) FROM products WHERE stock_quantity > 0 AND stock_quantity <= 3 AND status = 'active'),
    'out_of_stock',     (SELECT count(*) FROM products WHERE stock_quantity = 0 AND status = 'active'),
    'stores_with_low_stock', (
      SELECT count(DISTINCT store_id) FROM products
      WHERE stock_quantity <= 3 AND status = 'active'
    )
  );
$$;


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Update admin_stats() to include new feature counts         ║
-- ╚══════════════════════════════════════════════════════════════╝

CREATE OR REPLACE FUNCTION admin_stats()
RETURNS jsonb LANGUAGE sql SECURITY DEFINER AS $$
SELECT jsonb_build_object(
  'pending_vendor_apps', (SELECT count(*) FROM vendor_applications WHERE status = 'pending'),
  'pending_products',    (SELECT count(*) FROM products WHERE status = 'pending'),
  'total_stores',        (SELECT count(*) FROM stores WHERE is_active = true),
  'total_products',      (SELECT count(*) FROM products WHERE is_active = true),
  'total_users',         (SELECT count(*) FROM profiles),
  'total_orders_today',  (SELECT count(*) FROM orders WHERE created_at::date = current_date),
  'revenue_today',       (SELECT COALESCE(sum(total_amount),0) FROM orders
                           WHERE created_at::date = current_date
                             AND status NOT IN ('pending_payment','cancelled')),
  'revenue_30d',         (SELECT COALESCE(sum(total_amount),0) FROM orders
                           WHERE created_at >= now() - interval '30 days'
                             AND status NOT IN ('pending_payment','cancelled')),
  'revenue_all_time',    (SELECT COALESCE(sum(total_amount),0) FROM orders
                           WHERE status NOT IN ('pending_payment','cancelled')),
  -- New: tickets
  'open_tickets',        (SELECT count(*) FROM support_tickets WHERE status IN ('open','in_progress')),
  'unassigned_tickets',  (SELECT count(*) FROM support_tickets WHERE assigned_to IS NULL AND status IN ('open','in_progress')),
  -- New: inventory
  'low_stock_items',     (SELECT count(*) FROM products WHERE stock_quantity > 0 AND stock_quantity <= 3 AND status = 'active'),
  'out_of_stock_items',  (SELECT count(*) FROM products WHERE stock_quantity = 0 AND status = 'active'),
  -- New: payouts
  'pending_payouts',     (SELECT count(*) FROM payouts WHERE status = 'pending'),
  'pending_payout_total',(SELECT COALESCE(sum(net_amount),0) FROM payouts WHERE status = 'pending')
);
$$;
