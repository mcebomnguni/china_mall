-- ============================================================
-- China Stall — Admin Web Dashboard SQL
-- Run AFTER master_migration.sql
-- ============================================================

-- ── 1. Admin notes column on products ───────────────────────
ALTER TABLE products ADD COLUMN IF NOT EXISTS admin_notes text;

-- ── 2. RLS: Admin can access all stores ─────────────────────
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "stores_public_select"       ON stores;
CREATE POLICY "stores_public_select" ON stores FOR SELECT USING (true);

DROP POLICY IF EXISTS "vendors_manage_own_stores"  ON stores;
CREATE POLICY "vendors_manage_own_stores" ON stores FOR ALL
  USING  (owner = auth.uid())
  WITH CHECK (owner = auth.uid());

DROP POLICY IF EXISTS "admin_all_stores"           ON stores;
CREATE POLICY "admin_all_stores" ON stores FOR ALL
  USING  (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')));

-- ── 3. RLS: Admin can access all orders + order_items ───────
DROP POLICY IF EXISTS "admin_all_orders"           ON orders;
CREATE POLICY "admin_all_orders" ON orders FOR ALL
  USING  (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')));

DROP POLICY IF EXISTS "admin_all_order_items"      ON order_items;
CREATE POLICY "admin_all_order_items" ON order_items FOR ALL
  USING  (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')));

-- ── 4. RLS: Admin can see all profiles ──────────────────────
DROP POLICY IF EXISTS "admin_all_profiles"         ON profiles;
CREATE POLICY "admin_all_profiles" ON profiles FOR ALL
  USING  (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')));

-- ── 5. Approve vendor application (creates/activates store) ─
CREATE OR REPLACE FUNCTION admin_approve_vendor(
  p_application_id bigint,
  p_admin_id       uuid,
  p_notes          text DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_app        vendor_applications%ROWTYPE;
  v_store_id   bigint;
BEGIN
  SELECT * INTO v_app FROM vendor_applications WHERE id = p_application_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Application % not found', p_application_id; END IF;

  -- Mark application approved
  UPDATE vendor_applications
  SET    status      = 'approved',
         reviewed_at = now(),
         reviewed_by = p_admin_id,
         admin_notes = COALESCE(p_notes, admin_notes),
         updated_at  = now()
  WHERE  id = p_application_id;

  -- Ensure profile is marked as vendor
  UPDATE profiles SET role = 'vendor', updated_at = now()
  WHERE  id = v_app.profile_id AND role != 'admin';

  -- Create or activate the store
  SELECT id INTO v_store_id FROM stores WHERE owner = v_app.profile_id LIMIT 1;
  IF v_store_id IS NULL THEN
    INSERT INTO stores (owner, name, is_active, created_at, updated_at)
    VALUES (v_app.profile_id, v_app.store_name, true, now(), now())
    RETURNING id INTO v_store_id;
  ELSE
    UPDATE stores SET is_active = true, name = v_app.store_name, updated_at = now()
    WHERE  id = v_store_id;
  END IF;

  -- Notify vendor
  INSERT INTO notifications (profile_id, title, body, data) VALUES (
    v_app.profile_id,
    '🎉 Store Approved!',
    'Your store "' || v_app.store_name || '" has been approved. You can now list products.',
    jsonb_build_object('type','vendor_approved','store_id',v_store_id)
  );
END;
$$;

-- ── 6. Reject vendor application ────────────────────────────
CREATE OR REPLACE FUNCTION admin_reject_vendor(
  p_application_id bigint,
  p_admin_id       uuid,
  p_notes          text
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_profile_id uuid;
  v_store_name text;
BEGIN
  SELECT profile_id, store_name INTO v_profile_id, v_store_name
  FROM   vendor_applications WHERE id = p_application_id;

  UPDATE vendor_applications
  SET    status      = 'rejected',
         reviewed_at = now(),
         reviewed_by = p_admin_id,
         admin_notes = p_notes,
         updated_at  = now()
  WHERE  id = p_application_id;

  INSERT INTO notifications (profile_id, title, body, data) VALUES (
    v_profile_id,
    'Store Application Declined',
    'Your application for "' || v_store_name || '" was not approved. Reason: ' || p_notes,
    jsonb_build_object('type','vendor_rejected')
  );
END;
$$;

-- ── 7. Request more info on vendor application ───────────────
CREATE OR REPLACE FUNCTION admin_vendor_more_info(
  p_application_id bigint,
  p_admin_id       uuid,
  p_notes          text
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_profile_id uuid;
  v_store_name text;
BEGIN
  SELECT profile_id, store_name INTO v_profile_id, v_store_name
  FROM   vendor_applications WHERE id = p_application_id;

  UPDATE vendor_applications
  SET    status      = 'more_info_required',
         reviewed_at = now(),
         reviewed_by = p_admin_id,
         admin_notes = p_notes,
         updated_at  = now()
  WHERE  id = p_application_id;

  INSERT INTO notifications (profile_id, title, body, data) VALUES (
    v_profile_id,
    'More Information Required',
    'We need additional information for your store "' || v_store_name || '". Notes: ' || p_notes,
    jsonb_build_object('type','vendor_more_info')
  );
END;
$$;

-- ── 8. Approve product listing ──────────────────────────────
CREATE OR REPLACE FUNCTION admin_approve_product(
  p_product_id bigint,
  p_admin_id   uuid
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_owner        uuid;
  v_product_name text;
BEGIN
  SELECT p.name, s.owner INTO v_product_name, v_owner
  FROM   products p JOIN stores s ON s.id = p.store_id
  WHERE  p.id = p_product_id;

  UPDATE products
  SET    status = 'active', is_active = true, admin_notes = NULL, updated_at = now()
  WHERE  id = p_product_id;

  INSERT INTO notifications (profile_id, title, body, data) VALUES (
    v_owner,
    '✅ Product Approved',
    '"' || v_product_name || '" is now live on the marketplace.',
    jsonb_build_object('type','product_approved','product_id',p_product_id)
  );
END;
$$;

-- ── 9. Reject product listing ───────────────────────────────
CREATE OR REPLACE FUNCTION admin_reject_product(
  p_product_id bigint,
  p_admin_id   uuid,
  p_notes      text
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_owner        uuid;
  v_product_name text;
BEGIN
  SELECT p.name, s.owner INTO v_product_name, v_owner
  FROM   products p JOIN stores s ON s.id = p.store_id
  WHERE  p.id = p_product_id;

  UPDATE products
  SET    status = 'rejected', is_active = false, admin_notes = p_notes, updated_at = now()
  WHERE  id = p_product_id;

  INSERT INTO notifications (profile_id, title, body, data) VALUES (
    v_owner,
    'Product Listing Rejected',
    '"' || v_product_name || '" was not approved. Reason: ' || p_notes,
    jsonb_build_object('type','product_rejected','product_id',p_product_id)
  );
END;
$$;

-- ── 10. Request product changes ──────────────────────────────
CREATE OR REPLACE FUNCTION admin_product_needs_changes(
  p_product_id bigint,
  p_admin_id   uuid,
  p_notes      text
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_owner        uuid;
  v_product_name text;
BEGIN
  SELECT p.name, s.owner INTO v_product_name, v_owner
  FROM   products p JOIN stores s ON s.id = p.store_id
  WHERE  p.id = p_product_id;

  UPDATE products
  SET    status = 'needs_changes', is_active = false, admin_notes = p_notes, updated_at = now()
  WHERE  id = p_product_id;

  INSERT INTO notifications (profile_id, title, body, data) VALUES (
    v_owner,
    'Changes Required for Product',
    '"' || v_product_name || '" needs updates before it can go live. Notes: ' || p_notes,
    jsonb_build_object('type','product_needs_changes','product_id',p_product_id)
  );
END;
$$;

-- ── 11. Admin dashboard stats ────────────────────────────────
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
                           WHERE status NOT IN ('pending_payment','cancelled'))
);
$$;

-- ── 12. Top products by sales ────────────────────────────────
CREATE OR REPLACE FUNCTION admin_top_products(
  p_days  integer DEFAULT 30,
  p_limit integer DEFAULT 100
) RETURNS TABLE (
  product_id     bigint,
  product_name   text,
  store_name     text,
  category_label text,
  total_sold     bigint,
  total_revenue  numeric,
  price          numeric,
  vendor_price   numeric
) LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    p.id,
    p.name,
    s.name,
    c.label,
    COALESCE(SUM(oi.quantity),0)::bigint          AS total_sold,
    COALESCE(SUM(oi.quantity * oi.unit_price),0)  AS total_revenue,
    p.price,
    p.vendor_price
  FROM products p
  JOIN stores s ON s.id = p.store_id
  LEFT JOIN categories c ON c.id = p.category_id
  LEFT JOIN order_items oi ON oi.product_id = p.id
  LEFT JOIN orders o ON o.id = oi.order_id
    AND o.created_at >= now() - (p_days || ' days')::interval
    AND o.status NOT IN ('pending_payment','cancelled','returned')
  GROUP BY p.id, p.name, s.name, c.label, p.price, p.vendor_price
  ORDER BY total_sold DESC
  LIMIT p_limit;
$$;

-- ── 13. Revenue timeline ─────────────────────────────────────
CREATE OR REPLACE FUNCTION admin_revenue_timeline(
  p_period text    DEFAULT 'day',
  p_days   integer DEFAULT 30
) RETURNS TABLE (
  bucket      timestamptz,
  order_count bigint,
  revenue     numeric
) LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    date_trunc(p_period, o.created_at) AS bucket,
    count(o.id)::bigint,
    COALESCE(sum(o.total_amount), 0)
  FROM orders o
  WHERE o.created_at >= now() - (p_days || ' days')::interval
    AND o.status NOT IN ('pending_payment','cancelled')
  GROUP BY 1
  ORDER BY 1;
$$;

-- ── 14. Store performance ────────────────────────────────────
CREATE OR REPLACE FUNCTION admin_store_performance(p_days integer DEFAULT 30)
RETURNS TABLE (
  store_id      bigint,
  store_name    text,
  owner_name    text,
  product_count bigint,
  order_count   bigint,
  revenue       numeric,
  is_active     boolean
) LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    s.id,
    s.name,
    pr.full_name,
    count(DISTINCT prod.id)::bigint                AS product_count,
    count(DISTINCT o.id)::bigint                   AS order_count,
    COALESCE(sum(oi.quantity * oi.unit_price), 0)  AS revenue,
    s.is_active
  FROM stores s
  LEFT JOIN profiles pr    ON pr.id   = s.owner
  LEFT JOIN products prod  ON prod.store_id = s.id
  LEFT JOIN order_items oi ON oi.product_id = prod.id
  LEFT JOIN orders o       ON o.id  = oi.order_id
    AND o.created_at >= now() - (p_days || ' days')::interval
    AND o.status NOT IN ('pending_payment','cancelled','returned')
  GROUP BY s.id, s.name, pr.full_name, s.is_active
  ORDER BY revenue DESC NULLS LAST;
$$;

-- Add driver_id to deliveries so couriers can be linked to deliveries
ALTER TABLE deliveries ADD COLUMN IF NOT EXISTS driver_id bigint REFERENCES drivers(id) ON DELETE SET NULL;

-- ── 15. Courier performance ──────────────────────────────────
CREATE OR REPLACE FUNCTION admin_courier_performance(p_days integer DEFAULT 30)
RETURNS TABLE (
  courier_name       text,
  courier_email      text,
  total_deliveries   bigint,
  completed          bigint,
  cancelled_count    bigint,
  on_time_rate_pct   numeric
) LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    p.full_name,
    p.email,
    count(d.id)::bigint                                            AS total_deliveries,
    count(CASE WHEN d.status = 'delivered' THEN 1 END)::bigint    AS completed,
    count(CASE WHEN d.status = 'cancelled' THEN 1 END)::bigint    AS cancelled_count,
    CASE WHEN count(d.id) = 0 THEN 0
         ELSE round(100.0 * count(CASE WHEN d.status = 'delivered' THEN 1 END) / count(d.id), 1)
    END                                                             AS on_time_rate_pct
  FROM profiles p
  JOIN drivers dr ON dr.profile_id = p.id
  LEFT JOIN deliveries d ON d.driver_id = dr.id
    AND d.created_at >= now() - (p_days || ' days')::interval
  WHERE p.role = 'courier'
  GROUP BY p.full_name, p.email
  ORDER BY completed DESC;
$$;

-- ── 16. Category conversion rates ───────────────────────────
CREATE OR REPLACE FUNCTION admin_category_stats(p_days integer DEFAULT 30)
RETURNS TABLE (
  category_label text,
  product_count  bigint,
  total_sold     bigint,
  revenue        numeric
) LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    COALESCE(c.label, 'Uncategorised'),
    count(DISTINCT p.id)::bigint,
    COALESCE(sum(oi.quantity), 0)::bigint,
    COALESCE(sum(oi.quantity * oi.unit_price), 0)
  FROM products p
  LEFT JOIN categories c ON c.id = p.category_id
  LEFT JOIN order_items oi ON oi.product_id = p.id
  LEFT JOIN orders o ON o.id = oi.order_id
    AND o.created_at >= now() - (p_days || ' days')::interval
    AND o.status NOT IN ('pending_payment','cancelled','returned')
  WHERE p.is_active = true
  GROUP BY c.label
  ORDER BY 4 DESC;
$$;
