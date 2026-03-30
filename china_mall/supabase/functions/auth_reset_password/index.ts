import { serve } from 'std/server'
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}))
    const email = body.email || null
    const token = body.token || null
    const newPassword = body.new_password || null
    if (!email || !token || !newPassword) return new Response(JSON.stringify({ error: 'missing params' }), { status: 400 })

    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // verify token
    const { data: tokenData, error: tErr } = await supabase
      .from('email_resets')
      .select('*')
      .eq('email', email)
      .eq('reset_token', token)
      .order('created_at', { ascending: false })
      .maybeSingle()
    if (tErr) return new Response(JSON.stringify({ error: tErr.message }), { status: 500 })
    const rec = tokenData as { reset_token?: string } | null
    if (!rec) return new Response(JSON.stringify({ error: 'invalid_token' }), { status: 400 })

    // find profile by email
    const { data: profileData, error: pErr } = await supabase
      .from('profiles')
      .select('id')
      .ilike('email', email)
      .maybeSingle()
    if (pErr) return new Response(JSON.stringify({ error: pErr.message }), { status: 500 })
    const profile = profileData as { id?: string } | null
    if (!profile) return new Response(JSON.stringify({ error: 'profile_not_found' }), { status: 404 })

    // update auth user password using admin API
    try {
      await supabase.auth.admin.updateUserById(profile.id, { password: newPassword })
    } catch (adminErr) {
      return new Response(JSON.stringify({ error: 'failed_to_update_password', detail: String(adminErr) }), { status: 500 })
    }

    // cleanup tokens
    await supabase.from('email_resets').delete().eq('email', email)

    return new Response(JSON.stringify({ ok: true }), { status: 200 })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
