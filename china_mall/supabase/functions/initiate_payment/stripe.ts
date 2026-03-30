// Example: Edge Function using Stripe to create a Checkout Session
// Requires environment variable STRIPE_SECRET_KEY set in the function's config.
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', { apiVersion: '2020-08-27' });

export default async (req: Request) => {
  try {
    const body = await req.json();
    const orderId = body.order_id;
    const amount = body.amount_cents; // in cents

    if (!orderId || !amount) {
      return new Response(JSON.stringify({ error: 'missing_fields' }), { status: 400 });
    }

    // Create a Stripe Checkout Session
    const host = req.headers.get('x-host') || 'https://your-app.example';
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      mode: 'payment',
      line_items: [
        {
          price_data: {
            currency: 'zar',
            product_data: { name: `Order ${orderId}` },
            unit_amount: amount,
          },
          quantity: 1,
        },
      ],
      success_url: `${host}/payment/success?session_id={CHECKOUT_SESSION_ID}&order=${orderId}`,
      cancel_url: `${host}/payment/cancel?order=${orderId}`,
    });

    return new Response(JSON.stringify({ redirect_url: session.url, session_id: session.id }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: 'stripe_error', detail: err.message }), { status: 500, headers: { 'Content-Type': 'application/json' } });
  }
}
