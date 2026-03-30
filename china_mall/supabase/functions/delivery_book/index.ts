import { serve } from 'std/server'
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)
    const body = await req.json().catch(() => ({}))

    // Insert a delivery record into a deliveries table (create table in schema.sql)
    const { data, error } = await supabase.from('deliveries').insert([{
      order_id: body.order_id,
      delivery_type: body.delivery_type,
      pickup_address: body.pickup_address,
      pickup_lat: body.pickup_lat,
      pickup_lng: body.pickup_lng,
      delivery_address: body.delivery_address,
      delivery_lat: body.delivery_lat,
      delivery_lng: body.delivery_lng,
      weight_kg: body.weight_kg || 1,
      status: 'created',
    }])

    if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 })
    return new Response(JSON.stringify({ delivery: data?.[0] || null }), { status: 201 })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
