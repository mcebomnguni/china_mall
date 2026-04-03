# China Stall — Spec Compliance Audit
Generated: 2026-04-02

## Summary
- Total spec requirements (individual items): **83**
- Fully implemented: **60**
- Partially implemented: **6**
- Not started: **17**
- Coverage: **~76%**

### Section-Level Summary
| Part | Sections | Done | Partial | Not Started |
|------|----------|------|---------|-------------|
| Part 1: Customer App | C1–C10 | 2 | 6 | 2 |
| Part 2: Store Portal | S1–S7 | 6 | 1 | 0 |
| Part 3: Courier | CR1–CR4 | 2 | 2 | 0 |
| Part 4: Admin Dashboard | A1–A7 | 7 | 0 | 0 |
| **Total** | **22 sections** | **17** | **9** | **2** |

---

## PART 1: CUSTOMER APP

### C1. Main Navigation (5 tabs: Home, Shop, Trends, Cart, Profile)
- **Status: PARTIAL**
- Notes: Has 4 tabs, not 5. Labels are **Main / Feed / Activity / You** (buyer mode). No dedicated "Trends" or "Cart" tab — cart is accessible from the Feed screen. The bottom nav is a floating dark pill-shaped bar (green, not black). Role-based tabs change for vendor (Home/Stock/Orders/Profile) and courier (Home/Pickups/Deliveries/Profile).

### C2. Home Screen
- **Status: PARTIAL**
- Targeted ads: **no** — no personalized/targeted ad display on home
- Promotions/deals section: **yes** — promotional carousel banners with page indicator dots
- Previous searches: **no** — no search history displayed
- Personalised recommendations: **no** — has Featured & Trending sections but not personalized per-user
- Search bar: **yes** — search screen accessible from home

### C3. Shop / Store Browsing
- **Status: DONE**
- Store list with categories: **yes** — `StoresScreen` with store directory
- Store detail page: **yes** — `StoreDetailScreen` with products, reviews, category filters
- Product detail page: **yes** — `ProductDetailScreen` with full detail
  - Multiple images: **yes** — sorted by ordinal field
  - Size options: **yes** — `sizes` jsonb field
  - Dimensions: **yes** — `dimensions` jsonb field
  - Colour options: **yes** — `colours` jsonb field
  - Fabric/material: **yes** — `fabric_material` text field
  - Product ID: **yes** — `product_ref_id` field
  - Add to cart: **yes** — cart integration
  - Customer reviews: **yes** — `WriteReviewSheet` + review display

### C4. Trends
- **Status: NOT STARTED**
- Top 100 products: **no** — only a "Trending" carousel section on the home screen (not a dedicated page)
- Top 100 shops: **no**
- Ranking indicators: **no**
- Notes: No dedicated Trends screen exists. The spec envisions a SHEIN-style trends page with hashtag chips and ranking lists. Currently, trending products are shown as a small horizontal scroll on the home screen only.

### C5. Cart & Checkout
- **Status: PARTIAL**
- Cart grouped by store: **no** — flat list with store name per item, not grouped by vendor (SHEIN-style)
- Quantity adjustment: **yes** — increment/decrement controls
- Delivery fee with R750 threshold: **partial** — `AppConfig.freeDeliveryThreshold = 750.0` exists but backend `delivery_calculator.dart` uses R500. Inconsistent.
- Checkout flow:
  - Address selection: **yes** — delivery address, city, province, postal code fields
  - Send to someone else: **no** — single recipient only
  - Gift option: **no** — no gift messaging or wrapping
  - Ozow payment: **no** — uses **Yoco** payment gateway instead of Ozow
  - Biometric/PIN confirmation: **yes** — both biometric and 4-digit PIN confirmation before payment
  - Order confirmation with batch window: **no** — no batch window messaging (9am/3pm cutoffs not shown to customer)

### C6. Customer Reviews
- **Status: PARTIAL**
- Post-delivery review: **no** — `WriteReviewSheet` exists but no automatic post-delivery review prompt
- Star rating + text: **yes** — rating (1–5 stars) + text body in `WriteReviewSheet`
- Visible on product pages: **yes** — reviews displayed on product detail screen

### C7. Delivery Verification Code System
- **Status: DONE**
- Pickup code flow: **yes** — courier enters code at store pickup
- Delivery code flow: **yes** — courier enters code at customer delivery
- 6-digit code entry UI: **yes** — `VerificationCodeInput` widget with 6 separate monospace fields, auto-advance, shake animation on error

### C8. Security & Authentication
- **Status: PARTIAL**
- Email/password registration: **yes** — `RegisterScreen` + `LoginScreen`
- Biometric/PIN setup: **yes** — `SecuritySetupScreen` + `BiometricService`
- 30-day full login cycle: **no** — has 30-minute **inactivity** timeout only (`SessionManager._timeoutMinutes = 30`), not a 30-day periodic re-authentication
- Purchase confirmation: **yes** — biometric/PIN required before payment
- Financial data protection: **partial** — device verification with 6-digit codes exists, but no explicit financial data encryption layer documented

### C9. Referral Program
- **Status: NOT STARTED**
- Share link generation: **no**
- 10% discount on referral: **no**
- App store redirect: **no**
- Notes: Zero references to "referral" found anywhere in the codebase. No `referrals` database table exists.

### C10. Address Book
- **Status: PARTIAL**
- Multiple addresses: **yes** — `SavedAddressesScreen` with address CRUD
- Send to someone else: **no** — no recipient management
- Named addresses: **yes** — labels like "home", "work", "partner" with custom icons

---

## PART 2: STORE PORTAL

### S1. Store Onboarding
- **Status: DONE**
- Formal path (COR, proof of account, 3 people): **yes** — `VendorOnboardingFormalScreen` collects COR, proof of account, authorized representatives with IDs
- Informal path (ID, permit, affidavit, etc.): **yes** — `VendorOnboardingInformalScreen` collects ID document, trading permit, affidavit, proof of account, contact info, workers
- Admin review flow: **yes** — `VendorDetailScreen` in admin with approve/reject/request-more-info actions; `vendor_applications` table tracks status

### S2. Product Management
- **Status: DONE**
- Add new product (all fields from spec): **yes** — `AddProductScreen` with name, description, price, images, sizes, colours, dimensions, fabric/material, category, stock
- Edit existing product: **yes** — `EditProductScreen` with same fields
- Promotions/sales: **yes** — `sale_price`, `is_on_sale`, `discount_percent` fields; product model supports sale pricing

### S3. Ads & Targeting
- **Status: DONE**
- Paid ad placement: **yes** — `VendorAdsScreen` with audience targeting (100–5000 customers), R10/100 customer pricing, campaign management (active/paused/completed). Note: "Payment integration coming soon" label in UI.

### S4. Store Analytics
- **Status: DONE**
- Sales history: **yes** — sales by period with revenue in `VendorAnalyticsScreen`
- Product performance: **yes** — ranked by revenue and units sold with progress bars
- Time period filters: **yes** — daily, weekly, monthly toggle (R250/month premium subscription required)

### S5. Order Fulfillment
- **Status: PARTIAL**
- Receive orders: **yes** — `VendorOrdersScreen` shows incoming orders
- Confirm and package: **yes** — `VendorOrderDetailScreen` with order status updates
- Item checklist: **partial** — courier has full `ItemChecklist` widget; vendor order detail shows items but lacks a formal pack-and-check checklist UI
- Handoff code to courier: **yes** — `delivery_handoffs` table with `store_packed` → `courier_picked_up` stages and 6-digit codes

### S6. Inventory Management
- **Status: DONE**
- Stock counter: **yes** — `stock_quantity` field with update via `updateProductStock()` API
- Low stock notifications (< 3): **yes** — DB trigger `handle_stock_change()` sends notification when stock < 3
- Auto-hide at 0 stock: **yes** — DB trigger sets `is_active = false` when stock = 0, re-activates when restocked

### S7. Categories & Filtering
- **Status: DONE**
- Store-level categories: **yes** — `StoreDetailScreen` has dynamic category filter chips generated from the store's actual products (comment: "S7 — category filter")

---

## PART 3: COURIER

### CR1. Role Switching
- **Status: DONE**
- Toggle in profile: **yes** — `CourierHomeScreen` has a "Customer" button (`Icons.swap_horiz`) that routes to buyer home
- Different interface per role: **yes** — `MainShell` shows different bottom nav tabs per role (buyer: Main/Feed/Activity/You, courier: Home/Pickups/Deliveries/Profile)

### CR2. Batch Pickup Schedule
- **Status: DONE**
- 9am and 3pm batches: **yes** — `BatchWindow` enum with `morning` (9:00 AM) and `afternoon` (3:00 PM) including cutoff times
- Assigned pickups view: **yes** — `PickupAssignmentsScreen` with list of assigned pickups, `BatchStatusCard` widget

### CR3. Pickup Flow
- **Status: PARTIAL**
- Item checklist: **yes** — `ItemChecklist` widget for verifying items at pickup
- Missing item handling: **yes** — `MissingItemSheet` for reporting missing/damaged items
- Handoff code entry: **yes** — `VerificationCodeInput` for store pickup code verification
- Customer notification on pickup: **partial** — `NotificationService` exists and DB functions send notifications, but no confirmed push notification integration for pickup events specifically

### CR4. Delivery Flow
- **Status: PARTIAL**
- Navigation to address: **partial** — delivery address is displayed but no integrated map navigation (no Google Maps/Waze intent launch)
- Customer item verification: **yes** — `ItemChecklist` on `DeliveryHandoffScreen`
- Delivery code entry: **yes** — `VerificationCodeInput` for customer delivery code
- Status update to "Delivered": **yes** — `completeDelivery()` API call updates status

---

## PART 4: ADMIN DASHBOARD (Web)

The admin dashboard is a **separate Flutter Web application** at `china_mall/admin/` with 23 Dart files, Supabase backend, and GoRouter navigation.

### A1. Store Approval
- **Status: DONE**
- **yes** — `VendorListScreen` + `VendorDetailScreen` with full application review, document viewing, approve/reject/request-more-info actions, status tracking. Supports both formal and informal applications.

### A2. Product Approval
- **Status: DONE**
- **yes** — `ProductListScreen` + `ProductDetailScreen` with thumbnail preview, category display, approve/reject/needs-changes actions. Status filters: pending, needs_changes, active, rejected.

### A3. Analytics
- **Status: DONE**
- **yes** — `AnalyticsScreen` with 4 tabs: Revenue timeline (hourly/daily/monthly), Top Products (ranked), Store Performance (metrics), Courier Performance (deliveries, ratings). Period filters: 7d/30d/90d.

### A4. Payment Management
- **Status: DONE**
- **yes** — `PaymentsScreen` with 3 tabs: Transactions (status filter), Payouts (process/track), Commission Schedules (frequency, %, active toggle). 4 stat cards: collected, pending, payouts, commission.

### A5. Help Desk
- **Status: DONE**
- **yes** — `TicketListScreen` + `TicketDetailScreen` with full helpdesk: ticket creation, assignment, status updates, messaging thread, internal notes, priority/category filters, auto-generated ticket numbers (TK-XXXXXX).

### A6. Inventory Oversight
- **Status: DONE**
- **yes** — `InventoryScreen` with 2 tabs: Overview (store inventory matrix) and Low Stock Alerts (threshold=3, restock notification). Stats: total SKUs, units, low stock count.

### A7. Order Monitoring (bonus — not in original spec numbering)
- **Status: DONE**
- **yes** — `OrdersScreen` with 11-column table, 13 status filters, handoff trail dialog showing 5-stage delivery chain with confirmation codes and timestamps.

---

## DATABASE

### Tables (from Supabase migrations)

| Table | Exists | Notes |
|-------|--------|-------|
| profiles (users) | **yes** | Roles: buyer, vendor, courier, admin, staff. Includes PIN hash, security method, account status, suspension/deletion fields |
| stores | **yes** | Owner, name, description, cover_url, slug, province/city/area, is_active |
| store_documents | **partial** | No separate table — document URLs stored in `vendor_applications` (cor_url, id_document_url, permit_url, affidavit_url, etc.) |
| store_workers | **partial** | Workers stored as jsonb array in `vendor_applications.workers`, not a separate table |
| products | **yes** | Full spec fields: name, price, stock_quantity, sizes/colours/dimensions (jsonb), fabric_material, sale_price, discount_percent, product_ref_id, status (pending/active/rejected/needs_changes) |
| product_images | **yes** | URL + ordinal for ordering |
| orders | **yes** | Full status enum (12 statuses), shipping_address jsonb, payment_meta, handoff_code |
| order_items | **yes** | Product, quantity, unit_price |
| deliveries | **yes** | Driver, pickup/delivery lat/lng, weight, status |
| reviews | **yes** | Product reviews with rating (1–5) + body text |
| addresses | **yes** | Profile-linked with label, full_address, lat/lng, is_default |
| referrals | **no** | Table does not exist |
| payouts | **yes** | Entity type (store/courier), period, gross/commission/net amounts, status, reference |
| support_tickets | **yes** | Auto-numbered (TK-XXXXXX), category, priority, status, assignment |
| ads (ad_campaigns) | **yes** | Store campaigns with target customers, budget, reach tracking |

### Additional Tables (not in spec but implemented)
| Table | Purpose |
|-------|---------|
| carts / cart_items | Server-side cart persistence |
| payments | Payment records with Ozow/Yoco references |
| payout_schedules | Commission configuration per store/courier |
| refunds | Refund requests with approval workflow |
| financial_entries | Double-entry bookkeeping for super admin |
| delivery_handoffs | 4-stage handoff chain with confirmation codes |
| delivery_tracking | Status history for deliveries |
| driver_locations | Real-time GPS tracking |
| drivers | Driver profile with vehicle info |
| courier_documents | Courier ID/license documents |
| courier_bank_details | Courier banking for payouts |
| vendor_applications | Full onboarding application data |
| categories | Hierarchical product categories |
| vouchers | Discount codes (not connected to referrals) |
| disputes | Order dispute records |
| audit_logs | Admin action audit trail |
| notifications | In-app notification storage |
| notification_devices | FCM/APNs push token registry |
| user_devices | Trusted device management |
| device_verification_codes | 6-digit device verification |
| phone_otps / email_otps | OTP for auth recovery |
| phone_resets / email_resets | Password reset tokens |
| analytics_subscriptions | Vendor analytics premium access |

---

## UI DESIGN COMPLIANCE

### Visual Design Language

| Requirement | Status | Notes |
|-------------|--------|-------|
| Red and white primary colour scheme | **no** | Green primary (#1D6B46) with white — no red anywhere in theme |
| Asian/Chinese aesthetic touches (dragon motifs, lattice patterns) | **no** | No cultural design elements. "Dragon Fashion" appears only as a mock store name |
| Middle Eastern geometric pattern influences | **no** | No geometric patterns found |
| Floating dark pill-shaped bottom nav bar | **yes** | Dark green pill (#133523) with 28px border radius, floating above content |
| 5-tab navigation (Home, Shop, Trends, Cart, Me) | **no** | 4 tabs: Main, Feed, Activity, You — missing Trends and Cart as dedicated tabs |
| SHEIN-style trends page with hashtag chips | **no** | No trends page exists |
| Bash-style photo category grid (2-column with image overlays) | **no** | Categories shown as horizontal scroll with emoji icons, not a photo grid |
| SHEIN-style vendor-grouped cart | **no** | Flat item list with store name label per item |
| Bash-style clean profile with icon+chevron rows | **yes** | OsCard sections with icon + label + right chevron, grouped by category |
| Promotional carousel banners on home | **yes** | Carousel with smooth page indicator dots |
| "Shop our stores" vendor/brand grid | **partial** | "Top Stores" section exists but as vertical list cards, not a grid layout |
| No emojis used as icons (vector icons only) | **no** | Emoji characters used for category icons: 👗👘👟💍⚽👜🛏🛋🪞🍳🧸📱. Also 🧪 for test mode badge |
| Product cards with real photography (or image URLs) | **yes** | Network images from Supabase storage with CachedNetworkImage |
| Verification code input (6-digit boxes, monospace) | **yes** | 6 separate 48px fields, monospace font, auto-advance, shake animation |

---

## PRIORITY GAPS

Top 10 most important missing features, ranked by business impact:

### 1. **Payment Gateway Mismatch (Ozow → Yoco)**
Spec requires Ozow (popular SA EFT payment). Current implementation uses Yoco (card-only). Ozow supports instant EFT which is critical for the target market demographic who may not have credit cards. **Business impact: HIGH — blocks revenue from bank-transfer customers.**

### 2. **Referral Program (C9) — Entirely Missing**
No referral system exists. Share links, discount codes, and viral growth mechanics are completely absent. No `referrals` table in database. **Business impact: HIGH — referrals are the primary organic growth channel for marketplace apps.**

### 3. **Trends Page (C4) — Not Started**
No dedicated trends screen with Top 100 products/shops. This is a key discovery and engagement feature (SHEIN's most-visited page). **Business impact: HIGH — drives browsing time, product discovery, and impulse purchases.**

### 4. **Cart Not Grouped by Store (C5)**
Items display as a flat list instead of grouped by vendor. This is critical for a multi-vendor marketplace — customers need to see per-store subtotals and delivery implications. **Business impact: MEDIUM-HIGH — confuses multi-store checkout experience.**

### 5. **30-Day Full Login Cycle (C8) — Missing**
Only has 30-minute inactivity timeout. Spec requires periodic full re-authentication every 30 days for security compliance. **Business impact: MEDIUM-HIGH — security/compliance risk for financial transactions.**

### 6. **Post-Delivery Review Prompt (C6)**
Review widget exists but no automatic prompt after delivery. Reviews drive trust and conversion. Without a prompt, review volume will be near zero. **Business impact: MEDIUM — no reviews = no social proof = lower conversion.**

### 7. **Gift & Send-to-Someone-Else (C5, C10)**
No ability to send orders to another person or add gift messages. This limits use cases like sending items to family/friends. **Business impact: MEDIUM — missed revenue from gift purchases.**

### 8. **Red/White Color Scheme & Cultural Design (UI)**
Spec calls for red/white theme with Asian/Chinese aesthetic touches. Current theme is entirely green. This is a brand identity issue — "China Mall/Stall" evokes a specific cultural market experience. **Business impact: MEDIUM — brand misalignment with target market expectations.**

### 9. **Delivery Fee Threshold Inconsistency (C5)**
Config says R750, backend calculator says R500. Inconsistent messaging to customers about free delivery. **Business impact: MEDIUM — customer confusion, potential trust issues.**

### 10. **Batch Window Display for Customers (C5)**
Customers are not told about the 9am/3pm batch pickup schedule during checkout. They should see estimated delivery windows. **Business impact: MEDIUM — customers don't know when to expect delivery.**

---

## QUICK WINS (< 1 hour each)

### 1. Fix Delivery Fee Threshold Consistency
Align `delivery_calculator.dart` R500 threshold to match `AppConfig.freeDeliveryThreshold = 750.0`. One-line change plus update the checkout UI copy.

### 2. Add Post-Delivery Review Prompt
In `OrderDetailScreen`, when `order.status == 'delivered'`, show a banner/button that opens the existing `WriteReviewSheet`. The widget already exists — just needs to be triggered.

### 3. Replace Emoji Category Icons with Vector Icons
Replace the 13 emoji characters in `app_constants.dart` with Material/Cupertino icon names. Map: clothing → `Icons.checkroom`, shoes → `Icons.sports_gymnastics`, electronics → `Icons.devices`, etc.

### 4. Group Cart Items by Store
In `CartScreen`, sort items by `storeId` and insert store header dividers between groups. The `store_name` is already on each `CartItem` — just needs a `groupBy()` and section headers.

### 5. Add Batch Window Info to Checkout
On `CheckoutScreen`, display a text line like "Orders placed before 9:00 AM ship in the morning batch. Orders before 3:00 PM ship in the afternoon batch." The `BatchWindow` model already exists in the courier feature.

---

## ARCHITECTURE NOTES

### Tech Stack
- **Mobile App**: Flutter (Dart) with Provider state management
- **Admin Dashboard**: Flutter Web (separate app at `admin/`)
- **Backend**: Supabase (PostgreSQL + Edge Functions + Auth + Storage)
- **Payment**: Yoco (spec says Ozow)
- **Routing**: GoRouter with role-based auth guards
- **State**: ChangeNotifier providers (AuthProvider, CartProvider, ProductsProvider, OrdersProvider, SupportProvider)

### Code Quality
- **128 Dart files** in the mobile app, **23** in admin dashboard
- Clean separation: screens / providers / models / services / widgets
- Comprehensive RLS policies on all tables
- 24 Edge Functions for serverless logic
- 40+ database functions for admin operations
- Proper indexes on frequently queried columns
- Audit logging for admin actions

### What's Working Well
- Store onboarding (formal + informal paths) is fully spec-compliant
- Courier batch system with verification codes is well-implemented
- Admin dashboard exceeds spec with financials, admin management, and order handoff trails
- Database schema is comprehensive with proper RLS, triggers, and functions
- Inventory management with auto-hide at 0 stock and low-stock notifications is production-ready
