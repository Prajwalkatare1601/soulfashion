-- Migration script to add boutiques support and multi-tenant RLS policies
-- Run this in the Supabase SQL Editor on your existing database

BEGIN;

-- 1. Create boutiques table
CREATE TABLE IF NOT EXISTS boutiques (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create boutique_users table to map auth users to boutiques
CREATE TABLE IF NOT EXISTS boutique_users (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  boutique_id UUID REFERENCES boutiques(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Add boutique_id to customers table
ALTER TABLE customers ADD COLUMN IF NOT EXISTS boutique_id UUID REFERENCES boutiques(id) ON DELETE CASCADE;

-- 4. Create a default boutique if none exists
INSERT INTO boutiques (name)
SELECT 'Default Boutique'
WHERE NOT EXISTS (SELECT 1 FROM boutiques LIMIT 1);

-- 5. Assign all existing customers to the default boutique
UPDATE customers
SET boutique_id = (SELECT id FROM boutiques ORDER BY created_at LIMIT 1)
WHERE boutique_id IS NULL;

-- Make boutique_id NOT NULL after backfilling
ALTER TABLE customers ALTER COLUMN boutique_id SET NOT NULL;

-- 6. Assign all existing logged-in users to the default boutique so they retain access
INSERT INTO boutique_users (user_id, boutique_id)
SELECT id, (SELECT id FROM boutiques ORDER BY created_at LIMIT 1)
FROM auth.users
ON CONFLICT (user_id) DO NOTHING;

-- 7. Enable Row Level Security (RLS) on all tables
ALTER TABLE boutiques ENABLE ROW LEVEL SECURITY;
ALTER TABLE boutique_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE scribbles ENABLE ROW LEVEL SECURITY;
ALTER TABLE reference_photos ENABLE ROW LEVEL SECURITY;

-- 8. Drop any existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can manage their own boutique user assignment" ON boutique_users;
DROP POLICY IF EXISTS "Users can view their boutique" ON boutiques;
DROP POLICY IF EXISTS "Users can update their boutique" ON boutiques;
DROP POLICY IF EXISTS "Users can create a boutique" ON boutiques;
DROP POLICY IF EXISTS "Users can manage customers in their boutique" ON customers;
DROP POLICY IF EXISTS "Users can manage measurements for customers in their boutique" ON measurements;
DROP POLICY IF EXISTS "Users can manage scribbles for customers in their boutique" ON scribbles;
DROP POLICY IF EXISTS "Users can manage reference photos for customers in their boutique" ON reference_photos;

-- 9. Create RLS Policies

-- Boutique Users policies
CREATE POLICY "Users can manage their own boutique user assignment" 
ON boutique_users 
FOR ALL 
TO authenticated 
USING (user_id = auth.uid()) 
WITH CHECK (user_id = auth.uid());

-- Boutiques policies
CREATE POLICY "Users can view their boutique" 
ON boutiques 
FOR SELECT 
TO authenticated 
USING (
  id IN (
    SELECT boutique_id 
    FROM boutique_users 
    WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Users can update their boutique" 
ON boutiques 
FOR UPDATE 
TO authenticated 
USING (
  id IN (
    SELECT boutique_id 
    FROM boutique_users 
    WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  id IN (
    SELECT boutique_id 
    FROM boutique_users 
    WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Users can create a boutique" 
ON boutiques 
FOR INSERT 
TO authenticated 
WITH CHECK (true);

-- Customers policies
CREATE POLICY "Users can manage customers in their boutique" 
ON customers 
FOR ALL 
TO authenticated 
USING (
  boutique_id IN (
    SELECT boutique_id 
    FROM boutique_users 
    WHERE user_id = auth.uid()
  )
) 
WITH CHECK (
  boutique_id IN (
    SELECT boutique_id 
    FROM boutique_users 
    WHERE user_id = auth.uid()
  )
);

-- Measurements policies
CREATE POLICY "Users can manage measurements for customers in their boutique" 
ON measurements 
FOR ALL 
TO authenticated 
USING (
  customer_id IN (
    SELECT id 
    FROM customers 
    WHERE boutique_id IN (
      SELECT boutique_id 
      FROM boutique_users 
      WHERE user_id = auth.uid()
    )
  )
) 
WITH CHECK (
  customer_id IN (
    SELECT id 
    FROM customers 
    WHERE boutique_id IN (
      SELECT boutique_id 
      FROM boutique_users 
      WHERE user_id = auth.uid()
    )
  )
);

-- Scribbles policies
CREATE POLICY "Users can manage scribbles for customers in their boutique" 
ON scribbles 
FOR ALL 
TO authenticated 
USING (
  customer_id IN (
    SELECT id 
    FROM customers 
    WHERE boutique_id IN (
      SELECT boutique_id 
      FROM boutique_users 
      WHERE user_id = auth.uid()
    )
  )
) 
WITH CHECK (
  customer_id IN (
    SELECT id 
    FROM customers 
    WHERE boutique_id IN (
      SELECT boutique_id 
      FROM boutique_users 
      WHERE user_id = auth.uid()
    )
  )
);

-- Reference Photos policies
CREATE POLICY "Users can manage reference photos for customers in their boutique" 
ON reference_photos 
FOR ALL 
TO authenticated 
USING (
  customer_id IN (
    SELECT id 
    FROM customers 
    WHERE boutique_id IN (
      SELECT boutique_id 
      FROM boutique_users 
      WHERE user_id = auth.uid()
    )
  )
) 
WITH CHECK (
  customer_id IN (
    SELECT id 
    FROM customers 
    WHERE boutique_id IN (
      SELECT boutique_id 
      FROM boutique_users 
      WHERE user_id = auth.uid()
    )
  )
);

-- 10. Database Triggers for Multi-Tenant automation

-- Trigger for automatically assigning new users to their new boutique based on signup metadata
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_boutique_name TEXT;
  v_boutique_id UUID;
BEGIN
  -- Extract boutique name from user metadata, fallback to 'My Boutique' if missing
  v_boutique_name := COALESCE(new.raw_user_meta_data ->> 'boutique_name', 'My Boutique');

  -- Create the new boutique
  INSERT INTO public.boutiques (name)
  VALUES (v_boutique_name)
  RETURNING id INTO v_boutique_id;

  -- Create the boutique user mapping
  INSERT INTO public.boutique_users (user_id, boutique_id)
  VALUES (new.id, v_boutique_id);

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate signup trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- Trigger for automatically setting boutique_id on new customer inserts based on user's boutique assignment
CREATE OR REPLACE FUNCTION public.set_customer_boutique_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.boutique_id IS NULL THEN
    NEW.boutique_id := (
      SELECT boutique_id 
      FROM public.boutique_users 
      WHERE user_id = auth.uid()
    );
  END IF;
  
  -- If boutique_id is still null, raise an exception (user not assigned to any boutique)
  IF NEW.boutique_id IS NULL THEN
    RAISE EXCEPTION 'Authenticated user is not assigned to a boutique.';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate customer insert trigger
DROP TRIGGER IF EXISTS on_customer_insert ON public.customers;
CREATE TRIGGER on_customer_insert
  BEFORE INSERT ON public.customers
  FOR EACH ROW EXECUTE FUNCTION public.set_customer_boutique_id();

COMMIT;
