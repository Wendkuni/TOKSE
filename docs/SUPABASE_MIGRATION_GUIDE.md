# 🗄️ Supabase Migration Guide

## Migration: Add photo_profile and cnib columns to users table

### Status: ⏳ PENDING - Must be executed before CNIB/photo features work

---

## How to Execute the Migration

### Step 1: Access Supabase Dashboard
1. Go to https://supabase.com
2. Login with your credentials
3. Select your Tokse project

### Step 2: Open SQL Editor
1. In the left sidebar, click **SQL Editor**
2. Click **New Query** button (top right)

### Step 3: Copy and Paste the Migration SQL
Copy the following SQL code:

```sql
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
```

### Step 4: Execute the Query
1. Paste the SQL into the editor
2. Click **RUN** button (or press `Ctrl+Enter`)
3. You should see a success message: `"Query executed successfully"`

### Step 5: Verify the Migration
1. Go to **Table Editor** in the left sidebar
2. Click on the **users** table
3. You should see two new columns:
   - `photo_profile` (TEXT, nullable)
   - `cnib` (TEXT, unique)

---

## What This Migration Does

### New Columns Added:

| Column | Type | Constraints | Purpose |
|--------|------|-------------|---------|
| `photo_profile` | TEXT | Nullable | Stores URL/path to user's profile photo |
| `cnib` | TEXT | UNIQUE, Nullable | Stores CNIB/Passport/ID for user verification |

### Index Created:
- `idx_users_cnib` on `cnib` column for faster lookups

---

## Features Now Available After Migration

✅ **Signup Form**: Users can enter optional CNIB/Passport number
✅ **Profile Photos**: Users can set profile photo URL in profile editor
✅ **CNIB Field**: Users can add/edit CNIB in profile editor modal
✅ **Avatar Display**: Profile shows photo if photo_profile URL provided
✅ **Uniqueness**: System ensures each CNIB is unique in database

---

## App Code Changes Made

### 1. **app/signup.tsx**
- Added CNIB input field (optional)
- Passes CNIB to `signUpWithPhone()` and `verifyOtp()`

### 2. **src/services/auth.ts**
- `signUpWithPhone(phone, nom, prenom, cnib?)` - accepts optional CNIB
- `verifyOtp(phone, token, nom, prenom, cnib?)` - passes CNIB to database
- `upsertUser(userId, phone, nom, prenom, cnib?)` - saves CNIB to users table

### 3. **app/profile.tsx**
- Interface `UserProfile` includes `photo_profile` and `cnib`
- Edit modal has TextInput fields for both
- Avatar displays image if `photo_profile` URL exists

---

## Testing After Migration

### Test 1: Signup with CNIB
1. Go to signup screen
2. Enter: nom, prenom, phone, CNIB
3. Verify CNIB is saved in database
4. Try creating another user with same CNIB → should fail (UNIQUE constraint)

### Test 2: Profile Photo
1. Edit profile
2. Enter photo URL: `https://example.com/photo.jpg`
3. Save and verify photo displays as avatar

### Test 3: Theme Toggle
1. Click ☀️/🌙 button
2. Verify dark mode (navy/cyan) vs light mode (white/blue)

---

## Troubleshooting

### Error: "column 'cnib' already exists"
- This means the migration was already run
- The `IF NOT EXISTS` clause prevents errors on re-runs

### Error: "table 'users' does not exist"
- Verify you're running the migration in the correct database
- Check that the users table exists in Supabase

### CNIB field not appearing in profile
- Ensure migration was executed successfully
- Clear app cache and restart
- Check browser DevTools console for errors

---

## Next Steps

After migration is executed:

1. ✅ Test signup with CNIB field
2. ✅ Test profile photo display
3. ✅ Test CNIB editing in profile modal
4. ✅ Test theme toggle (dark/light)
5. ⏭️ Add CNIB validation (format checking)
6. ⏭️ Add photo upload feature (currently URL-based only)
7. ⏭️ Add admin verification workflow for CNIB

---

## Quick Copy-Paste

If you just want to copy the migration SQL without reading, here it is:

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS photo_profile TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS cnib TEXT UNIQUE;
COMMENT ON COLUMN users.photo_profile IS 'URL or path to user profile photo';
COMMENT ON COLUMN users.cnib IS 'Unique identifier: CNIB, Passport, or ID number - for citizen verification';
CREATE INDEX IF NOT EXISTS idx_users_cnib ON users(cnib);
```

---

**Last Updated**: November 13, 2025
**Status**: Ready for execution
