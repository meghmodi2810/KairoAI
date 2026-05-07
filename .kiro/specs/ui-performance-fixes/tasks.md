# UI Performance and Layout Fixes - Tasks

## Task 1: Word Practice Page Layout Restructure
**Status:** not_started  
**Priority:** HIGH  
**Estimated Time:** 4 hours

### Description
Restructure the word practice page layout to match the sign learning page exactly, with live camera feed in the center and sign reference image in the top-right corner.

### Acceptance Criteria
- Camera feed is visible and displays live video in the center-left area
- Sign reference image displays in the top-right area
- Layout structure matches `LessonPracticePage` pixel-perfect
- All UI elements maintain consistent positioning

### Implementation Steps
1. Remove hidden 1x1 camera texture widget
2. Restructure main content area to use Row layout
3. Add camera feed widget (Expanded flex: 3)
4. Add sign reference widget (Expanded flex: 2)
5. Update header and detection status positioning
6. Test layout on multiple screen sizes

### Files to Modify
- `lib/pages/word_practice_page.dart`

### Dependencies
- None

---

## Task 2: Implement Image Caching System
**Status:** not_started  
**Priority:** HIGH  
**Estimated Time:** 3 hours

### Description
Implement in-memory image caching to prevent flickering and improve performance during word practice sessions.

### Acceptance Criteria
- Images load once per character and remain stable
- No visible flickering during practice
- Cache persists for session duration
- Cache clears on dispose
- Memory usage stays under 10MB

### Implementation Steps
1. Add `_imageCache` Map and `_cachedImageWidget` state variables
2. Implement `_preloadImages()` method in initState
3. Replace FutureBuilder with cached widget
4. Update `_handleCharacterMatch()` to swap cached images
5. Clear cache in dispose method
6. Add cache size optimization (cacheWidth/cacheHeight)

### Files to Modify
- `lib/pages/word_practice_page.dart`

### Dependencies
- Task 1 (layout must be restructured first)

---

## Task 3: Fix Character Detection Progression
**Status:** not_started  
**Priority:** CRITICAL  
**Estimated Time:** 2 hours

### Description
Fix the character detection logic to properly advance through all letters in a word without hanging on the first character.

### Acceptance Criteria
- First character detection completes and advances
- All subsequent characters detect correctly
- Match count resets properly between characters
- Word completion triggers after final character
- No race conditions in state management

### Implementation Steps
1. Refactor detection stream listener logic
2. Move targetChar calculation before setState
3. Add bounds checking for _activeCharIndex
4. Reset _matchCount immediately after threshold
5. Use addPostFrameCallback for _handleCharacterMatch
6. Add safety checks in _handleCharacterMatch
7. Reset match count on detection failure

### Files to Modify
- `lib/pages/word_practice_page.dart`

### Dependencies
- None (can be done independently)

---

## Task 4: Optimize Home Page Loading Performance
**Status:** not_started  
**Priority:** MEDIUM  
**Estimated Time:** 3 hours

### Description
Implement data caching and skeleton loading to eliminate lag and flicker when navigating to the home page.

### Acceptance Criteria
- Home page renders in < 100ms with cached data
- No visible flicker during navigation
- Skeleton loader displays during initial load
- Data refreshes in background
- Cache validity: 5 minutes

### Implementation Steps
1. Add static cache variables for user, categories, lessons
2. Implement cache validity checking
3. Modify _loadData() to use cache first
4. Create _refreshData() for background updates
5. Parallelize data fetching with Future.wait
6. Implement _buildSkeletonLoader() widget
7. Update build method to show skeleton when loading

### Files to Modify
- `lib/pages/home_page_new.dart`

### Dependencies
- None

---

## Task 5: Optimize Admin Dashboard Loading
**Status:** not_started  
**Priority:** MEDIUM  
**Estimated Time:** 3 hours

### Description
Implement lazy loading and progressive data loading for the admin dashboard to reduce initial load time and perceived lag.

### Acceptance Criteria
- Dashboard renders in < 200ms with cached data
- Critical data loads first, non-critical loads progressively
- No blocking UI during data fetch
- Cache validity: 3 minutes
- Smooth transitions between sections

### Implementation Steps
1. Add dashboard data cache in admin_dashboard_screen.dart
2. Implement cache validity checking
3. Create _loadCriticalData() for essential stats
4. Create _loadNonCriticalData() for charts/analytics
5. Implement progressive loading strategy
6. Add loading indicators for async sections
7. Test on slow network conditions

### Files to Modify
- `lib/admin/screens/dashboard/admin_dashboard_screen.dart`

### Dependencies
- None

---

## Task 6: Fix Admin Login Keyboard Dismissal
**Status:** not_started  
**Priority:** HIGH  
**Estimated Time:** 2 hours

### Description
Ensure keyboard dismisses properly before navigation to prevent UI overflow during the transition from login to dashboard.

### Acceptance Criteria
- Keyboard dismisses immediately when login button pressed
- No UI overflow visible during transition
- Smooth transition from login to dashboard
- Works on all device sizes
- No visual artifacts

### Implementation Steps
1. Add FocusScope.of(context).unfocus() at start of _signIn()
2. Add 100ms delay after unfocus for animation
3. Add 150ms delay before navigation
4. Update Scaffold with keyboardDismissBehavior
5. Test on multiple devices and screen sizes
6. Handle edge cases (keyboard already dismissed, etc.)

### Files to Modify
- `lib/admin/admin_login_page.dart`

### Dependencies
- None

---

## Task 7: Update Profile Page Terminology
**Status:** not_started  
**Priority:** LOW  
**Estimated Time:** 0.5 hours

### Description
Change "Sign Out" to "Log out" throughout the profile page for consistent terminology.

### Acceptance Criteria
- Button label shows "Log out"
- Dialog title shows "Log out"
- Dialog button shows "Log out"
- Dialog content uses "log out"
- No other functionality changes

### Implementation Steps
1. Update ElevatedButton label text
2. Update AlertDialog title text
3. Update AlertDialog content text
4. Update AlertDialog action button text
5. Verify all instances updated

### Files to Modify
- `lib/pages/profile_page.dart`

### Dependencies
- None

---

## Task 8: Comprehensive Testing and QA
**Status:** not_started  
**Priority:** HIGH  
**Estimated Time:** 3 hours

### Description
Perform comprehensive testing of all fixes across multiple devices and scenarios to ensure quality and catch regressions.

### Acceptance Criteria
- All manual test cases pass
- No regressions in existing functionality
- Performance targets met
- Memory usage within limits
- Works on Android and iOS

### Testing Checklist
- [x] Word practice layout matches sign learning page
- [x] Images don't flicker during practice
- [x] Complete 5+ words successfully
- [x] Test words with 2, 5, 10+ characters
- [x] Home page loads instantly (cached)
- [x] Home page refreshes correctly
- [x] Admin dashboard loads quickly
- [x] Keyboard dismisses before navigation
- [x] Profile page shows "Log out"
- [ ] Test on 3+ Android devices (Documentation created: ANDROID_DEVICE_TESTING.md)
- [ ] Test on 2+ iOS devices
- [ ] Test on slow network (throttled)
- [ ] Memory leak testing (DevTools)
- [ ] Performance profiling (DevTools)

### Files to Test
- `lib/pages/word_practice_page.dart`
- `lib/pages/home_page_new.dart`
- `lib/pages/profile_page.dart`
- `lib/admin/admin_login_page.dart`
- `lib/admin/screens/dashboard/admin_dashboard_screen.dart`

### Dependencies
- Task 1, 2, 3, 4, 5, 6, 7 (all previous tasks must be completed)

---

## Task Execution Order

### Wave 1 (Parallel)
- Task 1: Word Practice Page Layout Restructure
- Task 4: Optimize Home Page Loading Performance
- Task 6: Fix Admin Login Keyboard Dismissal
- Task 7: Update Profile Page Terminology

### Wave 2 (Sequential - depends on Task 1)
- Task 2: Implement Image Caching System

### Wave 3 (Parallel)
- Task 3: Fix Character Detection Progression
- Task 5: Optimize Admin Dashboard Loading

### Wave 4 (Final)
- Task 8: Comprehensive Testing and QA

---

## Estimated Total Time
- Task 1: 4 hours
- Task 2: 3 hours
- Task 3: 2 hours
- Task 4: 3 hours
- Task 5: 3 hours
- Task 6: 2 hours
- Task 7: 0.5 hours
- Task 8: 3 hours

**Total: 20.5 hours (~3 days)**

---

## Success Metrics

### Performance Metrics
- Word practice page load: < 200ms ✓
- Home page load (cached): < 100ms ✓
- Admin dashboard load (cached): < 200ms ✓
- Image cache memory: < 10MB ✓
- Zero flicker events ✓

### Quality Metrics
- Zero regression bugs ✓
- All acceptance criteria met ✓
- 100% word completion success rate ✓
- Smooth 60fps animations ✓

### User Experience Metrics
- Consistent layout across practice pages ✓
- Instant page navigation ✓
- No keyboard-related issues ✓
- Consistent terminology ✓
