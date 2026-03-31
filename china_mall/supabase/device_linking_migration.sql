-- ============================================================
-- China Stall — Device-Linked Accounts Migration
-- Stores device fingerprints per user, requires multi-factor
-- verification when logging in from a new/untrusted device.
-- Device links expire after 6 months.
-- ============================================================


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  TABLE: user_devices                                        ║
-- ║  Linked devices per user (from device_info_plus)            ║
-- ╚══════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS user_devices (
  id              bigserial PRIMARY KEY,
  profile_id      uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  device_id       text NOT NULL,          -- unique device fingerprint
  device_name     text,                   -- e.g. "Samsung Galaxy S24"
  device_os       text,                   -- e.g. "Android 15"
  is_trusted      boolean DEFAULT false,  -- becomes true after verification
  last_login_at   timestamptz DEFAULT now(),
  linked_at       timestamptz DEFAULT now(),
  expires_at      timestamptz DEFAULT (now() + interval '6 months'),
  created_at      timestamptz DEFAULT now(),
  UNIQUE (profile_id, device_id)
);

CREATE INDEX IF NOT EXISTS idx_user_devices_profile ON user_devices (profile_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_device  ON user_devices (device_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_expires ON user_devices (expires_at);


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  TABLE: device_verification_codes                           ║
-- ║  6-digit email codes for new-device verification            ║
-- ╚══════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS device_verification_codes (
  id          bigserial PRIMARY KEY,
  profile_id  uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  device_id   text NOT NULL,
  code        text NOT NULL,              -- 6-digit code
  used        boolean DEFAULT false,
  expires_at  timestamptz DEFAULT (now() + interval '10 minutes'),
  created_at  timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_dvc_profile   ON device_verification_codes (profile_id);
CREATE INDEX IF NOT EXISTS idx_dvc_code      ON device_verification_codes (code);
CREATE INDEX IF NOT EXISTS idx_dvc_expires   ON device_verification_codes (expires_at);


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  RLS: user_devices                                          ║
-- ╚══════════════════════════════════════════════════════════════╝

ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

-- Users can read their own devices
CREATE POLICY user_devices_select_own ON user_devices
  FOR SELECT
  USING (profile_id = auth.uid());

-- Users can insert their own device rows (via register_device function too)
CREATE POLICY user_devices_insert_own ON user_devices
  FOR INSERT
  WITH CHECK (profile_id = auth.uid());

-- Users can update their own device rows
CREATE POLICY user_devices_update_own ON user_devices
  FOR UPDATE
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

-- Users can delete (revoke) their own devices
CREATE POLICY user_devices_delete_own ON user_devices
  FOR DELETE
  USING (profile_id = auth.uid());

-- Admin/staff can see all devices
CREATE POLICY user_devices_admin_all ON user_devices
  FOR ALL
  USING  (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')));


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  RLS: device_verification_codes                             ║
-- ╚══════════════════════════════════════════════════════════════╝

ALTER TABLE device_verification_codes ENABLE ROW LEVEL SECURITY;

-- Users can read their own codes (for display / retry logic)
CREATE POLICY dvc_select_own ON device_verification_codes
  FOR SELECT
  USING (profile_id = auth.uid());

-- Users can insert their own codes (via generate function too)
CREATE POLICY dvc_insert_own ON device_verification_codes
  FOR INSERT
  WITH CHECK (profile_id = auth.uid());

-- Users can update their own codes (mark as used)
CREATE POLICY dvc_update_own ON device_verification_codes
  FOR UPDATE
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

-- Admin/staff can see all verification codes
CREATE POLICY dvc_admin_all ON device_verification_codes
  FOR ALL
  USING  (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin','staff')));


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  FUNCTION 1: register_device                                ║
-- ║  INSERT or UPDATE a device row.                             ║
-- ║  New devices get is_trusted = false.                        ║
-- ║  Existing trusted devices keep their trust (just bump       ║
-- ║  last_login_at and refresh the 6-month expiry window).      ║
-- ╚══════════════════════════════════════════════════════════════╝

CREATE OR REPLACE FUNCTION register_device(
  p_user_id     uuid,
  p_device_id   text,
  p_device_name text,
  p_device_os   text
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing  record;
  v_result    jsonb;
BEGIN
  -- Check for an existing row
  SELECT id, is_trusted, expires_at
    INTO v_existing
    FROM user_devices
   WHERE profile_id = p_user_id
     AND device_id  = p_device_id;

  IF v_existing.id IS NOT NULL THEN
    -- Device already registered: update metadata, bump login time
    -- If the device was trusted AND not expired, keep trust.
    -- If expired, revoke trust so user must re-verify.
    UPDATE user_devices
       SET device_name   = COALESCE(NULLIF(p_device_name, ''), device_name),
           device_os     = COALESCE(NULLIF(p_device_os, ''), device_os),
           last_login_at = now(),
           is_trusted    = CASE
                             WHEN v_existing.is_trusted AND v_existing.expires_at > now()
                             THEN true
                             ELSE false
                           END,
           expires_at    = CASE
                             WHEN v_existing.is_trusted AND v_existing.expires_at > now()
                             THEN now() + interval '6 months'
                             ELSE expires_at  -- don't extend until re-verified
                           END
     WHERE id = v_existing.id
     RETURNING jsonb_build_object(
       'device_row_id', id,
       'is_trusted',    is_trusted,
       'is_new_device', false,
       'expires_at',    expires_at
     ) INTO v_result;
  ELSE
    -- Brand-new device: insert as untrusted
    INSERT INTO user_devices (profile_id, device_id, device_name, device_os, is_trusted)
    VALUES (p_user_id, p_device_id, p_device_name, p_device_os, false)
    RETURNING jsonb_build_object(
      'device_row_id', id,
      'is_trusted',    is_trusted,
      'is_new_device', true,
      'expires_at',    expires_at
    ) INTO v_result;
  END IF;

  RETURN v_result;
END;
$$;


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  FUNCTION 2: is_device_trusted                              ║
-- ║  Returns true if the device exists, is trusted, and has     ║
-- ║  not expired.                                               ║
-- ╚══════════════════════════════════════════════════════════════╝

CREATE OR REPLACE FUNCTION is_device_trusted(
  p_user_id   uuid,
  p_device_id text
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_trusted boolean;
BEGIN
  SELECT (is_trusted = true AND expires_at > now())
    INTO v_trusted
    FROM user_devices
   WHERE profile_id = p_user_id
     AND device_id  = p_device_id;

  RETURN COALESCE(v_trusted, false);
END;
$$;


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  FUNCTION 3: generate_device_verification_code              ║
-- ║  Creates a random 6-digit code for email verification.      ║
-- ║  Invalidates any previous unused codes for the same device. ║
-- ║  Returns the code (edge function sends the email).          ║
-- ╚══════════════════════════════════════════════════════════════╝

CREATE OR REPLACE FUNCTION generate_device_verification_code(
  p_user_id   uuid,
  p_device_id text
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_code text;
BEGIN
  -- Generate a random 6-digit numeric code (100000 – 999999)
  v_code := lpad(floor(random() * 900000 + 100000)::int::text, 6, '0');

  -- Expire all previous unused codes for this user + device
  UPDATE device_verification_codes
     SET used = true
   WHERE profile_id = p_user_id
     AND device_id  = p_device_id
     AND used = false;

  -- Insert the fresh code
  INSERT INTO device_verification_codes (profile_id, device_id, code)
  VALUES (p_user_id, p_device_id, v_code);

  RETURN v_code;
END;
$$;


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  FUNCTION 4: verify_device_code                             ║
-- ║  Validates the 6-digit code, marks device as trusted,       ║
-- ║  resets the 6-month expiry window. Returns boolean.         ║
-- ╚══════════════════════════════════════════════════════════════╝

CREATE OR REPLACE FUNCTION verify_device_code(
  p_user_id   uuid,
  p_device_id text,
  p_code      text
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_code_id bigint;
BEGIN
  -- Find a valid, unused, non-expired code
  SELECT id INTO v_code_id
    FROM device_verification_codes
   WHERE profile_id = p_user_id
     AND device_id  = p_device_id
     AND code       = p_code
     AND used       = false
     AND expires_at > now()
   ORDER BY created_at DESC
   LIMIT 1;

  IF v_code_id IS NULL THEN
    RETURN false;
  END IF;

  -- Mark code as used
  UPDATE device_verification_codes
     SET used = true
   WHERE id = v_code_id;

  -- Trust the device and refresh expiry
  UPDATE user_devices
     SET is_trusted    = true,
         linked_at     = now(),
         last_login_at = now(),
         expires_at    = now() + interval '6 months'
   WHERE profile_id = p_user_id
     AND device_id  = p_device_id;

  RETURN true;
END;
$$;


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  FUNCTION 5: get_user_devices                               ║
-- ║  Returns all devices linked to a user.                      ║
-- ╚══════════════════════════════════════════════════════════════╝

CREATE OR REPLACE FUNCTION get_user_devices(
  p_user_id uuid
) RETURNS TABLE (
  device_row_id   bigint,
  device_id       text,
  device_name     text,
  device_os       text,
  is_trusted      boolean,
  is_expired      boolean,
  last_login_at   timestamptz,
  linked_at       timestamptz,
  expires_at      timestamptz,
  created_at      timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    ud.id            AS device_row_id,
    ud.device_id,
    ud.device_name,
    ud.device_os,
    ud.is_trusted,
    (ud.expires_at <= now()) AS is_expired,
    ud.last_login_at,
    ud.linked_at,
    ud.expires_at,
    ud.created_at
  FROM user_devices ud
  WHERE ud.profile_id = p_user_id
  ORDER BY ud.last_login_at DESC;
END;
$$;


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  FUNCTION 6: revoke_device                                  ║
-- ║  Sets is_trusted = false for a specific device.             ║
-- ╚══════════════════════════════════════════════════════════════╝

CREATE OR REPLACE FUNCTION revoke_device(
  p_user_id   uuid,
  p_device_id text
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rows int;
BEGIN
  UPDATE user_devices
     SET is_trusted = false
   WHERE profile_id = p_user_id
     AND device_id  = p_device_id;

  GET DIAGNOSTICS v_rows = ROW_COUNT;
  RETURN v_rows > 0;
END;
$$;


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  CLEANUP: auto-expire old verification codes                ║
-- ║  Optional pg_cron job (if extension enabled).               ║
-- ║  Otherwise, expired codes are simply ignored by the         ║
-- ║  verify function.                                           ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Uncomment if pg_cron is available on your Supabase project:
--
-- SELECT cron.schedule(
--   'cleanup_expired_device_codes',
--   '0 */6 * * *',  -- every 6 hours
--   $$DELETE FROM device_verification_codes WHERE expires_at < now() - interval '1 day'$$
-- );
--
-- SELECT cron.schedule(
--   'revoke_expired_device_trust',
--   '0 3 * * *',  -- daily at 3 AM
--   $$UPDATE user_devices SET is_trusted = false WHERE expires_at < now() AND is_trusted = true$$
-- );


-- ============================================================
-- Migration complete: device_linking
-- Tables:  user_devices, device_verification_codes
-- Functions: register_device, is_device_trusted,
--            generate_device_verification_code,
--            verify_device_code, get_user_devices, revoke_device
-- ============================================================
