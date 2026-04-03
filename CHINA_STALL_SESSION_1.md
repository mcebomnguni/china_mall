# China Stall — Session 1: UI Overhaul

## CONTEXT
The app is functionally 76% complete but the UI does not match the approved design direction. This session focuses ONLY on visual/UI changes — no new features, no new screens, no backend changes. We are converting the app from its current green theme to the approved red/cream/gold design system with proper icons.

## PRE-BUILD
1. Read **CLAUDE.md** in the project root
2. Invoke **ui-ux-pro-max** and **frontend-design** skills
3. **LOOK AT THE DESIGN REFERENCE IMAGES** — they are in the project root folder. View each one before making any changes:
   - `ref_all_screens.png` — Full 7-screen showcase (Home, Shop, Trends, Product, Cart, Order Tracking, Profile)
   - `ref_home.png` — Home screen close-up (welcome greeting, search bar, promo carousel, categories, featured products)
   - `ref_shop.png` — Shop/Categories page close-up (photo grid + store list)
   - `ref_trends.png` — Trends page close-up (collection banner + hashtag chips + product grid)
   - `ref_cart.png` — Cart page close-up (vendor-grouped items)
   - `ref_store_detail.png` — Store detail page (banner, ratings, product grid, Follow/Message buttons)
   - `ref_order_tracking.png` — Order tracking variations (timeline + map + summary)
   - `ref_product_detail.png` — Product detail page (image, price, sizes, delivery info)
   - `ref_profile.png` — Profile/Me page close-up (My Orders, Wishlist, menu list)

   These images are the design authority. Every UI change must match what you see in them.
4. Create a feature branch:
```bash
git checkout -b feature/ui-overhaul-session-1
```

## CRITICAL RULE: NO EMOJIS. NOT ONE. ANYWHERE.
If you encounter ANY emoji character in the codebase (👗👘👟💍⚽👜🛏🛋🪞🍳🧸📱🧪 or ANY other emoji), replace it with a Lucide icon. This is the #1 priority of this entire session.

---

## STEP 1: Install Lucide Icons Package

```bash
flutter pub add lucide_icons
```

This gives access to 1400+ clean line icons via `LucideIcons.iconName`. These icons match the style in the design references — clean, consistent line weight, professional.

**Icon mapping — replace EVERY emoji with these Lucide equivalents:**

| Current Emoji | Lucide Replacement | Code |
|---------------|-------------------|------|
| 👗 Clothing | `LucideIcons.shirt` | `Icon(LucideIcons.shirt)` |
| 👘 Traditional | `LucideIcons.shirt` | `Icon(LucideIcons.shirt)` |
| 👟 Shoes | `LucideIcons.footprints` | `Icon(LucideIcons.footprints)` |
| 💍 Jewellery | `LucideIcons.gem` | `Icon(LucideIcons.gem)` |
| ⚽ Sports | `LucideIcons.dumbbell` | `Icon(LucideIcons.dumbbell)` |
| 👜 Bags | `LucideIcons.shoppingBag` | `Icon(LucideIcons.shoppingBag)` |
| 🛏 Blankets/Bed | `LucideIcons.bedDouble` | `Icon(LucideIcons.bedDouble)` |
| 🛋 Furniture | `LucideIcons.sofa` | `Icon(LucideIcons.sofa)` |
| 🪞 Carpets/Mirror | `LucideIcons.frame` | `Icon(LucideIcons.frame)` |
| 🍳 Kitchen | `LucideIcons.chefHat` | `Icon(LucideIcons.chefHat)` |
| 🧸 Kids | `LucideIcons.baby` | `Icon(LucideIcons.baby)` |
| 📱 Electronics | `LucideIcons.smartphone` | `Icon(LucideIcons.smartphone)` |
| 🧪 Test mode | `LucideIcons.flask` or `LucideIcons.testTube2` | `Icon(LucideIcons.testTube2)` |

**Search the ENTIRE codebase** for emoji characters. Check:
- `app_constants.dart` or wherever categories are defined
- Any widget that renders category icons
- Any hardcoded strings with emoji
- Any mock data files
- Test badges or debug indicators

Run this to find them all:
```bash
grep -rn '[^\x00-\x7F]' lib/ --include="*.dart" | grep -v "// " | head -50
```

Replace every single one. Zero emojis remaining when this step is done.

---

## STEP 2: Color Scheme — Green to Red

Find the theme/colors definition file (likely `theme.dart`, `colors.dart`, `app_theme.dart`, or similar). Replace the entire color palette:

**Current green values → New red values:**

```dart
// PRIMARY
// Old: #1D6B46 (green) → New: #D42B2B (red)
// Old: #133523 (dark green) → New: #2D1A1A (dark charcoal-red)
// Old: #E8F5E9 (light green) → New: #FEE2E2 (light red)

// FULL NEW PALETTE:
static const Color primary = Color(0xFFD42B2B);          // Bold red
static const Color primaryDark = Color(0xFFB91C1C);       // Darker red
static const Color primaryLight = Color(0xFFFEE2E2);      // Light red tint
static const Color accent = Color(0xFFD4A843);            // Gold accent
static const Color accentLight = Color(0xFFFEF3C7);       // Light gold

static const Color background = Color(0xFFFAF8F5);        // Warm cream
static const Color surface = Color(0xFFFFFFFF);            // White cards
static const Color surfaceVariant = Color(0xFFF5F0EB);     // Slightly warmer white

static const Color navBar = Color(0xFF2D1A1A);             // Dark charcoal-red nav bar
static const Color navBarIcon = Color(0xFFFFFFFF);          // White icons
static const Color navBarIconInactive = Color(0x80FFFFFF);  // 50% white

static const Color textPrimary = Color(0xFF1F2937);        // Dark charcoal text
static const Color textSecondary = Color(0xFF6B7280);       // Grey text
static const Color textMuted = Color(0xFF9CA3AF);           // Light grey text
static const Color sectionLabel = Color(0xFF6B7280);        // Uppercase section headers

static const Color success = Color(0xFF16A34A);             // Green (confirmations, verified)
static const Color warning = Color(0xFFF59E0B);             // Amber (pending states)
static const Color error = Color(0xFFDC2626);               // Error red
static const Color starRating = Color(0xFFF59E0B);          // Gold stars

static const Color divider = Color(0xFFF3F4F6);            // Light divider
static const Color border = Color(0xFFE5E7EB);             // Input/card borders
static const Color cardShadow = Color(0x0A000000);          // Very subtle shadow

// GRADIENTS
static const LinearGradient primaryGradient = LinearGradient(
  colors: [Color(0xFFD42B2B), Color(0xFFE85D3A)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

static const LinearGradient promoBannerGradient = LinearGradient(
  colors: [Color(0xFFD42B2B), Color(0xFFC41E1E), Color(0xFFB91C1C)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
```

**Do a global search and replace** across the entire codebase for the old green hex values:
- `#1D6B46` or `0xFF1D6B46` → `0xFFD42B2B`
- `#133523` or `0xFF133523` → `0xFF2D1A1A`
- Any other green hex values → map to the closest red equivalent
- Light green backgrounds → warm cream `#FAF8F5`
- Green toggles → red toggles
- Green badges → red badges (except success states which stay green)

**Important:** Keep `success` / `confirmed` / `verified` states as GREEN (#16A34A). Only the brand/primary colors change from green to red.

---

## STEP 3: Bottom Navigation Bar — 4 Tabs to 5 Tabs

The current nav has 4 tabs: Main, Feed, Activity, You. Update to 5 tabs matching the design references:

**New 5-tab configuration:**

| Tab | Icon | Label | Lucide Icon |
|-----|------|-------|-------------|
| Home | House | "Home" | `LucideIcons.home` |
| Shop | Search with lines | "Shop" | `LucideIcons.search` |
| Trends | Trending up arrow | "Trends" | `LucideIcons.trendingUp` |
| Cart | Shopping bag | "Cart" | `LucideIcons.shoppingBag` |
| Me | Person | "Me" | `LucideIcons.user` |

**Cart tab special treatment:**
- Show red count badge (circle) on the cart icon with the number of items
- Below the badge, show the cart total in small red text (e.g., "R1,456") — only if items exist

**Nav bar styling:**
- Keep the floating dark pill shape (it's already there)
- Update the background color from dark green (#133523) to dark charcoal-red (#2D1A1A)
- Active tab: white icon + red label text + subtle red glow pill behind the icon (Container with `borderRadius: 12`, `color: primaryColor.withOpacity(0.15)`)
- Inactive tab: semi-transparent white icon (50% opacity) + no label or grey label
- Icon size: 24
- Label size: 10px
- Smooth scale animation on tab switch: active icon scales 1.0 → 1.1

**Route mapping for new tabs:**
- Home → existing home screen (update content in Session 2)
- Shop → existing store browsing screen (rename tab label)
- Trends → placeholder screen for now: centered text "Trends — Coming Soon" with `LucideIcons.trendingUp` icon above (build fully in Session 2)
- Cart → existing cart screen
- Me → existing profile screen (rename tab label)

---

## STEP 4: Group Cart Items by Vendor

The cart currently shows a flat list of items. Update to group items by store/vendor, matching the SHEIN-style cart in the design references.

**Layout per vendor group:**
```
┌─────────────────────────────────────┐
│ ☑️ Fashion Hub                    🗑 │  ← Vendor header with checkbox + delete
│ ┌──────┐ Leather Jacket              │
│ │ IMG  │ Size/Color                   │
│ │      │ R349  R̶5̶9̶9̶  — 1 +         │  ← Price, strikethrough, quantity
│ └──────┘                              │
│ ┌──────┐ Sneakers                     │
│ │ IMG  │ Size/Color                   │
│ │      │ R149  R̶2̶4̶9̶  — 1 +         │
│ └──────┘                              │
├─────────────────────────────────────┤
│ ☑️ Dragon Fashion                 🗑 │  ← Next vendor group
│ ┌──────┐ Silk Shirt                   │
│ │ IMG  │ ...                          │
│ └──────┘                              │
└─────────────────────────────────────┘
```

**Implementation:**
1. Find the cart screen (likely `cart_screen.dart` or similar)
2. Get the list of cart items
3. Group them by `storeId` or `storeName` using Dart's collection groupBy:
```dart
import 'package:collection/collection.dart';
final grouped = groupBy(cartItems, (item) => item.storeId);
```
4. Render each group with:
   - **Vendor header:** Checkbox (select all from this vendor) + Store name bold + Store icon/logo + Delete all from vendor icon (trash)
   - **Items under vendor:** Each item has its own checkbox + product thumbnail + name + size/color variant + red price + grey strikethrough original price + quantity controls (- 1 +)
   - Urgency badges where applicable: "Almost Sold Out" red overlay on thumbnail
   - Divider between vendor groups

5. **Sticky bottom bar:**
   - Total in large bold red: "R7,613"
   - "Saved R1,456" in green text (if any discounts)
   - "Checkout" button — dark/black filled, rounded, bold white text

**If `collection` package isn't installed:**
```bash
flutter pub add collection
```

---

## STEP 5: Category Display — Emoji Scroll to Photo Grid

Find where categories are displayed on the home/browse screen (the horizontal scroll with emoji icons). Replace it with proper category icons using Lucide inside rounded square cards.

**Current:** Horizontal scroll of emoji icons (👗, 👟, 🛏, 🛋, 🪞, etc.)

**New:** Horizontal scrollable row of category cards:
```
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
│  [icon] │  │  [icon] │  │  [icon] │  │  [icon] │
│         │  │         │  │         │  │         │
│Clothing │  │  Shoes  │  │  Home   │  │  Kids   │
└─────────┘  └─────────┘  └─────────┘  └─────────┘
```

Each card:
- White background with subtle shadow (2px)
- Rounded corners: 12px
- Size: 72x80 (width x height)
- Lucide icon centered, size 28, color: primary red
- Label below icon: 11px, medium weight, dark text
- Tap → navigate to category browse screen
- Horizontal padding between cards: 12px
- Container padding: 16px horizontal from screen edges

**Icons for each category:**
```dart
'Clothing': LucideIcons.shirt,
'Shoes': LucideIcons.footprints,
'Blankets': LucideIcons.bedDouble,
'Furniture': LucideIcons.sofa,
'Carpets': LucideIcons.frame,
'Electronics': LucideIcons.smartphone,
'Bags': LucideIcons.shoppingBag,
'Beauty': LucideIcons.sparkles,
'Jewellery': LucideIcons.gem,
'Kids': LucideIcons.baby,
'Home & Living': LucideIcons.lamp,
'Sports': LucideIcons.dumbbell,
'Kitchen': LucideIcons.chefHat,
```

---

## STEP 6: Category Filter Chips — Emojis to Icons

Find category filter chips on the browse/products screen. They likely have emoji characters before the text labels.

**Current:** `🧥 Clothing` `👟 Shoes` `🛏 Blankets`

**New:** Lucide icon + text, no emoji:

```dart
Chip(
  avatar: Icon(LucideIcons.shirt, size: 16),
  label: Text('Clothing'),
  // active: filled red background, white text, white icon
  // inactive: white background, red border, red text, red icon
)
```

Search for filter chips across ALL screens (home, shop, products, category browse) and replace any emoji-prefixed chips with Lucide icon versions.

---

## STEP 7: Update Scaffold Backgrounds

Change all screen backgrounds from the current light green tint to warm cream:

```dart
Scaffold(
  backgroundColor: Color(0xFFFAF8F5), // warm cream, was light green
  // ...
)
```

Search for `backgroundColor` across all Scaffold widgets and update. Also check for any Container or background color that uses the old green tint values.

---

## STEP 8: Update All Buttons

Find all button widgets and update colors:

**Primary buttons (Sign In, Buy Now, Checkout, Confirm):**
- Background: red gradient or solid `#D42B2B`
- Text: white, bold
- Border radius: 12px

**Secondary buttons (Add to Cart, Follow, outlined actions):**
- Background: white
- Border: 1.5px solid `#D42B2B`
- Text: `#D42B2B`, bold

**Toggle switches:**
- Active: red (#D42B2B) instead of green
- Inactive: grey

**Search the codebase for any remaining green color values** in buttons, toggles, badges, indicators, and replace with the red equivalent.

---

## STEP 9: Update Store Cards in "Top Stores" / "Shop Our Stores"

If a "Top Stores" section exists, update it to match the design reference:

**Layout: 2-column grid of store cards:**
Each card:
- White background, 12px rounded corners, subtle shadow
- Store name in bold, centered
- Small red map pin icon + "China Mall" or "Oriental Plaza" text below name in grey
- Clean, minimal — no product images in the store card, just name and location
- Tap → opens store detail screen

---

## STEP 10: Global Cleanup Sweep

After all changes, do a final sweep:

1. **Search for ANY remaining emoji characters:**
```bash
grep -rPn '[\x{1F300}-\x{1F9FF}]' lib/ --include="*.dart"
grep -rPn '[\x{2600}-\x{27BF}]' lib/ --include="*.dart"
```
If ANY results come back, replace them with Lucide icons.

2. **Search for any remaining green hex values:**
```bash
grep -rn "1D6B46\|133523\|1d6b46\|E8F5E9\|e8f5e9" lib/ --include="*.dart"
```
Replace any found with the red equivalents.

3. **Verify icon import is present** in every file that uses `LucideIcons`:
```dart
import 'package:lucide_icons/lucide_icons.dart';
```

---

## STEP 11: Verify

```bash
flutter analyze          # Zero issues
flutter build apk --debug   # Builds successfully
```

Visually verify:
- App background is warm cream, NOT green
- Bottom nav bar is dark charcoal-red with 5 tabs, NOT dark green with 4 tabs
- All category icons are Lucide line icons, NOT emojis
- Cart is grouped by vendor with store headers
- All buttons, toggles, and badges use red (except success states which are green)
- No emoji characters visible anywhere in the app

```bash
git add .
git commit -m "Session 1: UI overhaul — green to red theme, emoji to Lucide icons, 5-tab nav, vendor-grouped cart"
git push origin feature/ui-overhaul-session-1
```

---

## WHAT THIS SESSION DOES
- Installs Lucide Icons package
- Replaces ALL emojis with Lucide vector icons
- Converts entire color scheme from green to red/cream/gold
- Updates bottom nav from 4 tabs to 5 tabs with new icons and labels
- Groups cart items by vendor (SHEIN-style)
- Updates category display from emoji scroll to icon cards
- Updates filter chips from emoji-prefixed to icon-prefixed
- Updates all backgrounds, buttons, toggles, badges

## WHAT THIS SESSION DOES NOT DO
- No new screens (Trends page, Store Detail — that's Session 2)
- No new features (referral, gift, review prompts — that's Session 4)
- No courier changes (that's Session 3)
- No backend/database changes
- No Supabase schema changes
