-- Supabase schema for China Mall (initial)
-- Run in Supabase SQL editor or via psql connected to your Supabase Postgres database.

-- Ensure extensions if needed (for UUID generation)
-- CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Profiles: link to auth.users.id (uuid)
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY,
  email text,
  phone text,
  full_name text,
  avatar_url text,
  role text DEFAULT 'buyer',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Categories
CREATE TABLE IF NOT EXISTS categories (
  id bigserial PRIMARY KEY,
  slug text UNIQUE NOT NULL,
  label text NOT NULL,
  icon text,
  created_at timestamptz DEFAULT now()
);

-- Stores
CREATE TABLE IF NOT EXISTS stores (
  id bigserial PRIMARY KEY,
  owner uuid REFERENCES profiles(id) ON DELETE SET NULL,
  name text NOT NULL,
  description text,
  cover_url text,
  slug text UNIQUE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Products
CREATE TABLE IF NOT EXISTS products (
  id bigserial PRIMARY KEY,
  store_id bigint REFERENCES stores(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  price numeric(12,2) NOT NULL DEFAULT 0,
  currency text DEFAULT 'ZAR',
  stock integer DEFAULT 0,
  category_id bigint REFERENCES categories(id),
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Product images
CREATE TABLE IF NOT EXISTS product_images (
  id bigserial PRIMARY KEY,
  product_id bigint REFERENCES products(id) ON DELETE CASCADE,
  url text NOT NULL,
  ordinal integer DEFAULT 0
);

-- Cart and items (per user)
CREATE TABLE IF NOT EXISTS carts (
  id bigserial PRIMARY KEY,
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cart_items (
  id bigserial PRIMARY KEY,
  cart_id bigint REFERENCES carts(id) ON DELETE CASCADE,
  product_id bigint REFERENCES products(id),
  quantity integer NOT NULL DEFAULT 1,
  price_at_added numeric(12,2),
  created_at timestamptz DEFAULT now()
);

-- Orders and items
CREATE TYPE order_status AS ENUM (
  'pending_payment', 'payment_confirmed', 'processing', 'awaiting_pickup',
  'picked_up', 'in_transit', 'out_for_delivery', 'delivered', 'cancelled',
  'return_requested', 'returned', 'disputed'
);

CREATE TABLE IF NOT EXISTS orders (
  id bigserial PRIMARY KEY,
  profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  total_amount numeric(12,2) DEFAULT 0,
  currency text DEFAULT 'ZAR',
  status order_status DEFAULT 'pending_payment',
  shipping_address jsonb,
  payment_meta jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS order_items (
  id bigserial PRIMARY KEY,
  order_id bigint REFERENCES orders(id) ON DELETE CASCADE,
  product_id bigint REFERENCES products(id),
  quantity integer DEFAULT 1,
  unit_price numeric(12,2),
  created_at timestamptz DEFAULT now()
);

-- Vouchers
CREATE TABLE IF NOT EXISTS vouchers (
  id bigserial PRIMARY KEY,
  code text UNIQUE NOT NULL,
  discount_percent integer,
  discount_amount numeric(12,2),
  valid_from timestamptz,
  valid_to timestamptz,
  usage_limit integer DEFAULT 1,
  times_used integer DEFAULT 0,
  active boolean DEFAULT true
);

-- Linked devices
CREATE TABLE IF NOT EXISTS devices (
  id bigserial PRIMARY KEY,
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  device_id text,
  last_seen timestamptz DEFAULT now()
);

-- Reviews
CREATE TABLE IF NOT EXISTS reviews (
  id bigserial PRIMARY KEY,
  product_id bigint REFERENCES products(id) ON DELETE CASCADE,
  profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  rating smallint CHECK (rating >= 1 AND rating <= 5),
  body text,
  created_at timestamptz DEFAULT now()
);

-- Disputes
CREATE TABLE IF NOT EXISTS disputes (
  id bigserial PRIMARY KEY,
  order_id bigint REFERENCES orders(id) ON DELETE CASCADE,
  raised_by uuid REFERENCES profiles(id),
  reason text,
  status text DEFAULT 'open',
  created_at timestamptz DEFAULT now()
);

-- Indexes (examples)
CREATE INDEX IF NOT EXISTS idx_products_store ON products(store_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_orders_profile ON orders(profile_id);

-- RLS and policies: placeholder comments — implement per-table depending on needs
-- Example: allow users to select/insert their own cart items
-- ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "cart_owner" ON cart_items USING (cart_id IN (SELECT id FROM carts WHERE profile_id = auth.uid())) WITH CHECK (cart_id IN (SELECT id FROM carts WHERE profile_id = auth.uid()));

-- Edge Functions / Stored Procedures suggestions
-- 1) `calculate_delivery_fee(cart_id json)` -> returns fee
-- 2) `admin_overview()` -> returns admin metrics (use materialized views)
-- 3) `distribute_orders()` -> distribution algorithm for couriers

-- Admin overview: sample function returning revenue and order counts for the last N days
CREATE OR REPLACE FUNCTION admin_overview(days integer DEFAULT 30)
RETURNS jsonb LANGUAGE sql AS $$
  SELECT jsonb_build_object(
    'total_orders', (SELECT count(*) FROM orders WHERE created_at >= now() - (days || ' days')::interval),
    'total_revenue', (SELECT COALESCE(sum(total_amount),0) FROM orders WHERE created_at >= now() - (days || ' days')::interval),
    'orders_by_day', (SELECT jsonb_agg(row_to_json(t)) FROM (
      SELECT date_trunc('day', created_at) as day, count(*) as orders, COALESCE(sum(total_amount),0) as revenue
      FROM orders
      WHERE created_at >= now() - (days || ' days')::interval
      GROUP BY 1
      ORDER BY 1
    ) t)
  );
$$;

-- Example SQL function to calculate delivery fee.
-- This is a simple placeholder; replace with your real business rules.
CREATE OR REPLACE FUNCTION calculate_delivery_fee(cart_json jsonb, method text)
RETURNS numeric LANGUAGE plpgsql AS $$
DECLARE
  item_count integer := 0;
  base_fee numeric := 0;
  fee numeric := 0;
BEGIN
  -- Count items
  SELECT COALESCE(SUM((item->>'quantity')::int), 0) INTO item_count
  FROM jsonb_array_elements(cart_json->'items') as item;

  IF method = 'express' THEN
    base_fee := 50;
  ELSE
    base_fee := 20;
  END IF;

  -- Simple scaling by item count
  fee := base_fee + (item_count * 5);
  RETURN fee;
END;
$$;

-- ---------------------------
-- Row Level Security examples
-- ---------------------------

-- Enable RLS on tables that contain per-user private data
ALTER TABLE IF EXISTS profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS carts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS orders ENABLE ROW LEVEL SECURITY;

-- Profiles: users can read/update their own profile; inserts must use auth.uid()
CREATE POLICY IF NOT EXISTS "profiles_select_own" ON profiles
  FOR SELECT USING (id = auth.uid());

CREATE POLICY IF NOT EXISTS "profiles_update_own" ON profiles
  FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());

CREATE POLICY IF NOT EXISTS "profiles_insert_self" ON profiles
  FOR INSERT WITH CHECK (id = auth.uid());

-- Carts: only the owner may select/insert/update/delete their carts
CREATE POLICY IF NOT EXISTS "carts_owner" ON carts
  FOR ALL USING (profile_id::text = auth.uid()) WITH CHECK (profile_id::text = auth.uid());

-- Cart items: allow operations only when the parent cart belongs to the current user
CREATE POLICY IF NOT EXISTS "cart_items_owner" ON cart_items
  FOR ALL USING (
    EXISTS (SELECT 1 FROM carts WHERE carts.id = cart_items.cart_id AND carts.profile_id::text = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM carts WHERE carts.id = cart_items.cart_id AND carts.profile_id::text = auth.uid())
  );

-- Orders: owners can view and modify their orders. Admin/staff policies should be added separately.
CREATE POLICY IF NOT EXISTS "orders_owner" ON orders
  FOR ALL USING (profile_id::text = auth.uid()) WITH CHECK (profile_id::text = auth.uid());

-- Notes:
-- - These example policies assume the `profiles.id` is the same UUID as `auth.uid()` provided by Supabase Auth.
-- - Adjust policies for staff/admin roles (you can use `auth.role()` or custom claims in JWT to allow staff access).
-- - Test policies in Supabase SQL editor and the Policy simulator before deploying.

-- Audit logs: records admin actions and system events
CREATE TABLE IF NOT EXISTS audit_logs (
  id bigserial PRIMARY KEY,
  actor uuid,
  action text NOT NULL,
  resource_type text,
  resource_id text,
  details jsonb,
  created_at timestamptz DEFAULT now()
);

-- Addresses (user saved addresses)
CREATE TABLE IF NOT EXISTS addresses (
  id bigserial PRIMARY KEY,
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  label text,
  full_address text,
  lat double precision,
  lng double precision,
  is_default boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Deliveries and tracking
CREATE TABLE IF NOT EXISTS deliveries (
  id bigserial PRIMARY KEY,
  order_id bigint REFERENCES orders(id) ON DELETE SET NULL,
  delivery_type text,
  pickup_address text,
  pickup_lat double precision,
  pickup_lng double precision,
  delivery_address text,
  delivery_lat double precision,
  delivery_lng double precision,
  weight_kg numeric(8,2) DEFAULT 1,
  status text DEFAULT 'created',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS delivery_tracking (
  id bigserial PRIMARY KEY,
  delivery_id bigint REFERENCES deliveries(id) ON DELETE CASCADE,
  status text,
  notes text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS driver_locations (
  id bigserial PRIMARY KEY,
  delivery_id bigint REFERENCES deliveries(id) ON DELETE CASCADE,
  lat double precision,
  lng double precision,
  recorded_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS drivers (
  id bigserial PRIMARY KEY,
  profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  is_online boolean DEFAULT false,
  vehicle_info jsonb,
  updated_at timestamptz DEFAULT now()
);

-- Courier documents and banking details
CREATE TABLE IF NOT EXISTS courier_documents (
  id bigserial PRIMARY KEY,
  profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  doc_type text,
  file_url text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS courier_bank_details (
  id bigserial PRIMARY KEY,
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  account_name text,
  account_number text,
  bank_name text,
  updated_at timestamptz DEFAULT now()
);

-- Notifications
CREATE TABLE IF NOT EXISTS notification_devices (
  id bigserial PRIMARY KEY,
  profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  token text UNIQUE,
  platform text,
  device_name text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notifications (
  id bigserial PRIMARY KEY,
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  title text,
  body text,
  data jsonb,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- End of schema

-- Phone OTPs and resets (used by Edge Functions for phone-based recovery)
CREATE TABLE IF NOT EXISTS phone_otps (
  id bigserial PRIMARY KEY,
  phone_number text NOT NULL,
  code text NOT NULL,
  purpose text DEFAULT 'password_reset',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS phone_resets (
  id bigserial PRIMARY KEY,
  phone_number text NOT NULL,
  reset_token text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Email OTPs and resets (used by email-based recovery flows)
CREATE TABLE IF NOT EXISTS email_otps (
  id bigserial PRIMARY KEY,
  email text NOT NULL,
  code text NOT NULL,
  purpose text DEFAULT 'password_reset',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS email_resets (
  id bigserial PRIMARY KEY,
  email text NOT NULL,
  reset_token text NOT NULL,
  created_at timestamptz DEFAULT now()
);
