// Stripe webhook handler (Edge Function)
// Configure the webhook endpoint URL in your Stripe dashboard and set
// STRIPE_WEBHOOK_SECRET in function's environment variables.

import Stripe from 'stripe';

export default async (req: Request) => {
  const secret = process.env.STRIPE_WEBHOOK_SECRET || '';
  const payload = await req.text();
  const sig = req.headers.get('stripe-signature') || '';

  const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', { apiVersion: '2020-08-27' });

  try {
    const event = stripe.webhooks.constructEvent(payload, sig, secret);
    // Handle checkout.session.completed
    if (event.type === 'checkout.session.completed') {
      const session = event.data.object as Stripe.Checkout.Session;
      const orderRef = session.metadata?.order_id || null;
      // TODO: update `orders` table in Postgres to mark as paid using service role key
    }
    return new Response(JSON.stringify({ received: true }), { status: 200, headers: { 'Content-Type': 'application/json' } });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: 'webhook_error', detail: err.message }), { status: 400, headers: { 'Content-Type': 'application/json' } });
  }
};
