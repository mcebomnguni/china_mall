import { serve } from 'std/server'
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}))
    const email = body.email || null
    if (!email) return new Response(JSON.stringify({ error: 'missing email' }), { status: 400 })

    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    const { data, error } = await supabase
      .from('profiles')
      .select('email, full_name')
      .ilike('email', email)
      .maybeSingle()
    if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 })
    const profile = data as { email?: string; full_name?: string } | null
    if (!profile) return new Response(JSON.stringify({ error: 'not_found' }), { status: 404 })

    // Return the username/email as the identifier
    return new Response(JSON.stringify({ username: profile.email ?? profile.full_name }), { status: 200 })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
