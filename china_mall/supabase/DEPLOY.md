# Deploying Supabase schema and Edge Functions

Quick steps to deploy the schema and functions for this project.

Prerequisites
- `psql` (Postgres client) on PATH
- `supabase` CLI installed and authenticated (`supabase login`)
- Your Supabase project created and project ref available

Required environment variables (local / CI):
- `SUPABASE_DB_URL` — Postgres connection string for the Supabase database
- `SUPABASE_PROJECT_REF` — your Supabase project ref

Recommended function secrets (configure in Supabase dashboard or via CLI):
- `SUPABASE_SERVICE_ROLE_KEY` — service role key (useful for server-side functions)
- `SUPABASE_URL` — your Supabase URL (https://<ref>.supabase.co)
- `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` — for payment function/webhook

Deploy schema + all functions (Unix / WSL / Git Bash):
```bash
export SUPABASE_DB_URL="postgres://user:pass@db.host:5432/postgres"
export SUPABASE_PROJECT_REF="your-project-ref"
export SUPABASE_SERVICE_ROLE_KEY="service-role-key" # optional for schema operations
cd supabase
./deploy.sh
```

Deploy schema + all functions (PowerShell):
```powershell
$env:SUPABASE_DB_URL='postgres://user:pass@db.host:5432/postgres'
$env:SUPABASE_PROJECT_REF='your-project-ref'
$env:SUPABASE_SERVICE_ROLE_KEY='service-role-key' # optional for schema operations
Set-Location supabase
.\deploy.ps1
```

Deploy a single function:
```bash
# Unix
SUPABASE_FUNCTIONS="auth_phone_reset" ./deploy.sh

# PowerShell
$env:SUPABASE_FUNCTIONS='auth_phone_reset'
.\deploy.ps1
```

Setting function environment variables
- In the Supabase Dashboard: go to Functions → (your function) → Settings → Environment variables and add keys such as `SUPABASE_SERVICE_ROLE_KEY`, `STRIPE_SECRET_KEY`, etc.
- Or use the Supabase CLI (if supported in your version) to set secrets for Edge Functions. If your CLI supports `supabase secrets` or `supabase functions env`, consult `supabase --help` for exact commands.

Smoke test an Edge Function locally (if you have the Supabase CLI):
```bash
# from repository root
supabase functions serve auth_phone_reset
# then invoke via HTTP or the CLI
supabase functions invoke auth_phone_reset --project-ref "$SUPABASE_PROJECT_REF" --body '{"phone_number":"+15551234567","reset_token":"TOKEN","new_password":"newpass123"}'
```

Post-deploy
- Verify tables and RLS policies in the Supabase SQL editor and Auth settings
- Create the `product-images` bucket in Storage and set RLS/storage policies
- Add service role and Stripe secrets to project settings
- Run the Flutter app against the Supabase project and test major flows (auth, checkout, delivery, admin)

Troubleshooting
- If `psql` is not available, copy `supabase/schema.sql` and run it in the Supabase SQL editor
- If `supabase` CLI is not available, deploy functions using the Dashboard (Functions → New function → Upload)

Contact
- If you want, I can deploy locally-running function mocks for quick verification or prepare CI scripts for automated deployments.