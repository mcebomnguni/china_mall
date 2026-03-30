import { serve } from 'std/server'
import { createClient } from '@supabase/supabase-js'

serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}))
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // This endpoint expects a file_path to be uploaded by client or the function
    // could accept a base64 blob and upload to storage. Here we accept a 'file_path' indicating a URL
    const { data, error } = await supabase.from('courier_documents').insert([{
      doc_type: body.doc_type,
      file_url: body.file_path,
      created_at: new Date().toISOString(),
    }])
    if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 })
    return new Response(JSON.stringify({ document: data?.[0] ?? null }), { status: 201 })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
