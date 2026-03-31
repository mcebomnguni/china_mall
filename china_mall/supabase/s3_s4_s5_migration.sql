-- ============================================================
-- S3: Ads & Targeting
-- S4: Store Analytics subscriptions
-- S5: Order fulfillment columns + vendor RLS
-- Run this in the Supabase SQL Editor
-- ============================================================

-- ── S5: Extend orders table ──────────────────────────────────
ALTER TABLE orders ADD COLUMN IF NOT EXISTS handoff_code    text;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS confirmed_at    timestamptz;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS packed_at       timestamptz;

-- ── S3: Ad campaigns ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ad_campaigns (
  id                bigserial PRIMARY KEY,
  store_id          bigint NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  target_customers  integer NOT NULL DEFAULT 100,
  budget_rands      numeric(10,2) NOT NULL,
  customers_reached integer NOT NULL DEFAULT 0,
  status            text NOT NULL DEFAULT 'active'
                      CHECK (status IN ('active','paused','completed','cancelled')),
  starts_at         timestamptz NOT NULL DEFAULT now(),
  expires_at        timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE ad_campaigns ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "vendors_see_own_campaigns"    ON ad_campaigns;
CREATE POLICY "vendors_see_own_campaigns" ON ad_campaigns
  FOR SELECT USING (
    store_id IN (SELECT id FROM stores WHERE owner = auth.uid())
  );

DROP POLICY IF EXISTS "vendors_insert_campaigns"     ON ad_campaigns;
CREATE POLICY "vendors_insert_campaigns" ON ad_campaigns
  FOR INSERT WITH CHECK (
    store_id IN (SELECT id FROM stores WHERE owner = auth.uid())
  );

DROP POLICY IF EXISTS "vendors_update_campaigns"     ON ad_campaigns;
CREATE POLICY "vendors_update_campaigns" ON ad_campaigns
  FOR UPDATE USING (
    store_id IN (SELECT id FROM stores WHERE owner = auth.uid())
  );

-- ── S4: Analytics subscriptions ─────────────────────────────
CREATE TABLE IF NOT EXISTS analytics_subscriptions (
  id           bigserial PRIMARY KEY,
  store_id     bigint NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  status       text NOT NULL DEFAULT 'active'
                 CHECK (status IN ('active','expired','cancelled')),
  amount_paid  numeric(10,2) NOT NULL DEFAULT 250,
  starts_at    timestamptz NOT NULL DEFAULT now(),
  expires_at   timestamptz NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE analytics_subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "vendors_see_own_analytics_sub"    ON analytics_subscriptions;
CREATE POLICY "vendors_see_own_analytics_sub" ON analytics_subscriptions
  FOR SELECT USING (
    store_id IN (SELECT id FROM stores WHERE owner = auth.uid())
  );

DROP POLICY IF EXISTS "vendors_insert_analytics_sub"     ON analytics_subscriptions;
CREATE POLICY "vendors_insert_analytics_sub" ON analytics_subscriptions
  FOR INSERT WITH CHECK (
    store_id IN (SELECT id FROM stores WHERE owner = auth.uid())
  );

-- ── S5: Vendor RLS on orders ─────────────────────────────────
-- Vendors can SELECT orders that contain their products (or their own buyer orders)
DROP POLICY IF EXISTS "vendors_see_their_orders"     ON orders;
CREATE POLICY "vendors_see_their_orders" ON orders
  FOR SELECT USING (
    profile_id = auth.uid()
    OR id IN (
      SELECT DISTINCT oi.order_id
      FROM   order_items oi
      JOIN   products    p  ON p.id  = oi.product_id
      JOIN   stores      s  ON s.id  = p.store_id
      WHERE  s.owner = auth.uid()
    )
  );

-- Vendors can UPDATE status/handoff_code on their orders
DROP POLICY IF EXISTS "vendors_update_their_orders"  ON orders;
CREATE POLICY "vendors_update_their_orders" ON orders
  FOR UPDATE USING (
    id IN (
      SELECT DISTINCT oi.order_id
      FROM   order_items oi
      JOIN   products    p  ON p.id  = oi.product_id
      JOIN   stores      s  ON s.id  = p.store_id
      WHERE  s.owner = auth.uid()
    )
  );

-- Vendors can read order_items for their products (or buyer's own orders)
DROP POLICY IF EXISTS "vendors_see_their_order_items" ON order_items;
CREATE POLICY "vendors_see_their_order_items" ON order_items
  FOR SELECT USING (
    product_id IN (
      SELECT p.id FROM products p
      JOIN   stores s ON s.id = p.store_id
      WHERE  s.owner = auth.uid()
    )
    OR order_id IN (
      SELECT id FROM orders WHERE profile_id = auth.uid()
    )
  );
