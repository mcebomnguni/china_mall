import { serve } from 'std/server'
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}))
    const biometricToken = body.biometric_token || null
    if (!biometricToken) return new Response(JSON.stringify({ error: 'missing biometric_token' }), { status: 400 })

    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Look up device by token
    const { data: devData, error: dErr } = await supabase
      .from('devices')
      .select('profile_id')
      .eq('device_id', biometricToken)
      .maybeSingle()
    if (dErr) return new Response(JSON.stringify({ error: dErr.message }), { status: 500 })
    const dev = devData as { profile_id?: string } | null
    if (!dev || !dev.profile_id) {
      // fallback: sandbox response for dev/testing
      return new Response(JSON.stringify({ error: 'device_not_registered' }), { status: 404 })
    }

    // IMPORTANT: generating real access/refresh tokens requires integration with Supabase Auth internals.
    // As a minimal compatibility shim, return a sandbox response indicating success. Replace this logic
    // with a secure flow that issues real JWTs or exchanges a custom token for session tokens.
    return new Response(JSON.stringify({ ok: true, profile_id: dev.profile_id, sandbox: true }), { status: 200 })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
