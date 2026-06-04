-- 1. Create customers table
CREATE TABLE customers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  photo_url TEXT,
  order_status TEXT DEFAULT 'ordered',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- If the table already exists, run this migration:
-- ALTER TABLE customers ADD COLUMN order_status TEXT DEFAULT 'ordered';

-- 2. Create measurements table
CREATE TABLE measurements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  chest TEXT,
  waist TEXT,
  shoulder TEXT,
  sleeve TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Create scribbles table
CREATE TABLE scribbles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- IMPORTANT Storage Bucket Setup:
-- You must manually go to the 'Storage' section in your Supabase Dashboard
-- 1. Create a new bucket named: "scribbles"
-- 2. Toggle the "Public bucket" setting so it is publicly accessible.

-- IMPORTANT RLS rules since Auth is skipped for MVP:
-- Turn off Row Level Security on the above tables so we can read and write freely from the app.
-- To do this, go to Authentication -> Policies, or simply run:
ALTER TABLE customers DISABLE ROW LEVEL SECURITY;
ALTER TABLE measurements DISABLE ROW LEVEL SECURITY;
ALTER TABLE scribbles DISABLE ROW LEVEL SECURITY;

-- 4. Create reference_photos table
CREATE TABLE reference_photos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE reference_photos DISABLE ROW LEVEL SECURITY;

-- IMPORTANT Storage Bucket Setup:
-- 1. Create a new bucket named: "reference_photos"
-- 2. Toggle the "Public bucket" setting so it is publicly accessible.

-- 5. Storage Setup & RLS Policies
-- Run these to create buckets and allow authenticated users to upload
INSERT INTO storage.buckets (id, name, public) VALUES ('customer_photos', 'customer_photos', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('scribbles', 'scribbles', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('reference_photos', 'reference_photos', true) ON CONFLICT DO NOTHING;

-- Storage Policies (Allow anyone to read, but only authenticated users to upload/delete)
-- NOTE: If these policies already exist, they might throw an error. You can create them in the Supabase Dashboard UI instead.
CREATE POLICY "Public Read Access" ON storage.objects FOR SELECT USING (true);
CREATE POLICY "Authenticated Insert" ON storage.objects FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated Update" ON storage.objects FOR UPDATE WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authenticated Delete" ON storage.objects FOR DELETE USING (auth.role() = 'authenticated');
