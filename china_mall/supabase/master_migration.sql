-- ============================================================
-- China Stall Market Place — MASTER MIGRATION
-- Combines ALL migrations in order. Safe to re-run (idempotent).
-- Run this once in the Supabase SQL Editor.
-- Project: ipsdpswdubdczxfbvtty
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- PART 1 — BASE SCHEMA (tables, triggers, RLS)
-- ════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Profiles ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id          uuid PRIMARY KEY,
  email       text,
  phone       text,
  full_name   text,
  avatar_url  text,
  role        text DEFAULT 'buyer',
  is_online   boolean DEFAULT false,
  username    text,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

-- ── Categories ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS categories (
  id         bigserial PRIMARY KEY,
  slug       text UNIQUE NOT NULL,
  label      text NOT NULL,
  icon       text,
  created_at timestamptz DEFAULT now()
);

-- ── Stores ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS stores (
  id          bigserial PRIMARY KEY,
  owner       uuid REFERENCES profiles(id) ON DELETE SET NULL,
  name        text NOT NULL,
  description text,
  cover_url   text,
  slug        text UNIQUE,
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

-- ── Products ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id          bigserial PRIMARY KEY,
  store_id    bigint REFERENCES stores(id) ON DELETE CASCADE,
  title       text NOT NULL,
  description text,
  price       numeric(12,2) NOT NULL DEFAULT 0,
  currency    text DEFAULT 'ZAR',
  stock       integer DEFAULT 0,
  category_id bigint REFERENCES categories(id),
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS product_images (
  id         bigserial PRIMARY KEY,
  product_id bigint REFERENCES products(id) ON DELETE CASCADE,
  url        text NOT NULL,
  ordinal    integer DEFAULT 0
);

-- ── Cart ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS carts (
  id         bigserial PRIMARY KEY,
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cart_items (
  id            bigserial PRIMARY KEY,
  cart_id       bigint REFERENCES carts(id) ON DELETE CASCADE,
  product_id    bigint REFERENCES products(id),
  quantity      integer NOT NULL DEFAULT 1,
  price_at_added numeric(12,2),
  created_at    timestamptz DEFAULT now()
);

-- ── Orders ───────────────────────────────────────────────────
DO $$ BEGIN
  CREATE TYPE order_status AS ENUM (
    'pending_payment','payment_confirmed','processing','awaiting_pickup',
    'picked_up','in_transit','out_for_delivery','delivered','cancelled',
    'return_requested','returned','disputed'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS orders (
  id               bigserial PRIMARY KEY,
  profile_id       uuid REFERENCES profiles(id) ON DELETE SET NULL,
  total_amount     numeric(12,2) DEFAULT 0,
  currency         text DEFAULT 'ZAR',
  status           order_status DEFAULT 'pending_payment',
  shipping_address jsonb,
  payment_meta     jsonb,
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS order_items (
  id         bigserial PRIMARY KEY,
  order_id   bigint REFERENCES orders(id) ON DELETE CASCADE,
  product_id bigint REFERENCES products(id),
  quantity   integer DEFAULT 1,
  unit_price numeric(12,2),
  created_at timestamptz DEFAULT now()
);

-- ── Vouchers ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vouchers (
  id               bigserial PRIMARY KEY,
  code             text UNIQUE NOT NULL,
  discount_percent integer,
  discount_amount  numeric(12,2),
  valid_from       timestamptz,
  valid_to         timestamptz,
  usage_limit      integer DEFAULT 1,
  times_used       integer DEFAULT 0,
  active           boolean DEFAULT true
);

-- ── Devices ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS devices (
  id         bigserial PRIMARY KEY,
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  device_id  text,
  last_seen  timestamptz DEFAULT now()
);

-- ── Reviews ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reviews (
  id         bigserial PRIMARY KEY,
  product_id bigint REFERENCES products(id) ON DELETE CASCADE,
  profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  rating     smallint CHECK (rating >= 1 AND rating <= 5),
  body       text,
  created_at timestamptz DEFAULT now()
);

-- ── Disputes ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS disputes (
  id         bigserial PRIMARY KEY,
  order_id   bigint REFERENCES orders(id) ON DELETE CASCADE,
  raised_by  uuid REFERENCES profiles(id),
  reason     text,
  status     text DEFAULT 'open',
  created_at timestamptz DEFAULT now()
);

-- ── Audit logs ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_logs (
  id            bigserial PRIMARY KEY,
  actor         uuid,
  action        text NOT NULL,
  resource_type text,
  resource_id   text,
  details       jsonb,
  created_at    timestamptz DEFAULT now()
);

-- ── Addresses ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS addresses (
  id           bigserial PRIMARY KEY,
  profile_id   uuid REFERENCES profiles(id) ON DELETE CASCADE,
  label        text,
  full_address text,
  lat          double precision,
  lng          double precision,
  is_default   boolean DEFAULT false,
  created_at   timestamptz DEFAULT now(),
  updated_at   timestamptz DEFAULT now()
);

-- ── Deliveries ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS deliveries (
  id               bigserial PRIMARY KEY,
  order_id         bigint REFERENCES orders(id) ON DELETE SET NULL,
  delivery_type    text,
  pickup_address   text,
  pickup_lat       double precision,
  pickup_lng       double precision,
  delivery_address text,
  delivery_lat     double precision,
  delivery_lng     double precision,
  weight_kg        numeric(8,2) DEFAULT 1,
  status           text DEFAULT 'created',
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS delivery_tracking (
  id          bigserial PRIMARY KEY,
  delivery_id bigint REFERENCES deliveries(id) ON DELETE CASCADE,
  status      text,
  notes       text,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS driver_locations (
  id          bigserial PRIMARY KEY,
  delivery_id bigint REFERENCES deliveries(id) ON DELETE CASCADE,
  lat         double precision,
  lng         double precision,
  recorded_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS drivers (
  id           bigserial PRIMARY KEY,
  profile_id   uuid REFERENCES profiles(id) ON DELETE SET NULL,
  is_online    boolean DEFAULT false,
  vehicle_info jsonb,
  updated_at   timestamptz DEFAULT now()
);

-- ── Courier ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS courier_documents (
  id         bigserial PRIMARY KEY,
  profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  doc_type   text,
  file_url   text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS courier_bank_details (
  id             bigserial PRIMARY KEY,
  profile_id     uuid REFERENCES profiles(id) ON DELETE CASCADE,
  account_name   text,
  account_number text,
  bank_name      text,
  updated_at     timestamptz DEFAULT now()
);

-- ── Notifications ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notification_devices (
  id          bigserial PRIMARY KEY,
  profile_id  uuid REFERENCES profiles(id) ON DELETE SET NULL,
  token       text UNIQUE,
  platform    text,
  device_name text,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notifications (
  id         bigserial PRIMARY KEY,
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  title      text,
  body       text,
  data       jsonb,
  is_read    boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- ── OTP / Reset ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS phone_otps (
  id           bigserial PRIMARY KEY,
  phone_number text NOT NULL,
  code         text NOT NULL,
  purpose      text DEFAULT 'password_reset',
  created_at   timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS phone_resets (
  id           bigserial PRIMARY KEY,
  phone_number text NOT NULL,
  reset_token  text NOT NULL,
  created_at   timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS email_otps (
  id         bigserial PRIMARY KEY,
  email      text NOT NULL,
  code       text NOT NULL,
  purpose    text DEFAULT 'password_reset',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS email_resets (
  id          bigserial PRIMARY KEY,
  email       text NOT NULL,
  reset_token text NOT NULL,
  created_at  timestamptz DEFAULT now()
);

-- ── Indexes ──────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_products_store    ON products(store_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_orders_profile    ON orders(profile_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email    ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role     ON profiles(role);

-- ── Functions ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION admin_overview(days integer DEFAULT 30)
RETURNS jsonb LANGUAGE sql AS $$
  SELECT jsonb_build_object(
    'total_orders',  (SELECT count(*) FROM orders WHERE created_at >= now() - (days || ' days')::interval),
    'total_revenue', (SELECT COALESCE(sum(total_amount),0) FROM orders WHERE created_at >= now() - (days || ' days')::interval),
    'orders_by_day', (SELECT jsonb_agg(row_to_json(t)) FROM (
      SELECT date_trunc('day', created_at) AS day, count(*) AS orders, COALESCE(sum(total_amount),0) AS revenue
      FROM orders WHERE created_at >= now() - (days || ' days')::interval
      GROUP BY 1 ORDER BY 1
    ) t)
  );
$$;

CREATE OR REPLACE FUNCTION calculate_delivery_fee(cart_json jsonb, method text)
RETURNS numeric LANGUAGE plpgsql AS $$
DECLARE
  item_count integer := 0;
  base_fee   numeric := 0;
  fee        numeric := 0;
BEGIN
  SELECT COALESCE(SUM((item->>'quantity')::int), 0) INTO item_count
  FROM jsonb_array_elements(cart_json->'items') AS item;
  IF method = 'express' THEN base_fee := 50; ELSE base_fee := 20; END IF;
  fee := base_fee + (item_count * 5);
  RETURN fee;
END;
$$;

-- Auto-create profile on auth signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role, username)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'buyer'),
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO UPDATE SET
    email      = EXCLUDED.email,
    updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Backfill existing auth users
INSERT INTO public.profiles (id, email, full_name, role, username)
SELECT
  u.id,
  u.email,
  COALESCE(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)),
  COALESCE(u.raw_user_meta_data->>'role', 'buyer'),
  COALESCE(u.raw_user_meta_data->>'username', split_part(u.email, '@', 1))
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
ON CONFLICT (id) DO NOTHING;

-- ── RLS — Base tables ────────────────────────────────────────
ALTER TABLE profiles     ENABLE ROW LEVEL SECURITY;
ALTER TABLE carts        ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items   ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders       ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses    ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select_own"    ON profiles;
CREATE POLICY "profiles_select_own"    ON profiles FOR SELECT USING (id = auth.uid());
DROP POLICY IF EXISTS "profiles_update_own"   ON profiles;
CREATE POLICY "profiles_update_own"   ON profiles FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());
DROP POLICY IF EXISTS "profiles_insert_self"  ON profiles;
CREATE POLICY "profiles_insert_self"  ON profiles FOR INSERT WITH CHECK (id = auth.uid());
DROP POLICY IF EXISTS "profiles_select_public" ON profiles;
CREATE POLICY "profiles_select_public" ON profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "carts_owner"      ON carts;
CREATE POLICY "carts_owner"      ON carts FOR ALL USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS "cart_items_owner" ON cart_items;
CREATE POLICY "cart_items_owner" ON cart_items FOR ALL
  USING (EXISTS (SELECT 1 FROM carts WHERE carts.id = cart_items.cart_id AND carts.profile_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM carts WHERE carts.id = cart_items.cart_id AND carts.profile_id = auth.uid()));

DROP POLICY IF EXISTS "orders_owner"         ON orders;
CREATE POLICY "orders_owner"         ON orders FOR ALL USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS "notifications_owner"  ON notifications;
CREATE POLICY "notifications_owner"  ON notifications FOR ALL USING (profile_id = auth.uid());

DROP POLICY IF EXISTS "addresses_owner"      ON addresses;
CREATE POLICY "addresses_owner"      ON addresses FOR ALL USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());


-- ════════════════════════════════════════════════════════════
-- PART 2 — VENDOR APPLICATIONS
-- ════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS vendor_applications (
  id            bigserial PRIMARY KEY,
  profile_id    uuid REFERENCES profiles(id) ON DELETE CASCADE,
  business_type text CHECK (business_type IN ('formal', 'informal')) NOT NULL,
  status        text DEFAULT 'pending'
                  CHECK (status IN ('pending','approved','rejected','more_info_required')),

  -- Shared
  store_name    text NOT NULL,
  admin_notes   text,
  reviewed_at   timestamptz,
  reviewed_by   uuid REFERENCES profiles(id),

  -- Formal
  cor_url               text,
  proof_of_account_url  text,
  people                jsonb,

  -- Informal
  id_document_url             text,
  permit_url                  text,
  affidavit_url               text,
  informal_proof_of_account_url text,
  contact_info                jsonb,
  workers                     jsonb,

  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_vendor_applications_profile ON vendor_applications(profile_id);
CREATE INDEX IF NOT EXISTS idx_vendor_applications_status  ON vendor_applications(status);

ALTER TABLE vendor_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "vendor_app_owner_select" ON vendor_applications;
CREATE POLICY "vendor_app_owner_select" ON vendor_applications
  FOR SELECT USING (profile_id = auth.uid());

DROP POLICY IF EXISTS "vendor_app_owner_insert" ON vendor_applications;
CREATE POLICY "vendor_app_owner_insert" ON vendor_applications
  FOR INSERT WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS "vendor_app_owner_update" ON vendor_applications;
CREATE POLICY "vendor_app_owner_update" ON vendor_applications
  FOR UPDATE USING (profile_id = auth.uid() AND status = 'pending');

DROP POLICY IF EXISTS "vendor_app_admin_all" ON vendor_applications;
CREATE POLICY "vendor_app_admin_all" ON vendor_applications FOR ALL
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')));

-- Storage bucket for vendor docs (private)
INSERT INTO storage.buckets (id, name, public)
  VALUES ('vendor-docs', 'vendor-docs', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Vendor upload own docs"   ON storage.objects;
CREATE POLICY "Vendor upload own docs"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'vendor-docs');

DROP POLICY IF EXISTS "Vendor read own docs"     ON storage.objects;
CREATE POLICY "Vendor read own docs"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'vendor-docs' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Admin read vendor docs"   ON storage.objects;
CREATE POLICY "Admin read vendor docs"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'vendor-docs'
    AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff'))
  );


-- ════════════════════════════════════════════════════════════
-- PART 3 — PRODUCTS ENHANCEMENT (columns, categories, RLS)
-- ════════════════════════════════════════════════════════════

-- Rename legacy columns if they still exist
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'products' AND column_name = 'title') THEN
    ALTER TABLE products RENAME COLUMN title TO name;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'products' AND column_name = 'stock') THEN
    ALTER TABLE products RENAME COLUMN stock TO stock_quantity;
  END IF;
END $$;

-- Add new product columns
ALTER TABLE products
  ADD COLUMN IF NOT EXISTS status           text         DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS vendor_price     numeric(12,2),
  ADD COLUMN IF NOT EXISTS sizes            jsonb        DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS dimensions       jsonb        DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS colours          jsonb        DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS fabric_material  text,
  ADD COLUMN IF NOT EXISTS product_ref_id   text,
  ADD COLUMN IF NOT EXISTS sale_price       numeric(12,2),
  ADD COLUMN IF NOT EXISTS is_on_sale       boolean      DEFAULT false,
  ADD COLUMN IF NOT EXISTS discount_percent numeric(5,2) DEFAULT 0;

-- Seed categories (idempotent)
INSERT INTO categories (slug, label, icon) VALUES
  ('clothing',    'Clothing',    '👘'),
  ('shoes',       'Shoes',       '👟'),
  ('blankets',    'Blankets',    '🛏'),
  ('furniture',   'Furniture',   '🛋'),
  ('carpets',     'Carpets',     '🪞'),
  ('accessories', 'Accessories', '💍'),
  ('bags',        'Bags',        '👜'),
  ('toys',        'Toys',        '🧸'),
  ('kitchen',     'Kitchen',     '🍳'),
  ('electronics', 'Electronics', '📱'),
  ('sportswear',  'Sportswear',  '⚽')
ON CONFLICT (slug) DO NOTHING;

-- RLS on products + images
ALTER TABLE products       ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read active products"  ON products;
CREATE POLICY "Public read active products" ON products FOR SELECT
  USING (is_active = true OR store_id IN (SELECT id FROM stores WHERE owner = auth.uid()));

DROP POLICY IF EXISTS "Vendors insert own products"  ON products;
CREATE POLICY "Vendors insert own products" ON products FOR INSERT
  WITH CHECK (store_id IN (SELECT id FROM stores WHERE owner = auth.uid()));

DROP POLICY IF EXISTS "Vendors update own products"  ON products;
CREATE POLICY "Vendors update own products" ON products FOR UPDATE
  USING (store_id IN (SELECT id FROM stores WHERE owner = auth.uid()));

DROP POLICY IF EXISTS "Vendors delete own products"  ON products;
CREATE POLICY "Vendors delete own products" ON products FOR DELETE
  USING (store_id IN (SELECT id FROM stores WHERE owner = auth.uid()));

DROP POLICY IF EXISTS "Admin full access products"   ON products;
CREATE POLICY "Admin full access products" ON products
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')));

DROP POLICY IF EXISTS "Public read product images table"  ON product_images;
CREATE POLICY "Public read product images table" ON product_images FOR SELECT USING (true);

DROP POLICY IF EXISTS "Vendors manage own product images" ON product_images;
CREATE POLICY "Vendors manage own product images" ON product_images FOR ALL
  USING (product_id IN (
    SELECT p.id FROM products p JOIN stores s ON s.id = p.store_id WHERE s.owner = auth.uid()
  ));

-- Storage bucket for product images (public)
INSERT INTO storage.buckets (id, name, public)
  VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public read product images bucket"   ON storage.objects;
CREATE POLICY "Public read product images bucket"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'product-images');

DROP POLICY IF EXISTS "Authenticated upload product images" ON storage.objects;
CREATE POLICY "Authenticated upload product images"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'product-images');

DROP POLICY IF EXISTS "Authenticated delete product images" ON storage.objects;
CREATE POLICY "Authenticated delete product images"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'product-images');


-- ════════════════════════════════════════════════════════════
-- PART 4 — S3 (Ads), S4 (Analytics), S5 (Order Fulfillment)
-- ════════════════════════════════════════════════════════════

-- S5: extend orders
ALTER TABLE orders ADD COLUMN IF NOT EXISTS handoff_code  text;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS confirmed_at  timestamptz;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS packed_at     timestamptz;

-- S3: Ad campaigns
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
CREATE POLICY "vendors_see_own_campaigns" ON ad_campaigns FOR SELECT
  USING (store_id IN (SELECT id FROM stores WHERE owner = auth.uid()));

DROP POLICY IF EXISTS "vendors_insert_campaigns"     ON ad_campaigns;
CREATE POLICY "vendors_insert_campaigns" ON ad_campaigns FOR INSERT
  WITH CHECK (store_id IN (SELECT id FROM stores WHERE owner = auth.uid()));

DROP POLICY IF EXISTS "vendors_update_campaigns"     ON ad_campaigns;
CREATE POLICY "vendors_update_campaigns" ON ad_campaigns FOR UPDATE
  USING (store_id IN (SELECT id FROM stores WHERE owner = auth.uid()));

-- S4: Analytics subscriptions
CREATE TABLE IF NOT EXISTS analytics_subscriptions (
  id          bigserial PRIMARY KEY,
  store_id    bigint NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  status      text NOT NULL DEFAULT 'active'
                CHECK (status IN ('active','expired','cancelled')),
  amount_paid numeric(10,2) NOT NULL DEFAULT 250,
  starts_at   timestamptz NOT NULL DEFAULT now(),
  expires_at  timestamptz NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE analytics_subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "vendors_see_own_analytics_sub"    ON analytics_subscriptions;
CREATE POLICY "vendors_see_own_analytics_sub" ON analytics_subscriptions FOR SELECT
  USING (store_id IN (SELECT id FROM stores WHERE owner = auth.uid()));

DROP POLICY IF EXISTS "vendors_insert_analytics_sub"     ON analytics_subscriptions;
CREATE POLICY "vendors_insert_analytics_sub" ON analytics_subscriptions FOR INSERT
  WITH CHECK (store_id IN (SELECT id FROM stores WHERE owner = auth.uid()));

-- S5: Vendor RLS on orders (SELECT own orders OR orders with their products)
DROP POLICY IF EXISTS "vendors_see_their_orders"    ON orders;
CREATE POLICY "vendors_see_their_orders" ON orders FOR SELECT
  USING (
    profile_id = auth.uid()
    OR id IN (
      SELECT DISTINCT oi.order_id
      FROM   order_items oi
      JOIN   products    p ON p.id  = oi.product_id
      JOIN   stores      s ON s.id  = p.store_id
      WHERE  s.owner = auth.uid()
    )
  );

DROP POLICY IF EXISTS "vendors_update_their_orders" ON orders;
CREATE POLICY "vendors_update_their_orders" ON orders FOR UPDATE
  USING (
    id IN (
      SELECT DISTINCT oi.order_id
      FROM   order_items oi
      JOIN   products    p ON p.id  = oi.product_id
      JOIN   stores      s ON s.id  = p.store_id
      WHERE  s.owner = auth.uid()
    )
  );

-- Vendor RLS on order_items
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "buyers_see_own_order_items"    ON order_items;
CREATE POLICY "buyers_see_own_order_items" ON order_items FOR SELECT
  USING (order_id IN (SELECT id FROM orders WHERE profile_id = auth.uid()));

DROP POLICY IF EXISTS "vendors_see_their_order_items" ON order_items;
CREATE POLICY "vendors_see_their_order_items" ON order_items FOR SELECT
  USING (
    product_id IN (
      SELECT p.id FROM products p JOIN stores s ON s.id = p.store_id WHERE s.owner = auth.uid()
    )
  );


-- ════════════════════════════════════════════════════════════
-- PART 5 — S6 (Inventory triggers) & S7 (Category parents)
-- ════════════════════════════════════════════════════════════

-- S6: Decrement stock on order_items INSERT
CREATE OR REPLACE FUNCTION decrement_product_stock()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE products
  SET    stock_quantity = GREATEST(stock_quantity - NEW.quantity, 0),
         updated_at     = now()
  WHERE  id = NEW.product_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_decrement_stock ON order_items;
CREATE TRIGGER trg_decrement_stock
  AFTER INSERT ON order_items
  FOR EACH ROW EXECUTE FUNCTION decrement_product_stock();

-- S6: Auto-hide at 0, auto-show on restock, low-stock notification
CREATE OR REPLACE FUNCTION handle_stock_change()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_owner uuid;
BEGIN
  IF NEW.stock_quantity IS NOT DISTINCT FROM OLD.stock_quantity THEN
    RETURN NEW;
  END IF;

  -- Auto-hide when stock hits zero
  IF NEW.stock_quantity = 0 AND COALESCE(OLD.stock_quantity, 1) > 0 THEN
    NEW.is_active := false;
  END IF;

  -- Auto-restore when restocked from zero
  IF NEW.stock_quantity > 0 AND COALESCE(OLD.stock_quantity, 1) = 0 THEN
    NEW.is_active := true;
  END IF;

  -- Low-stock notification: crossed below 3
  IF NEW.stock_quantity > 0
     AND NEW.stock_quantity < 3
     AND COALESCE(OLD.stock_quantity, 3) >= 3
  THEN
    SELECT s.owner INTO v_owner FROM stores s WHERE s.id = NEW.store_id;
    IF v_owner IS NOT NULL THEN
      INSERT INTO notifications (profile_id, title, body, data) VALUES (
        v_owner,
        'Low Stock Alert',
        '"' || NEW.name || '" has only ' || NEW.stock_quantity || ' unit(s) left — restock soon.',
        jsonb_build_object('type','low_stock','product_id',NEW.id,'stock',NEW.stock_quantity)
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_handle_stock_change ON products;
CREATE TRIGGER trg_handle_stock_change
  BEFORE UPDATE OF stock_quantity ON products
  FOR EACH ROW EXECUTE FUNCTION handle_stock_change();

-- S7: parent_slug column + mappings
ALTER TABLE categories ADD COLUMN IF NOT EXISTS parent_slug text;

UPDATE categories SET parent_slug = 'clothes'
  WHERE slug IN ('clothing','shoes','accessories','sportswear','bags');

UPDATE categories SET parent_slug = 'household'
  WHERE slug IN ('blankets','furniture','carpets','kitchen','toys');

UPDATE categories SET parent_slug = 'electronics'
  WHERE slug = 'electronics';

CREATE INDEX IF NOT EXISTS idx_categories_parent ON categories(parent_slug);


-- ════════════════════════════════════════════════════════════
-- DONE — all 5 parts applied
-- ════════════════════════════════════════════════════════════
