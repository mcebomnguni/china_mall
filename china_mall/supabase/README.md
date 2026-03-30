Supabase migration notes for China Mall

Overview
- This folder contains a proposed Supabase schema and mapping from the existing Django endpoints to Postgres tables, storage and Edge Functions.

Files
- `schema.sql`: CREATE TABLE statements, indexes and RLS placeholders.
 - `functions/`: example Supabase Edge Functions (TypeScript) — e.g. `initiate_payment`.

High-level mapping
- Auth: use Supabase Auth + a `profiles` table linked to `auth.users` for user metadata.
- Storage: use Supabase Storage for product/store images and avatars.
- Core tables: `stores`, `products`, `categories`, `cart_items`, `carts`, `orders`, `order_items`, `vouchers`, `devices`, `reviews`, `disputes`.
- Complex endpoints (reports, distribution, delivery-fee, voucher validation, payment processing): implement as Edge Functions or SQL functions + Postgres views.

Next steps
1. Create a Supabase project and enable Postgres extensions (pgcrypto if needed).
2. Run `schema.sql` in the Supabase SQL editor or via psql.
3. Configure Storage buckets and CORS for Edge Functions.
4. Add `supabase_flutter` to the Flutter project and replace calls in `lib/core/services/*` with Supabase SDK or call Edge Functions.
5. Implement RLS policies for `profiles`, `orders`, `cart_items` and other per-user data.

Credentials / secrets
- When implementing in the app, store `SUPABASE_URL` and `SUPABASE_ANON_KEY` in a secure config (use CI secrets or env files during development). Use the service key only on server-side functions, not in the client.

Notes
- The SQL is intentionally conservative: handle relationships and common indexes but not every implementation detail. Consider adding materialized views for admin charts and triggers for denormalized counters if needed.

Local dev: running the app with Supabase

- Set the environment variables when running Flutter. Example (Windows PowerShell):

```powershell
$env:SUPABASE_URL='https://your-project.supabase.co'
$env:SUPABASE_ANON_KEY='your-anon-key'
flutter run
```

- Or pass as Dart defines:

```powershell
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

- This project also supports a publishable key define. If your Supabase project gives you a publishable client key instead of an anon key, use `SUPABASE_PUBLISHABLE_KEY`.

```powershell
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

- For local development on this repo, use the ignored file `env/flutter/supabase.local.json`:

```powershell
flutter run --dart-define-from-file=env/flutter/supabase.local.json
```

Security note: never commit your anon/service keys to the repo. Use CI secrets for production builds.

Deploying schema & functions
- The `supabase/deploy.ps1` (Windows PowerShell) and `supabase/deploy.sh` (Unix/WSL) scripts help apply `schema.sql` and deploy Edge Functions.
- Prerequisites:
	- `psql` (Postgres client) installed and on PATH, or use the Supabase SQL editor.
	- `supabase` CLI installed and authenticated (`supabase login`).
	- Environment variables: `SUPABASE_DB_URL` and `SUPABASE_PROJECT_REF`.

Examples (PowerShell):

```powershell
$env:SUPABASE_DB_URL='postgres://user:pass@db.supabase.co:5432/postgres'
$env:SUPABASE_PROJECT_REF='your-project-ref'
.\supabase\deploy.ps1
```

Examples (bash / WSL):

```bash
export SUPABASE_DB_URL='postgres://user:pass@db.supabase.co:5432/postgres'
export SUPABASE_PROJECT_REF='your-project-ref'
./supabase/deploy.sh
```

