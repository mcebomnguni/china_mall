# Supabase Test User Seeder

Purpose: Bulk-create test accounts for China Stall Market Place Supabase project.

## Setup
1. Add a `.env` file at the repo root with:
   ```
   SUPABASE_URL=https://ipsdpswdubdczxfbvtty.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
   ```
2. Ensure the `profiles` table exists (see `supabase/schema.sql`).

## Usage

### Dry run (preview only)
```bash
dart run scripts/create_test_users.dart --dry-run
```

### Real creation
```bash
dart run scripts/create_test_users.dart
```

## What it creates
- 100 buyers
- 20 vendors
- 10 couriers
- 2 admins

Each user gets:
- Email: `{role}.test.{index}@chinamall.local`
- Password: `Test1234!`
- `profiles` row with `full_name`, `role`, `phone`

## Output
- Report: created / skipped (already exists) / failed
- Summary CSV: `scripts/seed_report.csv`

## Security
- Never commit `.env` with service role key.
- Script is admin-only; do not ship in the Flutter app.
