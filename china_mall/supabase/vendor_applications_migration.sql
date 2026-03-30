-- Vendor applications table
-- Stores onboarding documents for both formal (registered business) and informal (unregistered) vendors
-- Admin reviews submissions before store goes live

CREATE TABLE IF NOT EXISTS vendor_applications (
  id bigserial PRIMARY KEY,
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  business_type text CHECK (business_type IN ('formal', 'informal')) NOT NULL,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'more_info_required')),

  -- Shared
  store_name text NOT NULL,
  admin_notes text,
  reviewed_at timestamptz,
  reviewed_by uuid REFERENCES profiles(id),

  -- Formal (registered business) fields
  cor_url text,               -- Company registration certificate
  proof_of_account_url text,  -- Bank account proof
  people jsonb,               -- [{name, surname, email, id_url}] up to 3

  -- Informal (unregistered vendor) fields
  id_document_url text,       -- Owner ID
  permit_url text,            -- Trading/vendor permit
  affidavit_url text,         -- Sworn statement
  informal_proof_of_account_url text,
  contact_info jsonb,         -- {name, surname, email, phone}
  workers jsonb,              -- [{name, phone, id_url}]

  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_vendor_applications_profile ON vendor_applications(profile_id);
CREATE INDEX IF NOT EXISTS idx_vendor_applications_status ON vendor_applications(status);

-- RLS
ALTER TABLE vendor_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "vendor_app_owner_select" ON vendor_applications;
CREATE POLICY "vendor_app_owner_select" ON vendor_applications
  FOR SELECT USING (profile_id = auth.uid());

DROP POLICY IF EXISTS "vendor_app_owner_insert" ON vendor_applications;
CREATE POLICY "vendor_app_owner_insert" ON vendor_applications
  FOR INSERT WITH CHECK (profile_id = auth.uid());

DROP POLICY IF EXISTS "vendor_app_owner_update" ON vendor_applications;
CREATE POLICY "vendor_app_owner_update" ON vendor_applications
  FOR UPDATE USING (profile_id = auth.uid() AND status = 'pending');

-- Allow admins to view and update all applications
DROP POLICY IF EXISTS "vendor_app_admin_all" ON vendor_applications;
CREATE POLICY "vendor_app_admin_all" ON vendor_applications
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'staff'))
  );

-- Storage bucket for vendor documents (run this once via Supabase dashboard or CLI)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('vendor-docs', 'vendor-docs', false)
-- ON CONFLICT (id) DO NOTHING;
