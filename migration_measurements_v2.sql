-- Migration to expand measurements table for new fashion-design specs
-- Run this in the Supabase SQL Editor

BEGIN;

ALTER TABLE public.measurements 
  -- Upper body fields
  ADD COLUMN IF NOT EXISTS upper_length TEXT,
  ADD COLUMN IF NOT EXISTS upper_chest TEXT,
  ADD COLUMN IF NOT EXISTS point TEXT,
  ADD COLUMN IF NOT EXISTS upper_waist TEXT,
  ADD COLUMN IF NOT EXISTS slit TEXT,
  ADD COLUMN IF NOT EXISTS upper_hip TEXT,
  ADD COLUMN IF NOT EXISTS lower_hip TEXT,
  ADD COLUMN IF NOT EXISTS front_neck TEXT,
  ADD COLUMN IF NOT EXISTS back_neck TEXT,
  ADD COLUMN IF NOT EXISTS back_board TEXT,
  ADD COLUMN IF NOT EXISTS arm TEXT,
  ADD COLUMN IF NOT EXISTS side TEXT,
  
  -- Bottom body fields
  ADD COLUMN IF NOT EXISTS lower_length TEXT,
  ADD COLUMN IF NOT EXISTS lower_waist TEXT,
  ADD COLUMN IF NOT EXISTS bottom_hip TEXT,
  ADD COLUMN IF NOT EXISTS knee TEXT,
  ADD COLUMN IF NOT EXISTS crotch TEXT,
  ADD COLUMN IF NOT EXISTS bottom TEXT,
  
  -- Full body fields
  ADD COLUMN IF NOT EXISTS full_length TEXT,
  ADD COLUMN IF NOT EXISTS yoke TEXT;

COMMIT;
