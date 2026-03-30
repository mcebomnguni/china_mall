-- ═══════════════════════════════════════════════════════════════════════
-- China Stall — Products Enhancement Migration
-- Run in Supabase SQL Editor (project: ipsdpswdubdczxfbvtty)
-- ═══════════════════════════════════════════════════════════════════════

-- 1. Rename columns (safe — only runs if old name still exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'products' AND column_name = 'title'
  ) THEN
    ALTER TABLE products RENAME COLUMN title TO name;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'products' AND column_name = 'stock'
  ) THEN
    ALTER TABLE products RENAME COLUMN stock TO stock_quantity;
  END IF;
END $$;

-- 2. Add new product columns
ALTER TABLE products
  ADD COLUMN IF NOT EXISTS status          text            DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS vendor_price    numeric(12,2),
  ADD COLUMN IF NOT EXISTS sizes           jsonb           DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS dimensions      jsonb           DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS colours         jsonb           DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS fabric_material text,
  ADD COLUMN IF NOT EXISTS product_ref_id  text,
  ADD COLUMN IF NOT EXISTS sale_price      numeric(12,2),
  ADD COLUMN IF NOT EXISTS is_on_sale      boolean         DEFAULT false,
  ADD COLUMN IF NOT EXISTS discount_percent numeric(5,2)   DEFAULT 0;

-- 3. Seed categories (idempotent)
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

-- 4. Enable RLS
ALTER TABLE products       ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;

-- 5. Products RLS policies
DROP POLICY IF EXISTS "Public read active products"  ON products;
DROP POLICY IF EXISTS "Vendors insert own products"  ON products;
DROP POLICY IF EXISTS "Vendors update own products"  ON products;
DROP POLICY IF EXISTS "Vendors delete own products"  ON products;
DROP POLICY IF EXISTS "Admin full access products"   ON products;

CREATE POLICY "Public read active products"
  ON products FOR SELECT
  USING (
    is_active = true
    OR store_id IN (SELECT id FROM stores WHERE owner = auth.uid())
  );

CREATE POLICY "Vendors insert own products"
  ON products FOR INSERT
  WITH CHECK (store_id IN (SELECT id FROM stores WHERE owner = auth.uid()));

CREATE POLICY "Vendors update own products"
  ON products FOR UPDATE
  USING (store_id IN (SELECT id FROM stores WHERE owner = auth.uid()));

CREATE POLICY "Vendors delete own products"
  ON products FOR DELETE
  USING (store_id IN (SELECT id FROM stores WHERE owner = auth.uid()));

CREATE POLICY "Admin full access products"
  ON products
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'staff'))
  );

-- 6. Product images RLS policies
DROP POLICY IF EXISTS "Public read product images table"    ON product_images;
DROP POLICY IF EXISTS "Vendors manage own product images"   ON product_images;

CREATE POLICY "Public read product images table"
  ON product_images FOR SELECT
  USING (true);

CREATE POLICY "Vendors manage own product images"
  ON product_images FOR ALL
  USING (
    product_id IN (
      SELECT p.id FROM products p
      JOIN stores s ON s.id = p.store_id
      WHERE s.owner = auth.uid()
    )
  );

-- 7. Storage bucket for product images (public)
INSERT INTO storage.buckets (id, name, public)
  VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
DROP POLICY IF EXISTS "Public read product images bucket"       ON storage.objects;
DROP POLICY IF EXISTS "Authenticated upload product images"     ON storage.objects;
DROP POLICY IF EXISTS "Authenticated delete product images"     ON storage.objects;

CREATE POLICY "Public read product images bucket"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'product-images');

CREATE POLICY "Authenticated upload product images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'product-images');

CREATE POLICY "Authenticated delete product images"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'product-images');
