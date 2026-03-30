Notifications Edge Functions

This folder contains minimal Edge Function stubs used by the Flutter app when calling notification-related endpoints via Supabase Functions.

Functions:
- `notifications_register_device` — upserts device tokens into `notification_devices` table. Accepts `token`, `platform`, `device_name`, `profile_id` (optional).
- `notifications_unregister_device` — deletes device token record. Accepts `token`.
- `notifications_mark_read` — marks all notifications read for `profile_id`. Accepts `profile_id`.
- `notifications_unread_count` — returns unread count for `profile_id`. Accepts `profile_id`.

Environment:
- `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` must be set when deploying.

Deploy (Supabase CLI):

```bash
supabase functions deploy notifications_register_device --project-ref <ref>
supabase functions deploy notifications_unregister_device --project-ref <ref>
supabase functions deploy notifications_mark_read --project-ref <ref>
supabase functions deploy notifications_unread_count --project-ref <ref>
```

Notes:
- These are simple stubs. For production you should verify the caller's JWT or extract `profile_id` from the Authorization header and validate permissions.
- Create `notification_devices` and `notifications` tables in your `schema.sql` before using these functions.
