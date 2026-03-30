// Supabase Edge Function: initiate_payment
// Deploy with: `supabase functions deploy initiate_payment`
// This is a minimal example that returns a mock redirect URL. Replace
// the payment provider integration with your real provider (Stripe, PayFast, etc.)

export default async (req: Request) => {
  try {
    const body = await req.json();
    const orderId = body.order_id;
    const amount = body.amount_cents;

    // TODO: validate order_id and amount against your Postgres DB using
    // the Supabase Admin key (set as an environment variable).

    // Example: create a payment session with your provider here.
    // This function returns a redirect_url which the client opens in a WebView.

    // Mock redirect URL (replace with real provider session URL)
    const redirectUrl = `https://payments.example/checkout?order=${orderId}&amount=${amount}`;

    const resBody = { redirect_url: redirectUrl, order_id: orderId, amount_cents: amount };
    return new Response(JSON.stringify(resBody), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: 'invalid_request', detail: String(err) }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }
};
