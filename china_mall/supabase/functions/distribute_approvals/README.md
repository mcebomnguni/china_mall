distribute_approvals Edge Function

Purpose
- Approve or distribute pending store approval requests in batches and write entries to `audit_logs`.

Usage
1. Deploy with the Supabase CLI and ensure the function has the `SUPABASE_SERVICE_ROLE_KEY` env var set.

```bash
supabase functions deploy distribute_approvals --project-ref <your-project-ref>
```

2. Call from client (example in `AdminService.distributeApprovals`) or run from server.

Security
- This function uses the Supabase service_role key to update protected tables — do NOT expose the service key to clients. Only deploy as an Edge Function.
