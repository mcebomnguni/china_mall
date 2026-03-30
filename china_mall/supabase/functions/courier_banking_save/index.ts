import { serve } from 'std/server'
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}))
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    const { data, error } = await supabase.from('courier_bank_details').upsert([{
      profile_id: body.profile_id,
      account_name: body.account_name,
      account_number: body.account_number,
      bank_name: body.bank_name,
    }], { onConflict: ['profile_id'] })

    if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 })
    return new Response(JSON.stringify({ ok: true, data: data?.[0] ?? null }), { status: 200 })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
