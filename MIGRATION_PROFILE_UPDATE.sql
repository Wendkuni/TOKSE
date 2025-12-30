-- Migration: Add photo_profile and cnib fields to users table
-- Date: November 13, 2025

-- Add new columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS photo_profile TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS cnib TEXT UNIQUE;

-- Add comment for cnib field
COMMENT ON COLUMN users.photo_profile IS 'URL or path to user profile photo';
COMMENT ON COLUMN users.cnib IS 'Unique identifier: CNIB, Passport, or ID number - for citizen verification';

-- Create index on cnib for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_cnib ON users(cnib);

-- Update existing users with default null values (already done by ALTER ADD COLUMN)
-- To execute: Run this migration in Supabase SQL editor
