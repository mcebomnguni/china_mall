import { serve } from 'std/server'
import { createClient } from '@supabase/supabase-js'

// Minimal phone OTP function — in production integrate with SMS provider
serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}))
    const phone = body.phone_number || null
    const purpose = body.purpose || 'password_reset'
    if (!phone) return new Response(JSON.stringify({ error: 'missing phone_number' }), { status: 400 })

    // simple sandbox behaviour: generate a 6-digit code and store in temp table (or return in response for sandbox)
    const code = Math.floor(100000 + Math.random() * 900000).toString()

    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // store in phone_otps table
    await supabase.from('phone_otps').insert([{ phone_number: phone, code, purpose, created_at: new Date().toISOString() }])

    // Return sandbox flag and code for local/testing only
    return new Response(JSON.stringify({ sandbox: true, code }), { status: 200 })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
