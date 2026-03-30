// Minimal Supabase Edge Function: delivery_quote
import { serve } from 'std/server'
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)
    const body = await req.json().catch(() => ({}))

    // Simple placeholder calculation — in production replace with real logic
    const deliveryFee = 500 + (body['weight_kg'] || 1) * 50
    return new Response(JSON.stringify({ delivery_fee_cents: deliveryFee }), { status: 200 })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
