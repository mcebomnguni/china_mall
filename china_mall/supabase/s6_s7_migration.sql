-- ============================================================
-- S6: Inventory Management (auto-stock triggers)
-- S7: Category Parent Structure
-- Run in the Supabase SQL Editor
-- ============================================================

-- ── S6: Decrement stock when an order item is inserted ───────────────────────
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

-- ── S6: Auto-hide at 0, auto-show on restock, low-stock notification ─────────
CREATE OR REPLACE FUNCTION handle_stock_change()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_owner uuid;
BEGIN
  -- Only act when stock_quantity actually changed
  IF NEW.stock_quantity IS NOT DISTINCT FROM OLD.stock_quantity THEN
    RETURN NEW;
  END IF;

  -- Auto-hide when stock hits zero
  IF NEW.stock_quantity = 0 AND COALESCE(OLD.stock_quantity, 1) > 0 THEN
    NEW.is_active := false;
  END IF;

  -- Auto-restore visibility when stock is replenished from zero
  IF NEW.stock_quantity > 0 AND COALESCE(OLD.stock_quantity, 1) = 0 THEN
    NEW.is_active := true;
  END IF;

  -- Low-stock notification: stock just crossed below 3 (still above 0)
  IF NEW.stock_quantity > 0
     AND NEW.stock_quantity < 3
     AND COALESCE(OLD.stock_quantity, 3) >= 3
  THEN
    SELECT s.owner INTO v_owner
    FROM   stores s
    WHERE  s.id = NEW.store_id;

    IF v_owner IS NOT NULL THEN
      INSERT INTO notifications (profile_id, title, body, data)
      VALUES (
        v_owner,
        'Low Stock Alert',
        '"' || NEW.name || '" has only ' || NEW.stock_quantity
          || ' unit(s) left — restock soon.',
        jsonb_build_object(
          'type',       'low_stock',
          'product_id', NEW.id,
          'stock',      NEW.stock_quantity
        )
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

-- ── S7: Add parent_slug column to categories ─────────────────────────────────
ALTER TABLE categories ADD COLUMN IF NOT EXISTS parent_slug text;

-- Map sub-categories to their parent groups
UPDATE categories SET parent_slug = 'clothes'
  WHERE slug IN ('clothing','shoes','accessories','sportswear','bags');

UPDATE categories SET parent_slug = 'household'
  WHERE slug IN ('blankets','furniture','carpets','kitchen','toys');

UPDATE categories SET parent_slug = 'electronics'
  WHERE slug = 'electronics';

-- Index for fast parent lookups
CREATE INDEX IF NOT EXISTS idx_categories_parent ON categories(parent_slug);
