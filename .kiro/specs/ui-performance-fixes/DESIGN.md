# UI Performance and Layout Fixes - Design Document

## Overview
This design document outlines the technical approach to fix UI/UX issues in the word practice page, home page, admin dashboard, and profile page. The design focuses on minimal code changes while maximizing impact.

---

## Architecture Overview

### System Context
```
┌─────────────────────────────────────────────────────────────┐
│                     KairoAI Flutter App                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Word Practice│  │  Home Page   │  │ Admin Pages  │      │
│  │     Page     │  │              │  │              │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│         └──────────────────┼──────────────────┘              │
│                            │                                 │
│         ┌──────────────────▼──────────────────┐             │
│         │      Core Services Layer            │             │
│         ├─────────────────────────────────────┤             │
│         │ • SignImageService (Enhanced)       │             │
│         │ • SignDetectionService              │             │
│         │ • DatabaseService (Cached)          │             │
│         └─────────────────────────────────────┘             │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Design Solutions

## D1: Word Practice Page Layout Redesign

### Current State Analysis
```dart
// Current layout (INCORRECT)
Column(
  children: [
    // Hidden camera (1x1 opacity 0)
    // Header with back button and progress
    Expanded(
      child: NeoPanel(
        child: Column([
          targetChar,
          Expanded(
            child: Container(
              // IMAGE IN CENTER (WRONG)
              child: FutureBuilder<String?>(
                future: _imageService.resolveImageRefForWord(targetChar),
                builder: (context, snapshot) {
                  // Rebuilds continuously causing flicker
                }
              )
            )
          )
        ])
      )
    ),
    // Detection status at bottom
  ]
)
```

### Target State Design
```dart
// Target layout (CORRECT - matches sign learning page)
Column(
  children: [
    // Header with back button and progress
    Expanded(
      child: Row(
        children: [
          // LEFT: Live camera feed (VISIBLE)
          Expanded(
            flex: 3,
            child: Container(
              child: _detecting && _detectionService.textureId != null
                ? Texture(textureId: _detectionService.textureId!)
                : _buildCameraPlaceholder()
            )
          ),
          SizedBox(width: 10),
          // RIGHT: Sign reference image (CACHED)
          Expanded(
            flex: 2,
            child: Container(
              child: _cachedImageWidget ?? _buildSignPlaceholder()
            )
          )
        ]
      )
    ),
    // Detection status at bottom
  ]
)
```

### Implementation Strategy

#### Step 1: Add Image Caching State
```dart
class _WordPracticePageState extends State<WordPracticePage> {
  // Add new state variables
  Widget? _cachedImageWidget;
  final Map<String, Widget> _imageCache = {};
  
  // Existing state...
  int _activeCharIndex = 0;
  // ...
}
```

#### Step 2: Preload Images on Init
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _preloadImages(); // NEW
  _initialize();
}

Future<void> _preloadImages() async {
  for (final charModel in widget.wordModel.characters) {
    final char = charModel.char.toUpperCase();
    final resolvedRef = await _imageService.resolveImageRefForWord(char);
    
    if (resolvedRef != null && resolvedRef.isNotEmpty) {
      _imageCache[char] = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          resolvedRef,
          fit: BoxFit.contain,
          cacheWidth: 400,
          cacheHeight: 400,
          errorBuilder: (context, error, stackTrace) => 
            _buildSignPlaceholder(char),
        ),
      );
    }
  }
  
  // Set initial cached image
  if (mounted && widget.wordModel.characters.isNotEmpty) {
    setState(() {
      _cachedImageWidget = _imageCache[_currentTargetChar()];
    });
  }
}
```

#### Step 3: Update Layout Structure
```dart
@override
Widget build(BuildContext context) {
  // ... existing code ...
  
  return Scaffold(
    backgroundColor: AppTheme.paperCream,
    body: SafeArea(
      child: Column(
        children: [
          // Header (unchanged)
          _buildHeader(),
          
          // MAIN CONTENT AREA (CHANGED)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  // LEFT: Camera feed
                  Expanded(
                    flex: 3,
                    child: _buildCameraFeed(),
                  ),
                  const SizedBox(width: 10),
                  // RIGHT: Sign reference
                  Expanded(
                    flex: 2,
                    child: _buildSignReference(),
                  ),
                ],
              ),
            ),
          ),
          
          // Detection status (unchanged)
          if (!_isCompleted) _buildDetectionStatus(),
        ],
      ),
    ),
  );
}

Widget _buildCameraFeed() {
  return Container(
    decoration: BoxDecoration(
      color: AppTheme.paperCream,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.inkBlack, width: 3),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: _detecting && _detectionService.textureId != null
        ? Texture(textureId: _detectionService.textureId!)
        : _buildCameraPlaceholder(),
    ),
  );
}

Widget _buildSignReference() {
  return NeoPanel(
    color: AppTheme.warmWhite,
    radius: 18,
    child: Column(
      children: [
        Text(
          _currentTargetChar(),
          style: const TextStyle(
            color: AppTheme.inkBlack,
            fontSize: 46,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.paperCream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.inkBlack, width: 3),
            ),
            child: _cachedImageWidget ?? _buildSignPlaceholder(_currentTargetChar()),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.signalYellow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.inkBlack, width: 2),
          ),
          child: Text(
            'STEP ${_activeCharIndex + 1}/${widget.wordModel.characters.length}',
            style: const TextStyle(
              color: AppTheme.inkBlack,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildCameraPlaceholder() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.videocam_off_rounded,
          size: 64,
          color: AppTheme.inkBlack.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 16),
        Text(
          'Camera Initializing...',
          style: TextStyle(
            color: AppTheme.inkBlack.withValues(alpha: 0.5),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
```

#### Step 4: Update Character Transition
```dart
void _handleCharacterMatch() {
  setState(() {
    _matchCount = 0;
    _activeCharIndex++;
    
    // Update cached image for new character
    if (_activeCharIndex < widget.wordModel.characters.length) {
      final nextChar = widget.wordModel.characters[_activeCharIndex].char.toUpperCase();
      _cachedImageWidget = _imageCache[nextChar];
    }
  });

  if (_activeCharIndex >= widget.wordModel.characters.length) {
    _handleWordCompleted();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Great! Now sign ${widget.wordModel.characters[_activeCharIndex].char}'),
        backgroundColor: AppTheme.mintGreen,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
```

#### Step 5: Clear Cache on Dispose
```dart
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  _stopDetection();
  _imageCache.clear(); // Clear cache
  super.dispose();
}
```

---

## D2: Character Detection Progression Fix

### Root Cause Analysis
The issue is in the detection stream listener logic. The current code has a potential race condition where `_matchCount` increments but `_handleCharacterMatch()` may not execute properly due to state management timing.

### Current Problematic Code
```dart
_subscription = _detectionService.detectionStream.listen(
  (data) {
    if (!mounted || _isCompleted) return;
    setState(() {
      _result = data;
      _loading = false;
      _detecting = true;
    });

    final targetChar = widget.wordModel.characters[_activeCharIndex].char.toUpperCase();

    if (data.handDetected &&
        data.detectedSign.toUpperCase() == targetChar &&
        data.confidence > 0.6) {
      _matchCount++;
      if (_matchCount >= _requiredMatches) {
        _handleCharacterMatch(); // Called outside setState
      }
    }
  },
  // ...
);
```

### Fixed Code
```dart
_subscription = _detectionService.detectionStream.listen(
  (data) {
    if (!mounted || _isCompleted) return;
    
    // Get current target BEFORE setState
    final targetChar = _activeCharIndex < widget.wordModel.characters.length
      ? widget.wordModel.characters[_activeCharIndex].char.toUpperCase()
      : '';
    
    if (targetChar.isEmpty) return;
    
    setState(() {
      _result = data;
      _loading = false;
      _detecting = true;
    });

    // Check match AFTER setState completes
    if (data.handDetected &&
        data.detectedSign.toUpperCase() == targetChar &&
        data.confidence > 0.6) {
      
      // Increment match count
      _matchCount++;
      
      // Check if we've reached required matches
      if (_matchCount >= _requiredMatches) {
        // Reset match count immediately
        _matchCount = 0;
        
        // Handle character match in next frame to avoid state conflicts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isCompleted) {
            _handleCharacterMatch();
          }
        });
      }
    } else {
      // Reset match count if detection fails
      if (_matchCount > 0) {
        _matchCount = 0;
      }
    }
  },
  onError: (error) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _detecting = false;
      _matchCount = 0; // Reset on error
    });
  },
);
```

### Enhanced Character Match Handler
```dart
void _handleCharacterMatch() {
  if (_isCompleted) return; // Safety check
  
  final currentIndex = _activeCharIndex;
  final nextIndex = currentIndex + 1;
  
  setState(() {
    _activeCharIndex = nextIndex;
    
    // Update cached image for new character
    if (nextIndex < widget.wordModel.characters.length) {
      final nextChar = widget.wordModel.characters[nextIndex].char.toUpperCase();
      _cachedImageWidget = _imageCache[nextChar];
    }
  });

  if (nextIndex >= widget.wordModel.characters.length) {
    _handleWordCompleted();
  } else {
    final nextChar = widget.wordModel.characters[nextIndex].char;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Great! Now sign $nextChar'),
        backgroundColor: AppTheme.mintGreen,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
```

---

## D3: Home Page Loading Performance

### Current Issues
1. No data caching - fetches fresh data on every navigation
2. No initial data for StreamBuilder/FutureBuilder
3. Multiple Firestore queries execute sequentially
4. No loading skeletons - shows spinner instead

### Solution Architecture

#### Step 1: Add Data Caching Layer
```dart
class _HomePageState extends State<HomePage> {
  // Cache variables
  static UserModel? _cachedUser;
  static List<CategoryModel>? _cachedCategories;
  static LessonModel? _cachedContinueLesson;
  static String? _cachedContinueCategoryId;
  static DateTime? _lastCacheTime;
  
  static const Duration _cacheValidity = Duration(minutes: 5);
  
  bool get _isCacheValid {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheValidity;
  }
  
  // Existing variables...
  UserModel? _user;
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
}
```

#### Step 2: Optimize Data Loading
```dart
@override
void initState() {
  super.initState();
  _loadData();
}

Future<void> _loadData() async {
  // Use cached data immediately if valid
  if (_isCacheValid && _cachedUser != null) {
    setState(() {
      _user = _cachedUser;
      _categories = _cachedCategories ?? [];
      _continueLesson = _cachedContinueLesson;
      _continueCategoryId = _cachedContinueCategoryId;
      _isLoading = false;
    });
    
    // Refresh in background
    _refreshData();
    return;
  }
  
  // Load fresh data
  await _refreshData();
}

Future<void> _refreshData() async {
  try {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _db.createUserDocument(currentUser);
    }

    // Parallel data fetching
    final results = await Future.wait([
      _db.getCurrentUser(),
      _db.getCategories(),
    ]);

    final user = results[0] as UserModel?;
    final categories = results[1] as List<CategoryModel>;

    // Find continue lesson (optimized)
    LessonModel? nextLesson;
    String? nextCategoryId;

    for (final category in categories) {
      if (category.isLocked) continue;
      final lessons = await _db.getLessons(category.id);
      for (final lesson in lessons) {
        final progress = await _db.getLessonProgress(lesson.id);
        if (progress == null || progress.status != 'completed') {
          nextLesson = lesson;
          nextCategoryId = category.id;
          break;
        }
      }
      if (nextLesson != null) break;
    }

    // Update cache
    _cachedUser = user;
    _cachedCategories = categories;
    _cachedContinueLesson = nextLesson;
    _cachedContinueCategoryId = nextCategoryId;
    _lastCacheTime = DateTime.now();

    if (!mounted) return;
    setState(() {
      _user = user;
      _categories = categories;
      _continueLesson = nextLesson;
      _continueCategoryId = nextCategoryId;
      _isLoading = false;
    });
  } catch (e) {
    debugPrint('Error loading home data: $e');
    if (!mounted) return;
    setState(() => _isLoading = false);
  }
}
```

#### Step 3: Add Skeleton Loading
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppTheme.paperCream,
    body: SafeArea(
      child: RefreshIndicator(
        color: AppTheme.cobaltBlue,
        onRefresh: _refreshData,
        child: _isLoading && _user == null
          ? _buildSkeletonLoader()
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 14),
                  _statsRow(),
                  if (_continueLesson != null) ...[
                    const SizedBox(height: 18),
                    _continueCard(),
                  ],
                  const SizedBox(height: 18),
                  _dailyGoalSection(),
                  const SizedBox(height: 20),
                  const Text(
                    'FEATURED CATEGORIES',
                    style: TextStyle(
                      color: AppTheme.inkBlack,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _categoriesList(),
                ],
              ),
            ),
      ),
    ),
  );
}

Widget _buildSkeletonLoader() {
  return SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSkeletonBox(height: 60, width: double.infinity),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildSkeletonBox(height: 100)),
            const SizedBox(width: 8),
            Expanded(child: _buildSkeletonBox(height: 100)),
            const SizedBox(width: 8),
            Expanded(child: _buildSkeletonBox(height: 100)),
          ],
        ),
        const SizedBox(height: 18),
        _buildSkeletonBox(height: 120, width: double.infinity),
        const SizedBox(height: 18),
        _buildSkeletonBox(height: 150, width: double.infinity),
      ],
    ),
  );
}

Widget _buildSkeletonBox({required double height, double? width}) {
  return Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: AppTheme.warmWhite.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.inkBlack.withValues(alpha: 0.1), width: 2),
    ),
  );
}
```

---

## D4: Admin Dashboard Loading Performance

### Current Issues
1. All dashboard widgets load simultaneously
2. No progressive loading
3. Heavy initial data queries
4. No caching mechanism

### Solution: Lazy Loading with Caching

#### Step 1: Add Dashboard Data Cache
```dart
// In admin_dashboard_screen.dart
class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Cache
  static Map<String, dynamic>? _cachedDashboardData;
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidity = Duration(minutes: 3);
  
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  
  bool get _isCacheValid {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheValidity;
  }
}
```

#### Step 2: Implement Progressive Loading
```dart
@override
void initState() {
  super.initState();
  _loadDashboard();
}

Future<void> _loadDashboard() async {
  // Use cache immediately if valid
  if (_isCacheValid && _cachedDashboardData != null) {
    setState(() {
      _dashboardData = Map.from(_cachedDashboardData!);
      _isLoading = false;
    });
    
    // Refresh in background
    _refreshDashboard();
    return;
  }
  
  // Load fresh data
  await _refreshDashboard();
}

Future<void> _refreshDashboard() async {
  try {
    // Load critical data first
    final criticalData = await _loadCriticalData();
    
    if (mounted) {
      setState(() {
        _dashboardData = criticalData;
        _isLoading = false;
      });
    }
    
    // Load non-critical data progressively
    await _loadNonCriticalData();
    
    // Update cache
    _cachedDashboardData = Map.from(_dashboardData);
    _lastCacheTime = DateTime.now();
    
  } catch (e) {
    debugPrint('Error loading dashboard: $e');
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

Future<Map<String, dynamic>> _loadCriticalData() async {
  // Load only essential stats
  final results = await Future.wait([
    _db.getTotalUsers(),
    _db.getTotalLessons(),
    _db.getTotalCategories(),
  ]);
  
  return {
    'totalUsers': results[0],
    'totalLessons': results[1],
    'totalCategories': results[2],
  };
}

Future<void> _loadNonCriticalData() async {
  // Load charts and detailed stats progressively
  final recentActivity = await _db.getRecentActivity();
  final analytics = await _db.getAnalyticsSummary();
  
  if (mounted) {
    setState(() {
      _dashboardData['recentActivity'] = recentActivity;
      _dashboardData['analytics'] = analytics;
    });
  }
}
```

---

## D5: Admin Login Keyboard Dismissal

### Root Cause
Navigation occurs before keyboard dismissal animation completes, causing UI overflow during transition.

### Solution

#### Step 1: Dismiss Keyboard Before Navigation
```dart
Future<void> _signIn() async {
  if (!_formKey.currentState!.validate()) return;
  
  // CRITICAL: Dismiss keyboard FIRST
  FocusScope.of(context).unfocus();
  
  // Small delay to let keyboard animation start
  await Future.delayed(const Duration(milliseconds: 100));
  
  setState(() => _isLoading = true);

  try {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (userCredential.user == null) throw Exception('Auth failed');
    final isAdmin = await _adminDbService.isAdmin();

    if (!isAdmin) {
      await _auth.signOut();
      _showStatus('ACCESS DENIED. ADMIN ONLY.', isError: true);
      return;
    }

    await _adminDbService.updateAdminLastLogin();
    
    // Additional delay to ensure keyboard is fully dismissed
    await Future.delayed(const Duration(milliseconds: 150));
    
    if (mounted) {
      final admin = AdminModel(
        id: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        displayName: 'Admin',
        role: 'admin',
        permissions: [],
        isActive: true,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      // Navigate after keyboard is dismissed
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminShell(admin: admin)),
      );
    }
  } catch (e) {
    _showStatus('LOGIN FAILED. CHECK CREDENTIALS.', isError: true);
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

#### Step 2: Update Scaffold Configuration
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppTheme.charcoalNight,
    resizeToAvoidBottomInset: true, // Allow resize but handle gracefully
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                // ... existing content
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
```

---

## D6: Profile Page Terminology Fix

### Simple Text Replacement

```dart
// In profile_page.dart

// Change button label
ElevatedButton.icon(
  // ... existing properties
  icon: const Icon(Icons.logout_rounded),
  label: const Text('Log out'), // Changed from 'Sign Out'
)

// Change dialog title
AlertDialog(
  // ... existing properties
  title: const Text(
    'Log out', // Changed from 'Log Out'
    style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.inkBlack),
  ),
  content: const Text(
    'Are you sure you want to log out?', // Changed from 'log out?'
    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.inkBlack),
  ),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context, false),
      child: const Text('Cancel', style: TextStyle(color: AppTheme.inkBlack, fontWeight: FontWeight.bold)),
    ),
    ElevatedButton(
      onPressed: () => Navigator.pop(context, true),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.punchRed,
        foregroundColor: Colors.white,
      ),
      child: const Text('Log out', style: TextStyle(fontWeight: FontWeight.bold)), // Changed from 'Log Out'
    ),
  ],
)
```

---

## Implementation Plan

### Phase 1: Critical Fixes (Day 1)
1. **Word Practice Layout** (D1) - 4 hours
   - Implement image caching
   - Restructure layout to match sign learning page
   - Test on multiple devices

2. **Character Detection Fix** (D2) - 2 hours
   - Fix detection stream logic
   - Add safety checks
   - Test word completion flow

### Phase 2: Performance Optimizations (Day 2)
3. **Home Page Performance** (D3) - 3 hours
   - Implement data caching
   - Add skeleton loaders
   - Optimize queries

4. **Admin Dashboard Performance** (D4) - 3 hours
   - Implement lazy loading
   - Add progressive data loading
   - Test on slow connections

### Phase 3: Polish (Day 3)
5. **Keyboard Dismissal** (D5) - 2 hours
   - Add keyboard dismissal logic
   - Test on various devices
   - Handle edge cases

6. **Terminology Fix** (D6) - 0.5 hours
   - Update text strings
   - Verify consistency

7. **Testing & QA** - 3 hours
   - Comprehensive testing
   - Bug fixes
   - Performance validation

---

## Testing Strategy

### Unit Tests
- Image caching logic
- Character detection progression
- Data caching mechanisms

### Integration Tests
- Word practice flow end-to-end
- Home page navigation
- Admin login flow

### Manual Testing Checklist
- [ ] Word practice layout matches sign learning page
- [ ] Images don't flicker during practice
- [ ] All characters in word complete successfully
- [ ] Home page loads instantly with cached data
- [ ] Admin dashboard loads progressively
- [ ] Keyboard dismisses before navigation
- [ ] Profile page shows "Log out" consistently
- [ ] Test on Android (3+ devices)
- [ ] Test on iOS (2+ devices)
- [ ] Test on slow network
- [ ] Test with large words (10+ characters)
- [ ] Memory leak testing

---

## Performance Targets

### Load Times
- Word practice page: < 200ms
- Home page (cached): < 100ms
- Home page (fresh): < 500ms
- Admin dashboard (cached): < 200ms
- Admin dashboard (fresh): < 800ms

### Memory Usage
- Image cache: < 10MB per session
- Data cache: < 5MB
- Total increase: < 20MB

### Frame Rate
- Maintain 60fps during all transitions
- No dropped frames during detection
- Smooth animations throughout

---

## Rollback Plan

If critical issues are discovered:

1. **Immediate Rollback**
   - Revert to previous commit
   - Deploy hotfix if in production

2. **Partial Rollback**
   - Disable image caching (use FutureBuilder)
   - Disable data caching (fetch fresh)
   - Keep layout changes

3. **Feature Flags**
   - Add flags for each optimization
   - Enable/disable remotely if needed

---

## Monitoring & Metrics

### Key Metrics to Track
- Page load times (Firebase Performance)
- Memory usage (DevTools)
- Crash rate (Firebase Crashlytics)
- User completion rates
- Error rates

### Success Criteria
- Zero increase in crash rate
- 50% reduction in load times
- 90% reduction in flicker reports
- 100% word completion success rate

---

## Documentation Updates

### Code Documentation
- Add inline comments for caching logic
- Document image preloading strategy
- Explain detection stream fixes

### User Documentation
- No user-facing documentation needed
- Internal testing guide updates

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-01-XX | Kiro AI | Initial design document |
