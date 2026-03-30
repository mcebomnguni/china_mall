import { serve } from 'std/server'
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}))
    const phone = body.phone_number || null
    const otp = body.otp || null
    if (!phone || !otp) return new Response(JSON.stringify({ error: 'missing params' }), { status: 400 })

    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    const { data, error } = await supabase
      .from('phone_otps')
      .select('*')
      .eq('phone_number', phone)
      .order('created_at', { ascending: false })
      .maybeSingle()
    if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 })
    const record = data as { code?: string; purpose?: string } | null
    if (!record) return new Response(JSON.stringify({ verified: false, error: 'not_found' }), { status: 404 })

    if (record.code === otp) {
      // For username recovery, fetch profile username; otherwise create reset token
      if (record.purpose === 'username_recovery') {
        const { data: profile, error: pErr } = await supabase
          .from('profiles')
          .select('email')
          .eq('phone', phone)
          .maybeSingle()
        if (pErr) return new Response(JSON.stringify({ error: pErr.message }), { status: 500 })
        const username = (profile as { email?: string } | null)?.email ?? null
        return new Response(JSON.stringify({ verified: true, purpose: 'username_recovery', username }), { status: 200 })
      } else {
        // create a short-lived reset token
        const resetToken = Math.random().toString(36).substring(2, 12)
        await supabase.from('phone_resets').insert([{ phone_number: phone, reset_token: resetToken, created_at: new Date().toISOString() }])
        return new Response(JSON.stringify({ verified: true, reset_token: resetToken }), { status: 200 })
      }
    }

    return new Response(JSON.stringify({ verified: false }), { status: 200 })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
