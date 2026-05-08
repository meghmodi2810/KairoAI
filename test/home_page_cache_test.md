# Home Page Cache Test - Manual Testing Guide

## Test Objective
Verify that the home page caching implementation works correctly and loads instantly when navigating to the home page with cached data.

## Prerequisites
- App must be running on a device or emulator
- User must be logged in
- Network connection available

## Test Procedure

### Test 1: Initial Load (Cache Miss)
**Expected Behavior:** First load fetches fresh data and caches it

1. **Clear app data** (to ensure no cache exists)
   - Android: Settings > Apps > KairoAI > Storage > Clear Data
   - iOS: Uninstall and reinstall the app

2. **Launch the app and log in**

3. **Navigate to home page**
   - Observe: Skeleton loader should appear briefly
   - Observe: Data loads from network
   - Measure: Load time (should be < 500ms for fresh data)

4. **Verify all data displays correctly:**
   - User greeting and name
   - XP badge
   - Stats row (Streak, Gems, Coins)
   - Continue Learning card (if applicable)
   - Daily Goal section
   - Featured Categories list

**Result:** ✓ Pass / ✗ Fail
**Notes:**

---

### Test 2: Cached Load (Cache Hit)
**Expected Behavior:** Second load uses cached data and loads instantly

1. **From home page, navigate away**
   - Tap on a category or profile page
   - Wait 2-3 seconds

2. **Navigate back to home page**
   - Use back button or bottom navigation

3. **Observe loading behavior:**
   - ✓ No skeleton loader should appear
   - ✓ Content displays immediately (< 100ms)
   - ✓ No visible flicker
   - ✓ No loading spinner

4. **Verify all data displays correctly:**
   - All sections render instantly
   - Data matches previous view

**Result:** ✓ Pass / ✗ Fail
**Load Time:** _____ ms
**Notes:**

---

### Test 3: Background Refresh
**Expected Behavior:** Cached data displays immediately, fresh data loads in background

1. **With cache valid, navigate to home page**

2. **Observe:**
   - Cached data displays instantly
   - No visible loading indicators
   - Data may update silently if changes occurred

3. **Make a change in another part of the app:**
   - Complete a lesson or earn XP
   - Navigate back to home page

4. **Verify:**
   - Page loads instantly with cached data
   - Updated data appears after background refresh

**Result:** ✓ Pass / ✗ Fail
**Notes:**

---

### Test 4: Cache Expiration
**Expected Behavior:** After 5 minutes, cache expires and fresh data is fetched

1. **Navigate to home page (cache should be populated)**

2. **Wait 5+ minutes** (or modify _cacheValidity to 10 seconds for faster testing)

3. **Navigate away and back to home page**

4. **Observe:**
   - Skeleton loader may appear briefly
   - Fresh data is fetched from network
   - Cache is updated with new data

**Result:** ✓ Pass / ✗ Fail
**Notes:**

---

### Test 5: Pull-to-Refresh
**Expected Behavior:** Manual refresh fetches fresh data and updates cache

1. **Navigate to home page with cached data**

2. **Pull down to trigger refresh**

3. **Observe:**
   - Refresh indicator appears
   - Fresh data is fetched
   - Cache is updated
   - UI updates with new data

**Result:** ✓ Pass / ✗ Fail
**Notes:**

---

### Test 6: Multiple Navigation Cycles
**Expected Behavior:** Cache persists across multiple navigation cycles

1. **Navigate to home page** (cache populated)

2. **Navigate away and back 5 times rapidly**

3. **Observe each return to home page:**
   - ✓ Instant load every time
   - ✓ No flicker
   - ✓ Consistent data
   - ✓ No loading indicators

**Result:** ✓ Pass / ✗ Fail
**Notes:**

---

### Test 7: Network Failure with Cache
**Expected Behavior:** Cached data displays even if network fails

1. **Navigate to home page** (cache populated)

2. **Enable airplane mode**

3. **Navigate away and back to home page**

4. **Observe:**
   - Cached data displays instantly
   - No error messages
   - App remains functional with cached data

**Result:** ✓ Pass / ✗ Fail
**Notes:**

---

### Test 8: Performance Measurement
**Expected Behavior:** Load times meet performance targets

1. **Use Flutter DevTools Timeline**

2. **Measure first load (cache miss):**
   - Target: < 500ms

3. **Measure cached load (cache hit):**
   - Target: < 100ms

4. **Record measurements:**
   - First load: _____ ms
   - Cached load: _____ ms
   - Frame rate: _____ fps (target: 60fps)

**Result:** ✓ Pass / ✗ Fail
**Notes:**

---

## Performance Targets

| Metric | Target | Actual | Pass/Fail |
|--------|--------|--------|-----------|
| Initial render (cached) | < 100ms | _____ ms | _____ |
| Initial render (fresh) | < 500ms | _____ ms | _____ |
| No visible flicker | Yes | _____ | _____ |
| Cache validity | 5 minutes | _____ | _____ |
| Background refresh | Works | _____ | _____ |

---

## Test Summary

**Total Tests:** 8
**Passed:** _____
**Failed:** _____
**Overall Result:** ✓ Pass / ✗ Fail

**Tester Name:** _____________________
**Test Date:** _____________________
**Device/Emulator:** _____________________
**OS Version:** _____________________

---

## Issues Found

| Issue # | Description | Severity | Status |
|---------|-------------|----------|--------|
| 1 | | | |
| 2 | | | |
| 3 | | | |

---

## Additional Notes

