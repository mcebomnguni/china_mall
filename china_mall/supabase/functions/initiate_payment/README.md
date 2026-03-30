initiate_payment Edge Function

Purpose
- Create a payment session with your payment provider and return a redirect URL
  that the client opens for card/payment completion.

Usage
1. Customize `index.ts` to integrate with your payment gateway (Stripe, PayFast, etc.).
2. Optionally verify the `order_id` and `amount_cents` against your Supabase Postgres
   database using a service role key (DO NOT embed the service key in client apps).
3. Deploy:

```bash
supabase functions deploy initiate_payment --project-ref <your-project-ref>
```

4. In the client use `SupabaseService.client.functions.invoke('initiate_payment', { body })`
   (we already call this from the app in `payment_service.dart`).

Security notes
- Use server-side secrets (service role key) only in Edge Functions or server-side code.
- Validate order ownership and amount before creating a payment session.
