// Edge Function: distribute_approvals
// Simple example: approve pending stores in batches and write audit logs.
// Deploy with: `supabase functions deploy distribute_approvals`

import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL = process.env.SUPABASE_URL || ''
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || ''

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

export default async (_req: Request) => {
  try {
    // Find pending stores (limit 10 for example)
    const { data: pending, error: pendingError } = await supabase
      .from('stores')
      .select('id, name, owner')
      .eq('approved', false)
      .limit(10)
    if (pendingError) throw pendingError

    const ids = (pending || []).map((r: any) => r.id)
    if (ids.length === 0) {
      return new Response(JSON.stringify({ status: 'no_pending' }), { status: 200, headers: { 'Content-Type': 'application/json' } })
    }

    // Approve them (simple example logic)
    const { error: updateError } = await supabase
      .from('stores')
      .update({ approved: true })
      .in('id', ids)
    if (updateError) throw updateError

    // Insert audit logs for each approved store
    const logs = (pending || []).map((r: any) => ({
      actor: null, // anonymous/system - replace with real actor if you have auth context
      action: 'approve_store',
      resource_type: 'store',
      resource_id: String(r.id),
      details: { name: r.name, owner: r.owner },
    }))
    const { error: logError } = await supabase.from('audit_logs').insert(logs)
    if (logError) throw logError

    return new Response(JSON.stringify({ status: 'approved', count: ids.length, ids }), { status: 200, headers: { 'Content-Type': 'application/json' } })
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message || String(err) }), { status: 500, headers: { 'Content-Type': 'application/json' } })
  }
}
