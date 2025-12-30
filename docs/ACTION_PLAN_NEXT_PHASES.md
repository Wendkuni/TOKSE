# 🎯 Action Plan - Post-Migration Testing & Future Features

## PHASE 1: Immediate Testing (Before Next Session)
**Timeline**: Today
**Blocker**: Database migration must be executed first

### Task 1.1: Execute Database Migration ⚠️ CRITICAL
- [ ] Go to Supabase dashboard
- [ ] Open SQL Editor
- [ ] Copy SQL from `MIGRATION_PROFILE_UPDATE.sql`
- [ ] Execute and verify success
- [ ] Check users table has new columns

### Task 1.2: Test Signup Flow
- [ ] Signup with: nom, prenom, phone, CNIB
- [ ] Verify CNIB is saved to database
- [ ] Try signup again with same CNIB → should fail (UNIQUE constraint)
- [ ] Verify success message shows

### Task 1.3: Test Profile Photo
- [ ] Login with account
- [ ] Go to profile
- [ ] Edit profile
- [ ] Enter photo URL (any public image URL)
- [ ] Save
- [ ] Verify photo displays as avatar

### Task 1.4: Test CNIB in Profile
- [ ] Edit profile
- [ ] Add/edit CNIB number
- [ ] Save
- [ ] Refresh page
- [ ] Verify CNIB persists

### Task 1.5: Test Theme Toggle
- [ ] Click ☀️/🌙 button in navigation
- [ ] Verify dark mode (navy/cyan colors)
- [ ] Click again
- [ ] Verify light mode (white/blue colors)
- [ ] Test persistence across app restarts

---

## PHASE 2: Feature Polish (Session 2)
**Timeline**: Next session
**Focus**: Make features more user-friendly

### Task 2.1: CNIB Format Validation
**File**: `src/services/auth.ts`
**Changes**:
```typescript
// Add validation function
function isValidCNIB(cnib: string): boolean {
  // Accept formats:
  // - Senegal CNIB: 13 digits (e.g., 1234567890123)
  // - Passport: alphanumeric (e.g., AB123456)
  // - ID: any 5+ characters
  return cnib.length >= 5 && cnib.length <= 20;
}
```

### Task 2.2: Profile Completeness Indicator
**File**: `app/profile.tsx`
**Changes**:
- Add progress bar showing profile completeness
- Calculate: nom + prenom + phone + photo + cnib = 5/5
- Show percentage (e.g., "3/5 fields completed")
- Highlight missing fields in form

### Task 2.3: Photo Upload Feature
**Files**: `app/profile.tsx`, `src/services/storage.ts` (new)
**Changes**:
- Replace text input with image picker
- Allow camera photo or gallery selection
- Upload to Supabase Storage
- Generate public URL
- Save URL to photo_profile column

### Task 2.4: CNIB Verification Badge
**File**: `app/profile.tsx`
**Changes**:
- Add "verified" badge if CNIB provided
- Show verification date
- Add "Verify" button → opens verification modal

---

## PHASE 3: Security Enhancements (Session 3)
**Timeline**: Future session
**Focus**: Protect user data

### Task 3.1: CNIB Admin Verification
**Files**: `admin-dashboard/AdminDashboard.jsx`, `src/services/auth.ts`
**Changes**:
- Admin dashboard shows pending CNIB verifications
- Admin can approve/reject with notes
- User gets notification when verified
- Add `cnib_verified` column to users table

### Task 3.2: Photo Moderation
**File**: `admin-dashboard/AdminDashboard.jsx`
**Changes**:
- Admin can flag inappropriate photos
- Photos can be auto-scanned with moderation API
- Flagged photos require re-upload

### Task 3.3: Duplicate Account Detection
**File**: `src/services/auth.ts`
**Changes**:
- On signup, check if CNIB already exists
- Check if phone already exists
- Prevent duplicate accounts

---

## PHASE 4: User Experience (Session 4+)
**Timeline**: Later sessions
**Focus**: Better UX

### Task 4.1: Onboarding Flow
**File**: `app/signup.tsx`
**Changes**:
- Add step indicator (1/3, 2/3, 3/3)
- Smooth transitions between steps
- Save draft locally (AsyncStorage)
- Allow resume from where user left off

### Task 4.2: Profile Photo Gallery
**File**: `app/profile.tsx`
**Changes**:
- Allow multiple photos
- Show gallery in profile view
- Let users pick which is "main" photo
- Add captions to photos

### Task 4.3: Social Verification
**File**: `app/profile.tsx`
**Changes**:
- Link to social media profiles
- Show verification badges
- Add reputation score

### Task 4.4: Export/Backup Profile
**File**: `app/profile.tsx`
**Changes**:
- Allow PDF export of profile
- Allow QR code for profile sharing
- Allow account backup

---

## PHASE 5: Analytics & Reporting (Session 5+)
**Timeline**: Mature version

### Task 5.1: Profile Insights
**Files**: `app/profile.tsx`, `src/services/analytics.ts` (new)
**Changes**:
- Show profile view count
- Show engagement stats
- Show popular signalements

### Task 5.2: Admin Analytics
**File**: `admin-dashboard/AdminDashboard.jsx`
**Changes**:
- Dashboard stats: total verified profiles, pending verifications
- Verification rate trends
- Photo upload trends

---

## DEPENDENCIES & PRIORITIES

```
Priority 1 (MUST DO):
├── Database migration
├── Signup/profile CNIB field
└── Profile photo display

Priority 2 (SHOULD DO):
├── CNIB validation
├── Photo upload feature
└── Profile completeness indicator

Priority 3 (NICE TO HAVE):
├── Admin CNIB verification
├── Photo moderation
└── Onboarding flow

Priority 4 (FUTURE):
├── Social verification
├── Analytics
└── Advanced features
```

---

## RISK ASSESSMENT

| Risk | Severity | Mitigation |
|------|----------|-----------|
| CNIB not unique in legacy data | HIGH | Check existing data for duplicates before migration |
| Photo upload fails silently | MEDIUM | Add error handling and user feedback |
| Migration rollback needed | LOW | Keep backup of migration SQL, test on staging first |
| Users lose data on form error | MEDIUM | Save form state to AsyncStorage |
| Theme colors not persisting | LOW | Verify AsyncStorage is working |

---

## ROLLBACK PLAN

If migration fails or new features cause issues:

### Option 1: Remove Columns
```sql
ALTER TABLE users DROP COLUMN IF EXISTS photo_profile;
ALTER TABLE users DROP COLUMN IF EXISTS cnib;
```

### Option 2: Quick Rollback
1. Revert code commits
2. Clear app cache
3. Execute rollback SQL

### Option 3: Data Recovery
1. Export users table before migration
2. Keep backup CSV of all data
3. Can restore if needed

---

## SUCCESS METRICS

After each phase, measure:

| Metric | Target | Current |
|--------|--------|---------|
| Signup success rate | >95% | TBD |
| Profile photo adoption | >50% of users | TBD |
| CNIB verification rate | >60% | TBD |
| Theme toggle usage | >80% | TBD |
| Zero errors on signup | 100% | TBD |

---

## TIMELINE ESTIMATE

```
Phase 1 (Today):        1-2 hours
Phase 2 (Next session):   2-3 hours
Phase 3 (Later):         3-4 hours
Phase 4 (Future):        4-5 hours
Phase 5+ (Mature):       Ongoing
```

---

## RESOURCES NEEDED

1. **Supabase Access**: SQL editor + Storage
2. **Image Service**: URL for photo hosting (or Supabase Storage)
3. **Testing Device**: Mobile app for Expo testing
4. **Documentation**: Keep docs updated with new features

---

## CHECKPOINTS

- [ ] Phase 1: All tests passing
- [ ] Phase 2: Features working with validation
- [ ] Phase 3: Security measures in place
- [ ] Phase 4: UX feels smooth and polished
- [ ] Phase 5: Analytics visible and useful

---

**Last Updated**: November 13, 2025
**Status**: Ready to execute
**Next Action**: Execute database migration
