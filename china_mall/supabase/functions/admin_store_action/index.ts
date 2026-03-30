import { serve } from 'std/server'
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}))
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    const id = body.id
    const action = body.action
    const reason = body.reason || null

    if (!id || !action) return new Response(JSON.stringify({ error: 'missing id or action' }), { status: 400 })

    if (action === 'approve') {
      const { data, error } = await supabase.from('stores').update({ status: 'approved' }).eq('id', id).select().limit(1)
      if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 })
      // insert audit log
      await supabase.from('audit_logs').insert([{ actor: null, action: 'approve_store', resource_type: 'store', resource_id: String(id), details: { reason } }])
      return new Response(JSON.stringify({ ok: true, store: data?.[0] ?? null }), { status: 200 })
    } else if (action === 'reject') {
      const { data, error } = await supabase.from('stores').update({ status: 'rejected' }).eq('id', id).select().limit(1)
      if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 })
      await supabase.from('audit_logs').insert([{ actor: null, action: 'reject_store', resource_type: 'store', resource_id: String(id), details: { reason } }])
      return new Response(JSON.stringify({ ok: true }), { status: 200 })
    }

    return new Response(JSON.stringify({ error: 'unknown action' }), { status: 400 })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
