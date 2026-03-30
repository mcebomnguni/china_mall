#!/usr/bin/env bash
# Deploy Supabase schema and functions (Unix / WSL / Git Bash)

set -euo pipefail

if [ -z "${SUPABASE_DB_URL:-}" ]; then
  echo "SUPABASE_DB_URL is not set. Set it to your Supabase Postgres connection string." >&2
  exit 1
fi
if [ -z "${SUPABASE_PROJECT_REF:-}" ]; then
  echo "SUPABASE_PROJECT_REF is not set. Set it to your Supabase project ref." >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEMA="$ROOT_DIR/schema.sql"

if ! command -v psql >/dev/null 2>&1; then
  echo "psql not found in PATH. Install Postgres client or run the SQL manually in Supabase SQL editor." >&2
else
  echo "Applying schema.sql to SUPABASE_DB_URL..."
  psql "$SUPABASE_DB_URL" -f "$SCHEMA"
fi

if ! command -v supabase >/dev/null 2>&1; then
  echo "supabase CLI not found. Install from https://supabase.com/docs/guides/cli" >&2
  exit 1
fi

FUNC_DIR="$ROOT_DIR/functions"
if [ -z "${SUPABASE_FUNCTIONS:-}" ]; then
  for d in "$FUNC_DIR"/*/ ; do
    name=$(basename "$d")
    echo "Deploying function: $name"
    supabase functions deploy "$name" --project-ref "$SUPABASE_PROJECT_REF"
  done
else
  IFS=',' read -ra NAMES <<< "$SUPABASE_FUNCTIONS"
  for name in "${NAMES[@]}"; do
    name=$(echo "$name" | xargs)
    echo "Deploying function: $name"
    supabase functions deploy "$name" --project-ref "$SUPABASE_PROJECT_REF"
  done
fi

echo "Deploy complete. Verify in Supabase dashboard."
