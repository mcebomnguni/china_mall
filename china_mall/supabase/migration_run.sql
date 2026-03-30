-- China Mall — full schema migration (safe to re-run)

-- ── Extensions ───────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Profiles ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY,
  email text,
  phone text,
  full_name text,
  avatar_url text,
  role text DEFAULT 'buyer',
  is_online boolean DEFAULT false,
  username text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ── Categories ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS categories (
  id bigserial PRIMARY KEY,
  slug text UNIQUE NOT NULL,
  label text NOT NULL,
  icon text,
  created_at timestamptz DEFAULT now()
);

-- ── Stores ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS stores (
  id bigserial PRIMARY KEY,
  owner uuid REFERENCES profiles(id) ON DELETE SET NULL,
  name text NOT NULL,
  description text,
  cover_url text,
  slug text UNIQUE,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ── Products ──────────────────────────────────────────────────────────────────
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

CREATE TABLE IF NOT EXISTS product_images (
  id bigserial PRIMARY KEY,
  product_id bigint REFERENCES products(id) ON DELETE CASCADE,
  url text NOT NULL,
  ordinal integer DEFAULT 0
);

-- ── Cart ──────────────────────────────────────────────────────────────────────
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

-- ── Orders ────────────────────────────────────────────────────────────────────
DO $$ BEGIN
  CREATE TYPE order_status AS ENUM (
    'pending_payment','payment_confirmed','processing','awaiting_pickup',
    'picked_up','in_transit','out_for_delivery','delivered','cancelled',
    'return_requested','returned','disputed'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

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

-- ── Vouchers ──────────────────────────────────────────────────────────────────
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

-- ── Devices ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS devices (
  id bigserial PRIMARY KEY,
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  device_id text,
  last_seen timestamptz DEFAULT now()
);

-- ── Reviews ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reviews (
  id bigserial PRIMARY KEY,
  product_id bigint REFERENCES products(id) ON DELETE CASCADE,
  profile_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  rating smallint CHECK (rating >= 1 AND rating <= 5),
  body text,
  created_at timestamptz DEFAULT now()
);

-- ── Disputes ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS disputes (
  id bigserial PRIMARY KEY,
  order_id bigint REFERENCES orders(id) ON DELETE CASCADE,
  raised_by uuid REFERENCES profiles(id),
  reason text,
  status text DEFAULT 'open',
  created_at timestamptz DEFAULT now()
);

-- ── Audit logs ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_logs (
  id bigserial PRIMARY KEY,
  actor uuid,
  action text NOT NULL,
  resource_type text,
  resource_id text,
  details jsonb,
  created_at timestamptz DEFAULT now()
);

-- ── Addresses ────────────────────────────────────────────────────────────────
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

-- ── Deliveries ────────────────────────────────────────────────────────────────
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

-- ── Courier ───────────────────────────────────────────────────────────────────
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

-- ── Notifications ─────────────────────────────────────────────────────────────
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

-- ── OTP / Reset tables ────────────────────────────────────────────────────────
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

-- ── Indexes ───────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_products_store ON products(store_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_orders_profile ON orders(profile_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- ── Functions ─────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION admin_overview(days integer DEFAULT 30)
RETURNS jsonb LANGUAGE sql AS $$
  SELECT jsonb_build_object(
    'total_orders', (SELECT count(*) FROM orders WHERE created_at >= now() - (days || ' days')::interval),
    'total_revenue', (SELECT COALESCE(sum(total_amount),0) FROM orders WHERE created_at >= now() - (days || ' days')::interval),
    'orders_by_day', (SELECT jsonb_agg(row_to_json(t)) FROM (
      SELECT date_trunc('day', created_at) as day, count(*) as orders, COALESCE(sum(total_amount),0) as revenue
      FROM orders WHERE created_at >= now() - (days || ' days')::interval
      GROUP BY 1 ORDER BY 1
    ) t)
  );
$$;

CREATE OR REPLACE FUNCTION calculate_delivery_fee(cart_json jsonb, method text)
RETURNS numeric LANGUAGE plpgsql AS $$
DECLARE
  item_count integer := 0;
  base_fee numeric := 0;
  fee numeric := 0;
BEGIN
  SELECT COALESCE(SUM((item->>'quantity')::int), 0) INTO item_count
  FROM jsonb_array_elements(cart_json->'items') as item;
  IF method = 'express' THEN base_fee := 50; ELSE base_fee := 20; END IF;
  fee := base_fee + (item_count * 5);
  RETURN fee;
END;
$$;

-- Auto-create profile when a new auth user signs up
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
    email = EXCLUDED.email,
    updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Backfill profiles for existing auth users that have no profile yet
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

-- ── Row Level Security ────────────────────────────────────────────────────────
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE carts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;

-- Profiles policies
DROP POLICY IF EXISTS "profiles_select_own" ON profiles;
CREATE POLICY "profiles_select_own" ON profiles FOR SELECT USING (id = auth.uid());

DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "profiles_insert_self" ON profiles;
CREATE POLICY "profiles_insert_self" ON profiles FOR INSERT WITH CHECK (id = auth.uid());

-- Allow users to read all profiles (for vendor/store listings)
DROP POLICY IF EXISTS "profiles_select_public" ON profiles;
CREATE POLICY "profiles_select_public" ON profiles FOR SELECT USING (true);

-- Carts policies
DROP POLICY IF EXISTS "carts_owner" ON carts;
CREATE POLICY "carts_owner" ON carts FOR ALL USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());

-- Cart items policies
DROP POLICY IF EXISTS "cart_items_owner" ON cart_items;
CREATE POLICY "cart_items_owner" ON cart_items FOR ALL
  USING (EXISTS (SELECT 1 FROM carts WHERE carts.id = cart_items.cart_id AND carts.profile_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM carts WHERE carts.id = cart_items.cart_id AND carts.profile_id = auth.uid()));

-- Orders policies
DROP POLICY IF EXISTS "orders_owner" ON orders;
CREATE POLICY "orders_owner" ON orders FOR ALL USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());

-- Notifications policies
DROP POLICY IF EXISTS "notifications_owner" ON notifications;
CREATE POLICY "notifications_owner" ON notifications FOR ALL USING (profile_id = auth.uid());

-- Addresses policies
DROP POLICY IF EXISTS "addresses_owner" ON addresses;
CREATE POLICY "addresses_owner" ON addresses FOR ALL USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());
