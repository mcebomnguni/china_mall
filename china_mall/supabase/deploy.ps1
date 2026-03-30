<#
Deploy Supabase schema and functions (PowerShell)

Prerequisites:
- Install `psql` (Postgres client) and ensure it's on PATH.
- Install Supabase CLI and authenticate: `supabase login`.

Environment variables required:
- SUPABASE_DB_URL (Postgres connection string)
- SUPABASE_PROJECT_REF (your Supabase project ref)

Optional:
- SUPABASE_FUNCTIONS (comma-separated function names to deploy). Defaults to all functions under `supabase/functions/`.

Usage:
PS> $env:SUPABASE_DB_URL='postgres://...'
PS> $env:SUPABASE_PROJECT_REF='your-project-ref'
PS> .\supabase\deploy.ps1
#>
param()

if (-not $env:SUPABASE_DB_URL) {
  Write-Error "SUPABASE_DB_URL is not set. Set it to your Supabase Postgres connection string."
  exit 1
}
if (-not $env:SUPABASE_PROJECT_REF) {
  Write-Error "SUPABASE_PROJECT_REF is not set. Set it to your Supabase project ref."
  exit 1
}

$here = Split-Path -Parent $MyInvocation.MyCommand.Definition
$schema = Join-Path $here 'schema.sql'

if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
  Write-Warning "psql not found in PATH. Install Postgres client or run the SQL manually in Supabase SQL editor."
} else {
  Write-Host "Applying schema.sql to SUPABASE_DB_URL..."
  psql $env:SUPABASE_DB_URL -f $schema
}

# Deploy Edge Functions
$funcDir = Join-Path $here 'functions'
if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
  Write-Warning "supabase CLI not found. Install from https://supabase.com/docs/guides/cli"
  return
}

$toDeploy = $env:SUPABASE_FUNCTIONS
if ([string]::IsNullOrEmpty($toDeploy)) {
  Get-ChildItem -Path $funcDir -Directory | ForEach-Object {
    $name = $_.Name
    Write-Host "Deploying function: $name"
    supabase functions deploy $name --project-ref $env:SUPABASE_PROJECT_REF
  }
} else {
  $names = $toDeploy.Split(',') | ForEach-Object { $_.Trim() }
  foreach ($name in $names) {
    Write-Host "Deploying function: $name"
    supabase functions deploy $name --project-ref $env:SUPABASE_PROJECT_REF
  }
}

Write-Host "Deploy complete. Verify in Supabase dashboard."
