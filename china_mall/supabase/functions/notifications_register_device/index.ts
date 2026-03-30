import { serve } from 'std/server'
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}))
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    const token = body.token || null
    if (!token) return new Response(JSON.stringify({ error: 'missing token' }), { status: 400 })

    const { data, error } = await supabase.from('notification_devices').upsert([{
      token,
      platform: body.platform || null,
      device_name: body.device_name || null,
      profile_id: body.profile_id || null,
      created_at: new Date().toISOString(),
    }], { onConflict: ['token'] })

    if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 })
    return new Response(JSON.stringify({ ok: true, device: data?.[0] ?? null }), { status: 200 })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
