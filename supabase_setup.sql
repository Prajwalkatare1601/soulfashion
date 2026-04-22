-- 1. Create customers table
CREATE TABLE customers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  photo_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

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
