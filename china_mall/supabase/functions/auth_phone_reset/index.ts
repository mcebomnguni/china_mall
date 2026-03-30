import { serve } from 'std/server'
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}))
    const phone = body.phone_number || null
    const resetToken = body.reset_token || null
    const newPassword = body.new_password || null
    if (!phone || !resetToken || !newPassword) return new Response(JSON.stringify({ error: 'missing params' }), { status: 400 })

    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    const { data, error } = await supabase
      .from('phone_resets')
      .select('*')
      .eq('phone_number', phone)
      .eq('reset_token', resetToken)
      .order('created_at', { ascending: false })
      .maybeSingle()
    if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 })
    const rec = data as { reset_token?: string } | null
    if (!rec) return new Response(JSON.stringify({ error: 'invalid_token' }), { status: 400 })

    // Find profile by phone
    const { data: profileData, error: pErr } = await supabase
      .from('profiles')
      .select('id')
      .eq('phone', phone)
      .maybeSingle()
    if (pErr) return new Response(JSON.stringify({ error: pErr.message }), { status: 500 })
    const profile = profileData as { id?: string } | null
    if (!profile) return new Response(JSON.stringify({ error: 'profile_not_found' }), { status: 404 })

    // Use Supabase Admin API to update the Auth user's password
    try {
      // supabase.auth.admin is available when using a service_role key
      // profile.id is expected to be the auth.users.id (UUID)
      await supabase.auth.admin.updateUserById(profile.id, { password: newPassword })
    } catch (adminErr) {
      return new Response(JSON.stringify({ error: 'failed_to_update_password', detail: String(adminErr) }), { status: 500 })
    }

    // Clean up reset tokens for this phone
    await supabase.from('phone_resets').delete().eq('phone_number', phone)

    return new Response(JSON.stringify({ ok: true }), { status: 200 })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
