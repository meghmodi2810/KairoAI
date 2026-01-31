# KairoAI - Complete Project Context Document

> **Purpose:** This document serves as a comprehensive reference for understanding the KairoAI project. It provides complete context for developers, AI assistants, and stakeholders to understand the project scope, architecture, and specifications.

---

## Table of Contents

1. [Project Definition](#1-project-definition)
2. [Project Scope](#2-project-scope)
3. [System Architecture & Logic](#3-system-architecture--logic)
4. [Functional Requirements](#4-functional-requirements)
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [Database Schema](#6-database-schema)
7. [Technology Stack](#7-technology-stack)
8. [Screen Flow](#8-screen-flow)
9. [Gamification System](#9-gamification-system)
10. [Quick Reference](#10-quick-reference)

---

# 1. Project Definition

## 1.1 What is KairoAI?

**KairoAI** is an Indian Sign Language (ISL) learning mobile application designed specifically for children aged 6-14. The app uses real-time AI-powered hand gesture detection via the device camera to teach ISL alphabets, numbers, and words, providing instant visual feedback to learners.

## 1.2 Problem Statement

- Lack of interactive, child-friendly ISL learning tools
- Traditional methods don't provide real-time feedback
- No instant validation if the learner is making correct signs
- Limited accessibility to quality ISL education

## 1.3 Solution

A mobile app that:
- Shows the user what sign to make
- Detects their hand position using camera + AI
- Validates if they're making the correct sign
- Provides instant feedback (success/try again)

## 1.4 Target Users

| User Type | Description |
|-----------|-------------|
| **Primary** | Children aged 6-14 learning ISL |
| **Secondary** | Parents and educators teaching ISL |
| **Tertiary** | Anyone interested in learning ISL |

## 1.5 Core Innovation

Combines three technologies:
- **Flutter** for cross-platform UI
- **MediaPipe** for hand landmark detection (21 points)
- **TensorFlow Lite** for sign language classification

---

# 2. Project Scope

## 2.1 What is INCLUDED

### Features In Scope

| Module | Features |
|--------|----------|
| **Authentication** | Email/Password signup, Google Sign-In, Password reset |
| **Onboarding** | First-time user setup, Learning goal selection, Daily practice duration |
| **Learning System** | Categorized lessons (Alphabets, Numbers, Greetings, etc.), Step-by-step sign instructions, Images/GIFs/Videos for each sign |
| **Practice Mode** | Real-time camera-based sign detection, Visual feedback (correct/incorrect), Confidence score display |
| **Quiz Mode** | Random sign challenges, Accuracy tracking, Timed quizzes |
| **Gamification** | XP & Levels, Gems & Coins, Daily streaks, Achievements/Badges, Leaderboards |
| **Progress Tracking** | Lesson completion status, Signs learned count, Practice time tracking |
| **Daily Insights** | Daily tips, ISL fun facts, Motivational quotes |
| **Profile** | User stats, Settings, Logout |

### Content In Scope

| Category | Content |
|----------|---------|
| **Alphabets** | ISL A-Z (26 signs) |
| **Numbers** | 1-20 initially (expandable to 100) |
| **Greetings** | Hello, Goodbye, Thank you, Sorry, Please |
| **Basic Words** | Family, Emotions, Colors, Animals, Food |

### Platforms In Scope

- **Android** (API 26+, Android 8.0 Oreo+) - Primary
- **Tablets** (7" - 12" screens)

## 2.2 What is NOT INCLUDED

### Features Out of Scope (v1.0)

| Feature | Reason |
|---------|--------|
| **iOS Support** | Future phase - requires separate native implementation |
| **Two-hand sign detection** | Complexity - MediaPipe configured for single hand |
| **Dynamic/Motion signs** | v1.0 focuses on static signs only |
| **Word/Sentence formation** | Future feature - v1.0 covers individual signs |
| **Video calling with ISL** | Out of scope for learning app |
| **Voice-to-sign translation** | Future enhancement |
| **Sign-to-voice translation** | Future enhancement |
| **Multiplayer/Social features** | Basic leaderboard only in v1.0 |
| **Offline ML inference** | Requires pre-downloaded models (future) |
| **Regional ISL variations** | Standard ISL only in v1.0 |
| **Adult-focused content** | Child-friendly UI/content only |
| **Web version** | Mobile-only in v1.0 |
| **Paid subscriptions** | Free app in v1.0 |
| **In-app purchases** | Not included in v1.0 |
| **Parental controls** | Future enhancement |
| **Multi-language UI** | English only in v1.0 (Hindi future) |

### Technical Limitations

| Limitation | Description |
|------------|-------------|
| **Single hand only** | Detects one hand at a time |
| **Static signs** | No motion/gesture sequence detection |
| **Front camera only** | Back camera not optimized |
| **Lighting dependency** | Requires adequate lighting |
| **Processing power** | Requires mid-range device (3GB+ RAM) |

---

# 3. System Architecture & Logic

## 3.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER LAYER (Dart)                      │
│  • UI Screens (Home, Lessons, Practice, Quiz, Profile)      │
│  • State Management (Provider)                               │
│  • Firebase Integration (Auth, Firestore, Storage)          │
│  • Navigation (GoRouter)                                     │
└─────────────────────────┬───────────────────────────────────┘
                          │ Platform Channels
                          │ (MethodChannel / EventChannel)
┌─────────────────────────▼───────────────────────────────────┐
│                  KOTLIN LAYER (Android Native)               │
│  • CameraX → Capture frames at 30 FPS                       │
│  • MediaPipe → Detect hand, extract 21 landmarks            │
│  • TensorFlow Lite → Classify sign from landmarks           │
│  • Return: { letter, confidence, handDetected }             │
└─────────────────────────────────────────────────────────────┘
```

## 3.2 Sign Detection Pipeline Logic

### Step 1: Camera Capture
- CameraX captures video frames at 30 FPS
- Each frame is a 640×480 RGB bitmap
- Frame passed to MediaPipe for processing

### Step 2: Hand Detection (MediaPipe)
- Pre-trained Google model detects hand in frame
- Extracts 21 anatomical landmark points
- Each point has (x, y, z) coordinates
- Output: 63 float values (21 × 3)

### Step 3: Landmark Normalization
- Normalize coordinates relative to wrist (point 0)
- Scale to [0,1] range
- Makes model robust to hand position/size

### Step 4: Sign Classification (TensorFlow Lite)
- Custom-trained DNN model
- Input: 63 normalized landmark values
- Architecture: Dense(128) → Dense(64) → Dense(32) → Dense(26)
- Output: Probability for each letter (A-Z)
- Highest probability = predicted sign

### Step 5: Result to Flutter
- Kotlin sends result via EventChannel
- Data: { letter, confidence, handDetected, timestamp }
- Flutter updates UI based on result

## 3.3 Why This Approach?

| Approach | Pros | Cons |
|----------|------|------|
| **CNN (Image-based)** | Direct image input | Slow (100-200ms), Large model (10-50MB), Background sensitive |
| **DNN (Landmark-based) ✓** | Fast (1-5ms), Tiny model (~100KB), Background independent | Requires MediaPipe preprocessing |

**Decision:** Landmark-based DNN chosen for speed and accuracy.

## 3.4 Data Flow Logic

```
User opens Practice → Camera activates → Frames captured (30 FPS)
    ↓
Each frame → MediaPipe → Hand detected? 
    ↓ YES                    ↓ NO
Extract 21 landmarks     Show "No hand detected"
    ↓
Normalize landmarks (63 values)
    ↓
TensorFlow Lite → Classify → Get letter + confidence
    ↓
Compare with expected sign
    ↓
Match?
    ↓ YES                    ↓ NO
Show success animation   Show hint/try again
Update progress          
Award XP/Coins
```

## 3.5 Authentication Flow Logic

```
App Launch → Check Firebase Auth state
    ↓
Logged in?
    ↓ YES                    ↓ NO
Check onboarding status   Show Login Page
    ↓                           ↓
Completed?               User logs in (Email/Google)
    ↓ YES    ↓ NO              ↓
Go Home   Go Onboarding   New user?
                              ↓ YES      ↓ NO
                          Create user doc → Go Onboarding
                                         → Go Home
```

## 3.6 Progress Tracking Logic

```
User completes a sign:
1. Mark sign as completed in USER_SIGN_PROGRESS
2. Check if all signs in lesson completed
   → YES: Mark lesson as completed
   → Update USER_LESSON_PROGRESS
3. Award XP, Gems, Coins based on accuracy
4. Update USER_STATS (totalSignsLearned, xp, etc.)
5. Check achievement conditions
   → If met: Unlock achievement, notify user
6. Update LEADERBOARD entry
```

## 3.7 Streak Logic

```
User opens app:
1. Get lastStreakDate from USER_STATS
2. Compare with today's date
   → Same day: No change
   → Yesterday: Increment streakDays, update lastStreakDate
   → Older: Reset streakDays to 1, update lastStreakDate
3. Award streak bonus if milestone (7, 30, 100 days)
```

---

# 4. Functional Requirements

## 4.1 User Management

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | User can register using email/password | High |
| FR-002 | User can login using Google Sign-In | High |
| FR-003 | User can reset password via email | Medium |
| FR-004 | User can update profile information | Medium |
| FR-005 | User can set daily learning goals | Medium |
| FR-006 | System tracks user login streaks | High |

## 4.2 Onboarding

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-010 | New users complete onboarding flow | High |
| FR-011 | User selects learning goal during onboarding | High |
| FR-012 | User sets daily practice duration | Medium |
| FR-013 | App shows tutorial for first-time users | Medium |

## 4.3 Learning System

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-020 | Display categorized lessons | High |
| FR-021 | Show lesson progress within categories | High |
| FR-022 | Display sign images/GIFs/videos | High |
| FR-023 | Provide step-by-step instructions | High |
| FR-024 | Lock advanced lessons until prerequisites complete | Medium |
| FR-025 | Show estimated time for each lesson | Low |

## 4.4 Practice Mode (Camera Detection)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-030 | Access device camera for sign detection | Critical |
| FR-031 | Detect hand landmarks using MediaPipe | Critical |
| FR-032 | Classify sign using TensorFlow Lite model | Critical |
| FR-033 | Show real-time detection feedback | Critical |
| FR-034 | Display confidence score | High |
| FR-035 | Allow camera flip (front/back) | Medium |
| FR-036 | Show visual guide overlay | Medium |
| FR-037 | Provide audio feedback | Medium |

## 4.5 Quiz System

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-040 | Present random signs for user to perform | High |
| FR-041 | Validate user's sign against expected | High |
| FR-042 | Track quiz accuracy and completion time | High |
| FR-043 | Show quiz results summary | High |
| FR-044 | Award XP/coins based on performance | High |
| FR-045 | Progressive difficulty in quizzes | Medium |

## 4.6 Gamification

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-050 | Track and display gems/coins | High |
| FR-051 | Calculate and display XP and levels | High |
| FR-052 | Track daily practice streaks | High |
| FR-053 | Award achievements for milestones | Medium |
| FR-054 | Display leaderboards | Medium |
| FR-055 | Send streak reminder notifications | Low |

## 4.7 Progress & Analytics

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-070 | Track total lessons completed | High |
| FR-071 | Track total signs learned | High |
| FR-072 | Track total practice time | Medium |
| FR-073 | Show progress charts/statistics | Medium |

---

# 5. Non-Functional Requirements

## 5.1 Performance

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-001 | App startup time | < 3 seconds |
| NFR-002 | Camera frame processing | 30 FPS |
| NFR-003 | Sign detection latency | < 200ms |
| NFR-004 | API response time | < 500ms |
| NFR-005 | App size (APK) | < 100 MB |

## 5.2 Scalability

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-010 | Concurrent users | 10,000+ |
| NFR-011 | Database operations | 1M+ daily |
| NFR-012 | Media storage | 10 GB+ |

## 5.3 Reliability

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-020 | App availability | 99.9% uptime |
| NFR-021 | Crash-free sessions | > 99% |
| NFR-022 | Data backup | Daily |
| NFR-023 | Offline functionality | Lesson viewing |

## 5.4 Security

| ID | Requirement | Description |
|----|-------------|-------------|
| NFR-030 | Authentication | Firebase Auth with secure tokens |
| NFR-031 | Data encryption | TLS 1.3 for data in transit |
| NFR-032 | Database security | Firestore security rules |
| NFR-033 | Privacy | GDPR/COPPA compliant |

## 5.5 Usability

| ID | Requirement | Description |
|----|-------------|-------------|
| NFR-040 | Target age | 6-14 years (child-friendly UI) |
| NFR-041 | Language | English (Hindi future) |
| NFR-042 | Accessibility | Screen reader compatible |
| NFR-043 | Touch targets | Minimum 48x48 dp |

## 5.6 Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| Android Version | API 26 (8.0+) | API 30+ |
| RAM | 3 GB | 4 GB+ |
| Storage | 600 MB | 1 GB+ |
| Camera | Front 5 MP | Front 8 MP+ |
| Display | 5" 720p | 6"+ 1080p |
| GPU | OpenGL ES 3.0 | OpenGL ES 3.2 |

---

# 6. Database Schema

## 6.1 Normalized Tables Overview

```
USERS ─────┬──── USER_STATS
           ├──── USER_PREFERENCES
           ├──── USER_LESSON_PROGRESS ──── USER_SIGN_PROGRESS
           ├──── USER_ACHIEVEMENTS
           ├──── LEADERBOARD
           ├──── QUIZ_SESSIONS ──── QUIZ_ANSWERS
           └──── USER_ACTIVITY_LOG

CATEGORIES ──── LESSONS ──┬── SIGNS ──┬── SIGN_INSTRUCTIONS
                          │           └── SIGN_EXPECTED_LANDMARKS
                          └── LESSON_FOCUS_POINTS

ACHIEVEMENTS (standalone definition table)
DAILY_INSIGHTS (standalone)
```

## 6.2 Table Definitions

### USERS
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| user_id | VARCHAR(128) | PK | Firebase Auth UID |
| email | VARCHAR(255) | UNIQUE, NOT NULL | User's email |
| display_name | VARCHAR(100) | NOT NULL | Display name |
| photo_url | TEXT | NULL | Profile picture URL |
| created_at | TIMESTAMP | NOT NULL | Account creation |
| last_login_at | TIMESTAMP | NOT NULL | Last login |

### USER_STATS
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| user_id | VARCHAR(128) | PK, FK→USERS | User reference |
| gems | INT | DEFAULT 0 | Virtual currency |
| coins | INT | DEFAULT 0 | Virtual currency |
| xp | INT | DEFAULT 0 | Experience points |
| current_level | INT | DEFAULT 1 | User's level |
| streak_days | INT | DEFAULT 0 | Consecutive days |
| last_streak_date | DATE | NULL | Last streak update |
| total_lessons_completed | INT | DEFAULT 0 | Lessons finished |
| total_signs_learned | INT | DEFAULT 0 | Signs mastered |
| total_practice_minutes | INT | DEFAULT 0 | Practice time |

### USER_PREFERENCES
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| user_id | VARCHAR(128) | PK, FK→USERS | User reference |
| learning_goal | VARCHAR(255) | NULL | Learning objective |
| daily_goal_minutes | INT | DEFAULT 10 | Daily target |
| onboarding_completed | BOOLEAN | DEFAULT FALSE | Onboarding status |
| notifications_enabled | BOOLEAN | DEFAULT TRUE | Notification setting |

### CATEGORIES
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| category_id | VARCHAR(50) | PK | Unique identifier |
| name | VARCHAR(100) | NOT NULL | Display name |
| description | TEXT | NOT NULL | Description |
| icon_emoji | VARCHAR(10) | NOT NULL | Emoji icon |
| color | VARCHAR(7) | NOT NULL | Hex color |
| display_order | INT | NOT NULL | Sort order |
| total_lessons | INT | NOT NULL | Lesson count |
| total_signs | INT | NOT NULL | Sign count |
| is_locked | BOOLEAN | DEFAULT FALSE | Lock status |
| required_level | INT | DEFAULT 1 | Unlock level |

### LESSONS
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| lesson_id | VARCHAR(100) | PK | Unique identifier |
| category_id | VARCHAR(50) | FK→CATEGORIES | Parent category |
| unit_number | INT | NOT NULL | Unit number |
| title | VARCHAR(100) | NOT NULL | Lesson title |
| description | TEXT | NOT NULL | Description |
| display_order | INT | NOT NULL | Sort order |
| total_signs | INT | NOT NULL | Sign count |
| estimated_minutes | INT | NOT NULL | Time estimate |
| difficulty | ENUM | NOT NULL | beginner/intermediate/advanced |
| gems_reward | INT | DEFAULT 0 | Gems reward |
| coins_reward | INT | DEFAULT 0 | Coins reward |
| xp_reward | INT | DEFAULT 0 | XP reward |
| is_locked | BOOLEAN | DEFAULT FALSE | Lock status |
| required_lesson_id | VARCHAR(100) | FK→LESSONS, NULL | Prerequisite |

### SIGNS
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| sign_id | VARCHAR(100) | PK | Unique identifier |
| lesson_id | VARCHAR(100) | FK→LESSONS | Parent lesson |
| word | VARCHAR(100) | NOT NULL | English word |
| word_hindi | VARCHAR(100) | NULL | Hindi word |
| display_order | INT | NOT NULL | Sort order |
| image_url | TEXT | NULL | Static image |
| gif_url | TEXT | NULL | Animated GIF |
| video_url | TEXT | NULL | Video URL |
| description | TEXT | NOT NULL | How to perform |
| tips | TEXT | NULL | Helpful tips |
| difficulty | ENUM | NOT NULL | easy/medium/hard |

### SIGN_INSTRUCTIONS
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| instruction_id | INT | PK, AUTO_INCREMENT | Unique ID |
| sign_id | VARCHAR(100) | FK→SIGNS | Parent sign |
| step_number | INT | NOT NULL | Step order |
| instruction_text | VARCHAR(500) | NOT NULL | Instruction |

### USER_LESSON_PROGRESS
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| progress_id | INT | PK, AUTO_INCREMENT | Unique ID |
| user_id | VARCHAR(128) | FK→USERS | User reference |
| lesson_id | VARCHAR(100) | FK→LESSONS | Lesson reference |
| status | ENUM | DEFAULT 'not_started' | not_started/in_progress/completed |
| started_at | TIMESTAMP | NULL | Start time |
| completed_at | TIMESTAMP | NULL | Completion time |
| accuracy | DECIMAL(5,2) | DEFAULT 0 | Accuracy % |
| time_spent_seconds | INT | DEFAULT 0 | Time spent |
| attempts_count | INT | DEFAULT 0 | Attempts |
| gems_earned | INT | DEFAULT 0 | Gems earned |
| coins_earned | INT | DEFAULT 0 | Coins earned |
| UNIQUE | (user_id, lesson_id) | | No duplicates |

### USER_SIGN_PROGRESS
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT | PK, AUTO_INCREMENT | Unique ID |
| progress_id | INT | FK→USER_LESSON_PROGRESS | Progress ref |
| sign_id | VARCHAR(100) | FK→SIGNS | Sign reference |
| completed_at | TIMESTAMP | NOT NULL | When mastered |
| UNIQUE | (progress_id, sign_id) | | No duplicates |

### ACHIEVEMENTS
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| achievement_id | VARCHAR(50) | PK | Unique identifier |
| name | VARCHAR(100) | NOT NULL | Display name |
| description | TEXT | NOT NULL | Description |
| icon_emoji | VARCHAR(10) | NOT NULL | Emoji icon |
| type | ENUM | NOT NULL | milestone/streak/mastery |
| requirement_type | VARCHAR(50) | NOT NULL | e.g., lessons_completed |
| requirement_value | INT | NOT NULL | Value to unlock |
| gems_reward | INT | DEFAULT 0 | Gems reward |
| coins_reward | INT | DEFAULT 0 | Coins reward |
| xp_reward | INT | DEFAULT 0 | XP reward |

### USER_ACHIEVEMENTS
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT | PK, AUTO_INCREMENT | Unique ID |
| user_id | VARCHAR(128) | FK→USERS | User reference |
| achievement_id | VARCHAR(50) | FK→ACHIEVEMENTS | Achievement ref |
| unlocked_at | TIMESTAMP | NOT NULL | When unlocked |
| claimed | BOOLEAN | DEFAULT FALSE | Rewards claimed |
| UNIQUE | (user_id, achievement_id) | | No duplicates |

### LEADERBOARD
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| user_id | VARCHAR(128) | PK, FK→USERS | User reference |
| display_name | VARCHAR(100) | NOT NULL | Cached name |
| xp | INT | DEFAULT 0 | Total XP |
| level | INT | DEFAULT 1 | Current level |
| streak_days | INT | DEFAULT 0 | Current streak |
| weekly_xp | INT | DEFAULT 0 | This week's XP |
| monthly_xp | INT | DEFAULT 0 | This month's XP |
| last_updated | TIMESTAMP | NOT NULL | Last update |

### DAILY_INSIGHTS
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| insight_id | VARCHAR(50) | PK | Unique identifier |
| insight_date | DATE | UNIQUE | Date (YYYY-MM-DD) |
| title | VARCHAR(200) | NOT NULL | Title |
| message | TEXT | NOT NULL | Main content |
| tip | TEXT | NULL | Practice tip |
| fun_fact | TEXT | NULL | ISL fun fact |
| is_active | BOOLEAN | DEFAULT TRUE | Active status |

### QUIZ_SESSIONS
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| quiz_session_id | INT | PK, AUTO_INCREMENT | Unique ID |
| user_id | VARCHAR(128) | FK→USERS | User reference |
| lesson_id | VARCHAR(100) | FK→LESSONS, NULL | Related lesson |
| quiz_type | ENUM | NOT NULL | lesson/category/random |
| started_at | TIMESTAMP | NOT NULL | Start time |
| completed_at | TIMESTAMP | NULL | End time |
| total_questions | INT | NOT NULL | Question count |
| correct_answers | INT | DEFAULT 0 | Correct count |
| accuracy | DECIMAL(5,2) | DEFAULT 0 | Accuracy % |
| xp_earned | INT | DEFAULT 0 | XP earned |

### QUIZ_ANSWERS
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| quiz_answer_id | INT | PK, AUTO_INCREMENT | Unique ID |
| quiz_session_id | INT | FK→QUIZ_SESSIONS | Session ref |
| sign_id | VARCHAR(100) | FK→SIGNS | Expected sign |
| question_order | INT | NOT NULL | Order in quiz |
| detected_sign | VARCHAR(100) | NULL | What was detected |
| confidence_score | DECIMAL(5,4) | NULL | ML confidence |
| is_correct | BOOLEAN | DEFAULT FALSE | Correct or not |

---

# 7. Technology Stack

## 7.1 Frontend (Flutter/Dart)

| Technology | Version | Purpose |
|------------|---------|---------|
| Flutter | 3.16+ | UI Framework |
| Dart | 3.2+ | Programming Language |
| Provider | 6.1.1 | State Management |
| GoRouter | 13.0.0 | Navigation |
| Lottie | 3.0.0 | Animations |

## 7.2 Backend (Firebase)

| Service | Purpose |
|---------|---------|
| Firebase Auth | User authentication |
| Cloud Firestore | NoSQL database |
| Firebase Storage | Media files |
| Cloud Functions | Server-side logic |

## 7.3 Native Android (Kotlin)

| Technology | Version | Purpose |
|------------|---------|---------|
| Kotlin | 1.9+ | Native development |
| CameraX | 1.3.1 | Camera API |
| MediaPipe | 0.10.14 | Hand detection |
| TensorFlow Lite | 2.14.0 | ML inference |

## 7.4 ML Training (Python)

| Library | Purpose |
|---------|---------|
| TensorFlow 2.15 | Model training |
| MediaPipe 0.10.9 | Landmark extraction |
| OpenCV 4.8.1 | Image processing |
| NumPy, Pandas | Data manipulation |

---

# 8. Screen Flow

```
App Launch
    ↓
Auth Check ──→ Not Logged In ──→ Login Page
    ↓                               ↓
Logged In                    Sign Up / Google Sign-In
    ↓                               ↓
Onboarding Done? ──→ No ──→ Onboarding Flow
    ↓ Yes                           ↓
    ↓←──────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│           MAIN NAVIGATION               │
│  [Home] [Learn] [Quiz] [Profile]        │
└─────────────────────────────────────────┘
    ↓           ↓         ↓         ↓
 Dashboard  Categories  Quizzes   Settings
    ↓           ↓
 Insights   Lessons
              ↓
          Lesson Detail
              ↓
    ┌─────────┴─────────┐
    ↓                   ↓
Practice Mode       Quiz Mode
(Camera)            (Camera)
    ↓                   ↓
Results + Rewards   Results + Rewards
```

---

# 9. Gamification System

## 9.1 Currencies

| Currency | Earn By | Use For |
|----------|---------|---------|
| **XP** | Completing lessons, quizzes | Level progression |
| **Gems** | Achievements, daily bonus | Premium features (future) |
| **Coins** | Lesson completion, streaks | Customization (future) |

## 9.2 Level System

| Level | XP Required | Title |
|-------|-------------|-------|
| 1 | 0 | Beginner |
| 2 | 100 | Learner |
| 3 | 300 | Explorer |
| 4 | 600 | Achiever |
| 5 | 1000 | Expert |
| 6+ | +500 each | Master |

## 9.3 Achievements

| Achievement | Requirement | Reward |
|-------------|-------------|--------|
| First Steps | Complete 1 lesson | 10 gems, 50 XP |
| Week Warrior | 7-day streak | 25 gems, 100 XP |
| Alphabet Pro | Learn all A-Z | 50 gems, 200 XP |
| Perfectionist | 100% on any lesson | 15 gems, 75 XP |
| Dedicated | 100 minutes practice | 30 gems, 150 XP |

---

# 10. Quick Reference

## 10.1 Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point |
| `lib/auth_wrapper.dart` | Authentication logic |
| `lib/main_navigation.dart` | Bottom navigation |
| `lib/pages/` | All screen pages |
| `lib/services/` | Firebase services |
| `lib/models/` | Data models |
| `android/app/src/main/kotlin/` | Native ML code |

## 10.2 Firebase Collections

| Collection | Purpose |
|------------|---------|
| `users` | User profiles |
| `users/{id}/progress` | Lesson progress |
| `users/{id}/achievements` | Unlocked achievements |
| `categories` | Learning categories |
| `categories/{id}/lessons` | Lessons |
| `categories/{id}/lessons/{id}/signs` | Signs |
| `achievements` | Achievement definitions |
| `daily_insights` | Daily tips |
| `leaderboard` | User rankings |

## 10.3 Platform Channel Methods

| Method | Direction | Purpose |
|--------|-----------|---------|
| `startDetection` | Flutter → Kotlin | Start camera/ML |
| `stopDetection` | Flutter → Kotlin | Stop camera/ML |
| `onSignDetected` | Kotlin → Flutter | Detection result |

## 10.4 ML Model Info

| Property | Value |
|----------|-------|
| Input | 63 floats (21 landmarks × 3 coords) |
| Output | 26 probabilities (A-Z) |
| Architecture | Dense(128)→Dense(64)→Dense(32)→Dense(26) |
| Size | ~100 KB |
| Inference | 1-5ms |

---

## Document Info

| Property | Value |
|----------|-------|
| **Project** | KairoAI |
| **Version** | 1.0.0 |
| **Author** | Megh Modi |
| **Created** | December 18, 2025 |
| **Last Updated** | January 31, 2026 |
| **Status** | Development Phase |

---

*This document serves as the single source of truth for the KairoAI project specification.*
