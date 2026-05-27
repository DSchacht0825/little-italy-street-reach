-- Little Italy Street Reach - Combined Database Migration
-- Run this in Supabase SQL Editor

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create sequence for client IDs
CREATE SEQUENCE IF NOT EXISTS person_id_seq START 1;

-- =====================================================
-- PERSONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.persons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  middle_name TEXT,
  last_name TEXT,
  nickname TEXT,
  aka TEXT,
  date_of_birth DATE,
  age INTEGER,
  gender TEXT,
  race TEXT,
  ethnicity TEXT,
  sexual_orientation TEXT,
  preferred_language TEXT DEFAULT 'English',
  phone_number TEXT,
  photo_url TEXT,

  -- Physical description
  height TEXT,
  weight TEXT,
  hair_color TEXT,
  eye_color TEXT,
  physical_description TEXT,
  notes TEXT,

  -- Housing status
  living_situation TEXT,
  length_of_time_homeless TEXT,
  chronic_homeless BOOLEAN DEFAULT FALSE,
  veteran_status BOOLEAN DEFAULT FALSE,
  disability_status BOOLEAN DEFAULT FALSE,
  disability_types TEXT[],

  -- Health
  domestic_violence_victim BOOLEAN DEFAULT FALSE,
  chronic_health BOOLEAN DEFAULT FALSE,
  mental_health BOOLEAN DEFAULT FALSE,
  addictions TEXT[],

  -- Financial
  income TEXT,
  income_amount NUMERIC(10,2),
  evictions INTEGER DEFAULT 0,
  support_system TEXT,

  -- Program info
  enrollment_date DATE DEFAULT CURRENT_DATE,
  case_manager TEXT,
  referral_source TEXT,
  referral_source_other TEXT,
  release_of_information BOOLEAN DEFAULT FALSE,

  -- Contact tracking
  last_contact DATE,
  contact_count INTEGER DEFAULT 0,

  -- Exit tracking
  exit_date DATE,
  exit_destination TEXT,
  exit_notes TEXT,
  status TEXT DEFAULT 'active',

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID
);

-- =====================================================
-- ENCOUNTERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.encounters (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id UUID NOT NULL REFERENCES public.persons(id) ON DELETE CASCADE,
  service_date DATE NOT NULL DEFAULT CURRENT_DATE,
  outreach_location TEXT NOT NULL,
  outreach_worker TEXT NOT NULL,
  latitude NUMERIC(10, 7) NOT NULL,
  longitude NUMERIC(10, 7) NOT NULL,

  -- Service details
  referral_source TEXT,
  service_subtype TEXT,
  language_preference TEXT,
  cultural_notes TEXT,

  -- Clinical
  co_occurring_mh_sud BOOLEAN DEFAULT FALSE,
  co_occurring_type TEXT,

  -- Services provided
  transportation_provided BOOLEAN DEFAULT FALSE,
  shower_trailer BOOLEAN DEFAULT FALSE,
  other_services TEXT,
  support_services TEXT[],

  -- Placement
  placement_made BOOLEAN DEFAULT FALSE,
  placement_location TEXT,
  placement_location_other TEXT,
  placement_detox_name TEXT,
  refused_shelter BOOLEAN DEFAULT FALSE,
  refused_services BOOLEAN DEFAULT FALSE,
  shelter_unavailable BOOLEAN DEFAULT FALSE,

  -- Case management
  high_utilizer_contact BOOLEAN DEFAULT FALSE,
  case_management_notes TEXT,
  follow_up BOOLEAN DEFAULT FALSE,

  -- Media
  photo_urls TEXT[],
  log_id TEXT,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID
);

-- =====================================================
-- USER PROFILES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  full_name TEXT,
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin', 'super_admin')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- STATUS CHANGES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.status_changes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id UUID NOT NULL REFERENCES public.persons(id) ON DELETE CASCADE,
  change_type TEXT NOT NULL CHECK (change_type IN ('exit', 'return_to_active')),
  change_date DATE NOT NULL DEFAULT CURRENT_DATE,
  exit_destination TEXT,
  notes TEXT,
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEXES (with IF NOT EXISTS)
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_persons_first_name_trgm ON public.persons USING gin (first_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_persons_last_name_trgm ON public.persons USING gin (last_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_persons_client_id ON public.persons(client_id);
CREATE INDEX IF NOT EXISTS idx_persons_exit_date ON public.persons(exit_date);
CREATE INDEX IF NOT EXISTS idx_encounters_person_id ON public.encounters(person_id);
CREATE INDEX IF NOT EXISTS idx_encounters_service_date ON public.encounters(service_date DESC);
CREATE INDEX IF NOT EXISTS idx_encounters_location ON public.encounters(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_encounters_outreach_worker ON public.encounters(outreach_worker);
CREATE INDEX IF NOT EXISTS idx_encounters_high_utilizer ON public.encounters(high_utilizer_contact);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_status_changes_person_id ON public.status_changes(person_id);
CREATE INDEX IF NOT EXISTS idx_status_changes_date ON public.status_changes(change_date);

-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================
ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.encounters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.status_changes ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Authenticated users can view all persons" ON public.persons;
DROP POLICY IF EXISTS "Authenticated users can insert persons" ON public.persons;
DROP POLICY IF EXISTS "Authenticated users can update persons" ON public.persons;
DROP POLICY IF EXISTS "Authenticated users can view all encounters" ON public.encounters;
DROP POLICY IF EXISTS "Authenticated users can insert encounters" ON public.encounters;
DROP POLICY IF EXISTS "Authenticated users can update encounters" ON public.encounters;
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Authenticated users can view all status_changes" ON public.status_changes;
DROP POLICY IF EXISTS "Authenticated users can insert status_changes" ON public.status_changes;

-- Persons policies
CREATE POLICY "Authenticated users can view all persons"
  ON public.persons FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert persons"
  ON public.persons FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update persons"
  ON public.persons FOR UPDATE
  TO authenticated
  USING (true);

-- Encounters policies
CREATE POLICY "Authenticated users can view all encounters"
  ON public.encounters FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert encounters"
  ON public.encounters FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update encounters"
  ON public.encounters FOR UPDATE
  TO authenticated
  USING (true);

-- User profiles policies
CREATE POLICY "Users can view own profile"
  ON public.user_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
  ON public.user_profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admins can update all profiles"
  ON public.user_profiles FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Status changes policies
CREATE POLICY "Authenticated users can view all status_changes"
  ON public.status_changes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert status_changes"
  ON public.status_changes FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Generate client ID function
CREATE OR REPLACE FUNCTION generate_client_id()
RETURNS TEXT AS $$
BEGIN
  RETURN 'LI-' || LPAD(nextval('person_id_seq')::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- Check if person is active (contacted within 90 days)
CREATE OR REPLACE FUNCTION is_person_active(person_last_contact DATE)
RETURNS BOOLEAN AS $$
BEGIN
  IF person_last_contact IS NULL THEN
    RETURN FALSE;
  END IF;
  RETURN person_last_contact >= CURRENT_DATE - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Update last_contact when encounter is added
CREATE OR REPLACE FUNCTION update_person_last_contact()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.persons
  SET
    last_contact = NEW.service_date,
    contact_count = contact_count + 1,
    updated_at = NOW()
  WHERE id = NEW.person_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updating last_contact
DROP TRIGGER IF EXISTS trigger_update_person_last_contact ON public.encounters;
CREATE TRIGGER trigger_update_person_last_contact
  AFTER INSERT ON public.encounters
  FOR EACH ROW
  EXECUTE FUNCTION update_person_last_contact();

-- Auto-create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name')
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Grant permissions
GRANT USAGE ON SEQUENCE person_id_seq TO authenticated;
GRANT EXECUTE ON FUNCTION generate_client_id TO authenticated;
GRANT EXECUTE ON FUNCTION is_person_active TO authenticated;

-- =====================================================
-- STORAGE BUCKET FOR PHOTOS
-- =====================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('client-photos', 'client-photos', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
DROP POLICY IF EXISTS "Authenticated users can upload client photos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can view client photos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update client photos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete client photos" ON storage.objects;

CREATE POLICY "Authenticated users can upload client photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'client-photos');

CREATE POLICY "Authenticated users can view client photos"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'client-photos');

CREATE POLICY "Authenticated users can update client photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'client-photos');

CREATE POLICY "Authenticated users can delete client photos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'client-photos');

-- Done!
SELECT 'Little Italy Street Reach database setup complete!' as status;
