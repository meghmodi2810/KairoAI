# KairoAI - Complete Project Documentation
## Indian Sign Language Learning App with AI-Powered Hand Detection

**Author:** Megh Modi  
**Created:** December 18, 2025  
**Last Updated:** January 4, 2026  
**Version:** 1.0.0  
**Status:** Development Phase

---

# Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Project Vision & Goals](#2-project-vision--goals)
3. [Functional Requirements](#3-functional-requirements)
4. [Non-Functional Requirements](#4-non-functional-requirements)
5. [System Architecture & Flow](#5-system-architecture--flow)
6. [Technology Stack](#6-technology-stack)
7. [Database Schema](#7-database-schema)
8. [Firebase Storage Structure](#8-firebase-storage-structure)
9. [Security Rules](#9-security-rules)
10. [API & Cloud Functions](#10-api--cloud-functions)
11. [Screen Flow & Navigation](#11-screen-flow--navigation)
12. [Sample Data](#12-sample-data)

---

# 1. Executive Summary

## What is KairoAI?

KairoAI is an Indian Sign Language (ISL) learning application designed specifically for children. The app uses real-time hand gesture detection via the device camera to teach ISL alphabets and words, providing instant feedback to students.

## Core Innovation

The app combines three powerful technologies:
- **Flutter** for cross-platform UI
- **MediaPipe** for hand detection (running natively on Android)
- **TensorFlow Lite** for sign language classification

## Key Differentiator

Unlike traditional learning apps, KairoAI provides **real-time visual feedback** by:
1. Showing the user what sign to make
2. Detecting their hand position using the camera
3. Validating if they're making the correct sign
4. Providing instant feedback (success/try again)

---

# 2. Project Vision & Goals

## Primary Goal

Create an accessible, engaging platform for children to learn Indian Sign Language through interactive, AI-powered lessons.

## Target Users

| User Type | Description |
|-----------|-------------|
| **Primary** | Children aged 6-14 learning ISL |
| **Secondary** | Parents and educators teaching ISL |
| **Tertiary** | Anyone interested in learning ISL |

## Core Features

### 1. Lesson Mode
- Display a target alphabet (e.g., "A") or word (e.g., "MEGH")
- Open device camera
- Detect student's hand sign in real-time
- Validate against expected sign
- Show success animation/sound on correct detection
- Provide guidance hints on incorrect attempts

### 2. Quiz Mode
- Present random alphabets or words
- Student performs signs sequentially
- Each detected letter is validated in order
- Progress only on correct detection
- Track accuracy and completion time

### 3. Progress Tracking
- Store lesson completion in Firebase Firestore
- Track quiz scores and accuracy
- Visualize learning progress over time
- Gamification elements (badges, streaks, XP)

### 4. Gamification System
- Virtual currencies (Gems, Coins)
- Experience Points (XP) and Levels
- Daily streaks
- Achievements and badges
- Leaderboards

---

# 3. Functional Requirements

## 3.1 User Management

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | User can register using email/password | High |
| FR-002 | User can login using Google Sign-In | High |
| FR-003 | User can reset password via email | Medium |
| FR-004 | User can update profile information | Medium |
| FR-005 | User can set daily learning goals | Medium |
| FR-006 | System tracks user login streaks | High |

## 3.2 Onboarding

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-010 | New users complete onboarding flow | High |
| FR-011 | User selects learning goal during onboarding | High |
| FR-012 | User sets daily practice duration | Medium |
| FR-013 | App shows tutorial for first-time users | Medium |

## 3.3 Learning System

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-020 | Display categorized lessons (Alphabets, Numbers, etc.) | High |
| FR-021 | Show lesson progress within categories | High |
| FR-022 | Display sign images/GIFs/videos for learning | High |
| FR-023 | Provide step-by-step instructions for each sign | High |
| FR-024 | Lock advanced lessons until prerequisites complete | Medium |
| FR-025 | Show estimated time for each lesson | Low |

## 3.4 Practice Mode (Camera Detection)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-030 | Access device camera for sign detection | Critical |
| FR-031 | Detect hand landmarks using MediaPipe | Critical |
| FR-032 | Classify sign using TensorFlow Lite model | Critical |
| FR-033 | Show real-time detection feedback | Critical |
| FR-034 | Display confidence score for detection | High |
| FR-035 | Allow camera flip (front/back) | Medium |
| FR-036 | Show visual guide overlay during practice | Medium |
| FR-037 | Provide audio feedback for correct/incorrect signs | Medium |

## 3.5 Quiz System

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-040 | Present random signs for user to perform | High |
| FR-041 | Validate user's sign against expected sign | High |
| FR-042 | Track quiz accuracy and completion time | High |
| FR-043 | Show quiz results summary | High |
| FR-044 | Award XP/coins based on performance | High |
| FR-045 | Progressive difficulty in quizzes | Medium |

## 3.6 Gamification

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-050 | Track and display user's gems/coins | High |
| FR-051 | Calculate and display XP and levels | High |
| FR-052 | Track daily practice streaks | High |
| FR-053 | Award achievements for milestones | Medium |
| FR-054 | Display global/weekly leaderboards | Medium |
| FR-055 | Send streak reminder notifications | Low |

## 3.7 Daily Insights

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-060 | Display daily tip/fact on home screen | Medium |
| FR-061 | Show motivational quotes | Low |
| FR-062 | Provide ISL fun facts | Low |

## 3.8 Progress & Analytics

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-070 | Track total lessons completed | High |
| FR-071 | Track total signs learned | High |
| FR-072 | Track total practice time | Medium |
| FR-073 | Show progress charts/statistics | Medium |
| FR-074 | Display category-wise completion | Medium |

---

# 4. Non-Functional Requirements

## 4.1 Performance

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-001 | App startup time | < 3 seconds |
| NFR-002 | Camera frame processing rate | 30 FPS |
| NFR-003 | Sign detection latency | < 200ms |
| NFR-004 | API response time | < 500ms |
| NFR-005 | App size (APK) | < 100 MB |

## 4.2 Scalability

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-010 | Concurrent users supported | 10,000+ |
| NFR-011 | Database read/write operations | 1M+ daily |
| NFR-012 | Media storage capacity | 10 GB+ |

## 4.3 Reliability

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-020 | App availability | 99.9% uptime |
| NFR-021 | Crash-free sessions | > 99% |
| NFR-022 | Data backup frequency | Daily |
| NFR-023 | Offline functionality | Lesson viewing |

## 4.4 Security

| ID | Requirement | Description |
|----|-------------|-------------|
| NFR-030 | User authentication | Firebase Auth with secure tokens |
| NFR-031 | Data encryption | TLS 1.3 for data in transit |
| NFR-032 | Database security | Firestore security rules |
| NFR-033 | API security | Authenticated requests only |
| NFR-034 | Privacy compliance | GDPR/COPPA compliant |

## 4.5 Usability

| ID | Requirement | Description |
|----|-------------|-------------|
| NFR-040 | Target age group | 6-14 years (child-friendly UI) |
| NFR-041 | Language support | English, Hindi |
| NFR-042 | Accessibility | Screen reader compatible |
| NFR-043 | Color contrast | WCAG AA compliant |
| NFR-044 | Touch targets | Minimum 48x48 dp |

## 4.6 Compatibility

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-050 | Android version | API 26+ (Android 8.0+) |
| NFR-051 | iOS version | iOS 12+ (Future) |
| NFR-052 | Device camera | Front-facing required |
| NFR-053 | Screen sizes | 5" to 12" displays |

## 4.7 Maintainability

| ID | Requirement | Description |
|----|-------------|-------------|
| NFR-060 | Code documentation | Inline comments + README |
| NFR-061 | Modular architecture | Feature-based structure |
| NFR-062 | Test coverage | > 70% unit test coverage |
| NFR-063 | CI/CD pipeline | Automated builds and tests |

---

# 5. System Architecture & Flow

## 5.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          FLUTTER LAYER (UI)                              │
│                            Written in Dart                               │
│                                                                          │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│   │   Home      │  │   Lessons   │  │   Practice  │  │   Quiz      │   │
│   │   Page      │  │   Page      │  │   Page      │  │   Page      │   │
│   └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│   │  Profile    │  │   Login/    │  │ Onboarding  │  │  Category   │   │
│   │   Page      │  │  Signup     │  │   Page      │  │   Page      │   │
│   └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │
│                                                                          │
│                        Firebase Integration                              │
│               (Authentication, Firestore, Storage)                       │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             │ Platform Channels (MethodChannel)
                             │
┌────────────────────────────┴────────────────────────────────────────────┐
│                      KOTLIN LAYER (Android Native)                       │
│                                                                          │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐              │
│   │   CameraX    │ →  │  MediaPipe   │ →  │  TensorFlow  │              │
│   │              │    │    Hands     │    │     Lite     │              │
│   │ Capture      │    │ Detect hand  │    │ Classify     │              │
│   │ frames       │    │ Extract 21   │    │ sign         │              │
│   │              │    │ landmarks    │    │              │              │
│   └──────────────┘    └──────────────┘    └──────────────┘              │
│                                                                          │
│   Returns: { letter: "A", confidence: 0.95, handDetected: true }        │
└──────────────────────────────────────────────────────────────────────────┘
```

## 5.2 User Authentication Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   App Start  │ ──► │  Auth Check  │ ──► │  Logged In?  │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                  │
                     ┌────────────────────────────┼────────────────────────┐
                     │                            │                        │
                     ▼                            ▼                        │
              ┌──────────────┐            ┌──────────────┐                 │
              │  Login Page  │            │  Home Page   │                 │
              └──────┬───────┘            └──────────────┘                 │
                     │                                                      │
        ┌────────────┼────────────┐                                        │
        │            │            │                                        │
        ▼            ▼            ▼                                        │
┌─────────────┐ ┌─────────┐ ┌──────────┐                                  │
│Email/Pass   │ │ Google  │ │ Sign Up  │                                  │
│   Login     │ │ Sign-In │ │   Page   │                                  │
└──────┬──────┘ └────┬────┘ └────┬─────┘                                  │
       │             │           │                                         │
       └─────────────┴───────────┴─────────────────────────────────────────┘
                     │
                     ▼
              ┌──────────────┐     ┌──────────────┐
              │  New User?   │ ──► │  Onboarding  │
              └──────┬───────┘     └──────┬───────┘
                     │                    │
                     │    No              │
                     ▼                    ▼
              ┌──────────────┐     ┌──────────────┐
              │  Home Page   │ ◄── │  Home Page   │
              └──────────────┘     └──────────────┘
```

## 5.3 Learning Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Home Page   │ ──► │  Categories  │ ──► │   Lessons    │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                  │
                                                  ▼
                                          ┌──────────────┐
                                          │ Lesson Detail│
                                          │ (View Signs) │
                                          └──────┬───────┘
                                                  │
                     ┌────────────────────────────┴────────────────────┐
                     │                                                  │
                     ▼                                                  ▼
              ┌──────────────┐                                  ┌──────────────┐
              │ Practice Mode│                                  │  Quiz Mode   │
              │  (Camera)    │                                  │  (Camera)    │
              └──────┬───────┘                                  └──────┬───────┘
                     │                                                  │
                     ▼                                                  ▼
              ┌──────────────┐                                  ┌──────────────┐
              │ Sign Detection│                                 │ Sign Detection│
              │ (MediaPipe +  │                                 │ + Validation │
              │  TF Lite)     │                                 └──────┬───────┘
              └──────┬───────┘                                         │
                     │                                                  │
                     ▼                                                  ▼
              ┌──────────────┐                                  ┌──────────────┐
              │ Real-time    │                                  │ Quiz Results │
              │ Feedback     │                                  │ + Rewards    │
              └──────┬───────┘                                  └──────┬───────┘
                     │                                                  │
                     └──────────────────────┬───────────────────────────┘
                                            │
                                            ▼
                                     ┌──────────────┐
                                     │Update Progress│
                                     │ XP, Coins,   │
                                     │ Achievements │
                                     └──────────────┘
```

## 5.4 Sign Detection Pipeline

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         SIGN DETECTION PIPELINE                           │
└──────────────────────────────────────────────────────────────────────────┘

Step 1: Camera Capture
┌─────────────────────┐
│     CameraX         │
│  ┌───────────────┐  │
│  │ 640x480 Frame │  │     30 FPS
│  │    (RGB)      │──┼────────────────┐
│  └───────────────┘  │                │
└─────────────────────┘                │
                                       ▼
Step 2: Hand Detection              ┌─────────────────────┐
┌─────────────────────┐             │  MediaPipe Hands    │
│    Frame Input      │────────────►│  (Pre-trained)      │
└─────────────────────┘             │                     │
                                    │  Outputs:           │
                                    │  - Hand detected?   │
                                    │  - 21 landmarks     │
                                    │  - Handedness       │
                                    └──────────┬──────────┘
                                               │
Step 3: Landmark Processing                    ▼
┌──────────────────────────────────────────────────────────┐
│                   21 Hand Landmarks                       │
│   ┌───┐ ┌───┐ ┌───┐ ┌───┐                               │
│   │ 0 │ │ 1 │ │ 2 │ │...│ ... │20│                      │
│   │x,y│ │x,y│ │x,y│ │x,y│     │x,y│                     │
│   └───┘ └───┘ └───┘ └───┘     └───┘                     │
│                                                          │
│   Normalize: Scale to [0,1], Center on palm              │
│   Flatten: [x0,y0,z0, x1,y1,z1, ... x20,y20,z20]        │
│   Total: 63 features                                     │
└──────────────────────────┬───────────────────────────────┘
                           │
Step 4: Classification     ▼
┌──────────────────────────────────────────────────────────┐
│                TensorFlow Lite Model                      │
│   ┌──────────────────────────────────────────────────┐   │
│   │  Input: [63 normalized landmark values]          │   │
│   │                                                   │   │
│   │  Hidden Layer 1: Dense(128, relu)                │   │
│   │  Dropout: 0.3                                     │   │
│   │  Hidden Layer 2: Dense(64, relu)                 │   │
│   │  Dropout: 0.3                                     │   │
│   │  Output: Dense(26, softmax) ← A-Z probabilities  │   │
│   └──────────────────────────────────────────────────┘   │
└──────────────────────────┬───────────────────────────────┘
                           │
Step 5: Result             ▼
┌──────────────────────────────────────────────────────────┐
│                     Detection Result                      │
│   {                                                       │
│     "letter": "A",                                        │
│     "confidence": 0.95,                                   │
│     "handDetected": true,                                │
│     "landmarks": [...21 points...]                        │
│   }                                                       │
└──────────────────────────────────────────────────────────┘
```

---

# 6. Technology Stack

## 6.1 Frontend (Flutter/Dart)

| Technology | Version | Purpose |
|------------|---------|---------|
| Flutter | 3.16+ | Cross-platform UI framework |
| Dart | 3.2+ | Programming language |
| firebase_core | ^2.24.2 | Firebase initialization |
| firebase_auth | ^4.16.0 | User authentication |
| cloud_firestore | ^4.14.0 | NoSQL database |
| camera | ^0.10.5 | Camera access |
| provider | ^6.1.1 | State management |
| lottie | ^3.0.0 | Animations |

## 6.2 Backend (Firebase)

| Service | Purpose |
|---------|---------|
| Firebase Authentication | User sign-in/sign-up |
| Cloud Firestore | Real-time database |
| Firebase Storage | Media files (images, videos) |
| Cloud Functions | Server-side logic |
| Firebase Analytics | Usage tracking |

## 6.3 Native Android (Kotlin)

| Technology | Version | Purpose |
|------------|---------|---------|
| Kotlin | 1.9+ | Native Android development |
| CameraX | 1.3.1 | Camera API |
| MediaPipe Tasks Vision | 0.10.14 | Hand landmark detection |
| TensorFlow Lite | 2.14.0 | ML model inference |

## 6.4 ML/AI (Python)

| Library | Version | Purpose |
|---------|---------|---------|
| TensorFlow | 2.15.0 | Model training |
| MediaPipe | 0.10.9 | Landmark extraction |
| OpenCV | 4.8.1 | Image processing |
| NumPy | 1.26.2 | Numerical operations |
| Pandas | 2.1.3 | Data manipulation |

---

# 7. Database Schema

## 7.1 Collections Overview

```
Firestore Database Structure:
├── users/                          ← User profiles & stats
│   └── {userId}/
│       ├── [document fields]       ← Profile data
│       ├── progress/               ← Lesson progress tracking
│       │   └── {lessonId}/
│       └── achievements/           ← Unlocked achievements
│           └── {achievementId}/
├── categories/                     ← Learning categories
│   └── {categoryId}/
│       ├── [document fields]       ← Category info
│       └── lessons/                ← Lessons per category
│           └── {lessonId}/
│               ├── [document fields] ← Lesson info
│               └── signs/          ← Signs per lesson
│                   └── {signId}/
├── daily_insights/                 ← Daily tips & facts
│   └── {insightId}/
├── achievements/                   ← Achievement definitions
│   └── {achievementId}/
└── leaderboard/                    ← User rankings
    └── {userId}/
```

---

## 7.2 Users Collection

### Path: `users/{userId}`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `uid` | string | Yes | Firebase Auth UID |
| `email` | string | Yes | User's email address |
| `displayName` | string | Yes | Display name |
| `photoUrl` | string | No | Profile picture URL |
| `createdAt` | timestamp | Yes | Account creation date |
| `lastLoginAt` | timestamp | Yes | Last login timestamp |
| `gems` | number | Yes | Virtual currency (gems) |
| `coins` | number | Yes | Virtual currency (coins) |
| `streakDays` | number | Yes | Consecutive practice days |
| `lastStreakDate` | timestamp | No | Last streak update date |
| `learningGoal` | string | No | User's learning objective |
| `dailyGoalMinutes` | number | Yes | Daily practice target (default: 10) |
| `totalLessonsCompleted` | number | Yes | Total lessons finished |
| `totalSignsLearned` | number | Yes | Total signs mastered |
| `totalPracticeMinutes` | number | Yes | Total practice time |
| `currentLevel` | number | Yes | User's current level |
| `xp` | number | Yes | Experience points |

### Sample Document:

```json
{
  "uid": "firebase_auth_uid",
  "email": "user@example.com",
  "displayName": "John Doe",
  "photoUrl": "https://storage.googleapis.com/...",
  "createdAt": "Timestamp",
  "lastLoginAt": "Timestamp",
  "gems": 144,
  "coins": 2321,
  "streakDays": 7,
  "lastStreakDate": "Timestamp",
  "learningGoal": "Communicate with family",
  "dailyGoalMinutes": 10,
  "totalLessonsCompleted": 15,
  "totalSignsLearned": 45,
  "totalPracticeMinutes": 120,
  "currentLevel": 3,
  "xp": 1250
}
```

---

## 7.3 User Progress Subcollection

### Path: `users/{userId}/progress/{lessonId}`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `lessonId` | string | Yes | Lesson identifier |
| `categoryId` | string | Yes | Parent category ID |
| `status` | string | Yes | "not_started", "in_progress", "completed" |
| `completedAt` | timestamp | No | Completion timestamp |
| `startedAt` | timestamp | No | Start timestamp |
| `accuracy` | number | Yes | Accuracy percentage (0-100) |
| `timeSpentSeconds` | number | Yes | Time spent on lesson |
| `attemptsCount` | number | Yes | Number of attempts |
| `signsCompleted` | array | Yes | List of completed sign IDs |
| `gemsEarned` | number | Yes | Gems earned from lesson |
| `coinsEarned` | number | Yes | Coins earned from lesson |

### Sample Document:

```json
{
  "lessonId": "greetings_unit1",
  "categoryId": "greetings",
  "status": "completed",
  "completedAt": "Timestamp",
  "startedAt": "Timestamp",
  "accuracy": 85.5,
  "timeSpentSeconds": 300,
  "attemptsCount": 2,
  "signsCompleted": ["hello", "goodbye", "thank_you"],
  "gemsEarned": 5,
  "coinsEarned": 50
}
```

---

## 7.4 User Achievements Subcollection

### Path: `users/{userId}/achievements/{achievementId}`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `achievementId` | string | Yes | Achievement reference ID |
| `unlockedAt` | timestamp | Yes | When achievement was unlocked |
| `claimed` | boolean | Yes | Whether rewards were claimed |
| `claimedAt` | timestamp | No | When rewards were claimed |

### Sample Document:

```json
{
  "achievementId": "first_lesson",
  "unlockedAt": "Timestamp",
  "claimed": true,
  "claimedAt": "Timestamp"
}
```

---

## 7.5 Categories Collection

### Path: `categories/{categoryId}`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Category identifier |
| `name` | string | Yes | Category display name |
| `description` | string | Yes | Category description |
| `iconUrl` | string | No | Category icon URL |
| `iconEmoji` | string | Yes | Emoji icon |
| `color` | string | Yes | Theme color (hex) |
| `order` | number | Yes | Display order |
| `totalLessons` | number | Yes | Number of lessons |
| `totalSigns` | number | Yes | Number of signs |
| `isLocked` | boolean | Yes | Lock status |
| `requiredLevel` | number | Yes | Level needed to unlock |
| `createdAt` | timestamp | Yes | Creation timestamp |

### Sample Document:

```json
{
  "id": "greetings",
  "name": "Greetings",
  "description": "Learn common greeting signs",
  "iconUrl": "https://storage.googleapis.com/...",
  "iconEmoji": "👋",
  "color": "#4A90D9",
  "order": 1,
  "totalLessons": 5,
  "totalSigns": 20,
  "isLocked": false,
  "requiredLevel": 1,
  "createdAt": "Timestamp"
}
```

### Sample Categories:

| ID | Name | Emoji | Description |
|----|------|-------|-------------|
| `greetings` | Greetings | 👋 | Common greeting signs |
| `numbers` | Numbers | 🔢 | Number signs 1-100 |
| `alphabets` | Alphabets | 🔤 | ISL A-Z alphabets |
| `family` | Family | 👨‍👩‍👧‍👦 | Family member signs |
| `emotions` | Emotions | 😊 | Emotional expressions |
| `food` | Food & Drinks | 🍎 | Food-related signs |
| `animals` | Animals | 🐕 | Animal signs |
| `colors` | Colors | 🎨 | Color signs |
| `daily_words` | Daily Words | 📝 | Everyday vocabulary |
| `history` | History | 📜 | Historical ISL signs |

---

## 7.6 Lessons Subcollection

### Path: `categories/{categoryId}/lessons/{lessonId}`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Lesson identifier |
| `categoryId` | string | Yes | Parent category ID |
| `unitNumber` | number | Yes | Unit number within category |
| `title` | string | Yes | Lesson title |
| `subtitle` | string | Yes | Short subtitle |
| `description` | string | Yes | Detailed description |
| `thumbnailUrl` | string | No | Thumbnail image URL |
| `order` | number | Yes | Display order |
| `totalSigns` | number | Yes | Number of signs in lesson |
| `estimatedMinutes` | number | Yes | Estimated completion time |
| `difficulty` | string | Yes | "beginner", "intermediate", "advanced" |
| `gemsReward` | number | Yes | Gems reward for completion |
| `coinsReward` | number | Yes | Coins reward for completion |
| `xpReward` | number | Yes | XP reward for completion |
| `isLocked` | boolean | Yes | Lock status |
| `requiredLessonId` | string | No | Prerequisite lesson ID |
| `focusPoints` | array | Yes | Learning objectives |
| `createdAt` | timestamp | Yes | Creation timestamp |

### Sample Document:

```json
{
  "id": "greetings_unit1",
  "categoryId": "greetings",
  "unitNumber": 1,
  "title": "Greetings",
  "subtitle": "Basic greeting signs",
  "description": "Learn to say hello, goodbye, and thank you in ISL",
  "thumbnailUrl": "https://storage.googleapis.com/...",
  "order": 1,
  "totalSigns": 4,
  "estimatedMinutes": 5,
  "difficulty": "beginner",
  "gemsReward": 5,
  "coinsReward": 50,
  "xpReward": 25,
  "isLocked": false,
  "requiredLessonId": null,
  "focusPoints": [
    "Learn basic greeting signs",
    "Understand hand positioning",
    "Practice smooth transitions"
  ],
  "createdAt": "Timestamp"
}
```

---

## 7.7 Signs Subcollection

### Path: `categories/{categoryId}/lessons/{lessonId}/signs/{signId}`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Sign identifier |
| `lessonId` | string | Yes | Parent lesson ID |
| `word` | string | Yes | Sign word (English) |
| `wordInHindi` | string | No | Sign word (Hindi) |
| `order` | number | Yes | Display order |
| `imageUrl` | string | No | Static image URL |
| `gifUrl` | string | No | Animated GIF URL |
| `videoUrl` | string | No | Video demonstration URL |
| `description` | string | Yes | How to perform the sign |
| `instructions` | array | Yes | Step-by-step instructions |
| `tips` | string | No | Helpful tips |
| `difficulty` | string | Yes | "easy", "medium", "hard" |
| `expectedLandmarks` | map | No | Hand landmark data for validation |
| `createdAt` | timestamp | Yes | Creation timestamp |

### Sample Document:

```json
{
  "id": "hello",
  "lessonId": "greetings_unit1",
  "word": "Hello",
  "wordInHindi": "नमस्ते",
  "order": 1,
  "imageUrl": "https://firebasestorage.../signs/hello.png",
  "gifUrl": "https://firebasestorage.../signs/hello.gif",
  "videoUrl": "https://firebasestorage.../signs/hello.mp4",
  "description": "Wave your hand with palm facing outward",
  "instructions": [
    "Raise your dominant hand",
    "Keep palm facing outward",
    "Move hand side to side gently"
  ],
  "tips": "Keep your fingers together",
  "difficulty": "easy",
  "expectedLandmarks": {
    "fingerSpread": 0.2,
    "palmDirection": "outward"
  },
  "createdAt": "Timestamp"
}
```

---

## 7.8 Daily Insights Collection

### Path: `daily_insights/{insightId}`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Insight identifier |
| `date` | string | Yes | Date (YYYY-MM-DD format) |
| `title` | string | Yes | Insight title |
| `message` | string | Yes | Main message content |
| `tip` | string | No | Practice tip |
| `funFact` | string | No | ISL fun fact |
| `motivationalQuote` | string | No | Motivational quote |
| `audioUrl` | string | No | Audio insight URL |
| `imageUrl` | string | No | Accompanying image URL |
| `isActive` | boolean | Yes | Active status |
| `createdAt` | timestamp | Yes | Creation timestamp |

### Sample Document:

```json
{
  "id": "insight_20251231",
  "date": "2025-12-31",
  "title": "Day Insight",
  "message": "Listen every Day Insight about your education",
  "tip": "Practice makes perfect! Try to practice for at least 10 minutes daily.",
  "funFact": "Did you know? ISL has regional variations across India!",
  "motivationalQuote": "Every sign you learn brings you closer to connection.",
  "audioUrl": "https://storage.googleapis.com/...",
  "imageUrl": "https://storage.googleapis.com/...",
  "isActive": true,
  "createdAt": "Timestamp"
}
```

---

## 7.9 Achievements Collection

### Path: `achievements/{achievementId}`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Achievement identifier |
| `name` | string | Yes | Achievement display name |
| `description` | string | Yes | Achievement description |
| `iconUrl` | string | No | Badge icon URL |
| `iconEmoji` | string | Yes | Emoji representation |
| `type` | string | Yes | "milestone", "streak", "mastery", "social" |
| `requirement` | map | Yes | Requirement criteria |
| `gemsReward` | number | Yes | Gems reward |
| `coinsReward` | number | Yes | Coins reward |
| `xpReward` | number | Yes | XP reward |
| `isHidden` | boolean | Yes | Hidden achievement flag |
| `order` | number | Yes | Display order |
| `createdAt` | timestamp | Yes | Creation timestamp |

### Sample Document:

```json
{
  "id": "first_lesson",
  "name": "First Steps",
  "description": "Complete your first lesson",
  "iconUrl": "https://storage.googleapis.com/...",
  "iconEmoji": "🎯",
  "type": "milestone",
  "requirement": {
    "type": "lessons_completed",
    "value": 1
  },
  "gemsReward": 10,
  "coinsReward": 100,
  "xpReward": 50,
  "isHidden": false,
  "order": 1,
  "createdAt": "Timestamp"
}
```

### Sample Achievements:

| ID | Name | Type | Requirement |
|----|------|------|-------------|
| `first_lesson` | First Steps | milestone | Complete 1 lesson |
| `streak_7` | Week Warrior | streak | 7 day streak |
| `streak_30` | Monthly Master | streak | 30 day streak |
| `alphabets_master` | Alphabet Pro | mastery | Learn all alphabets |
| `perfect_score` | Perfectionist | milestone | 100% on a lesson |
| `speed_learner` | Speed Demon | milestone | Lesson under 3 min |
| `practice_100` | Dedicated | milestone | 100 minutes total |

---

## 7.10 Leaderboard Collection

### Path: `leaderboard/{userId}`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `userId` | string | Yes | User's Firebase UID |
| `displayName` | string | Yes | User's display name |
| `photoUrl` | string | No | Profile picture URL |
| `xp` | number | Yes | Total experience points |
| `level` | number | Yes | User's current level |
| `lessonsCompleted` | number | Yes | Total lessons completed |
| `streakDays` | number | Yes | Current streak days |
| `weeklyXp` | number | Yes | XP earned this week |
| `monthlyXp` | number | Yes | XP earned this month |
| `lastUpdated` | timestamp | Yes | Last update timestamp |

### Sample Document:

```json
{
  "userId": "firebase_auth_uid",
  "displayName": "John Doe",
  "photoUrl": "https://storage.googleapis.com/...",
  "xp": 1250,
  "level": 3,
  "lessonsCompleted": 15,
  "streakDays": 7,
  "weeklyXp": 350,
  "monthlyXp": 1100,
  "lastUpdated": "Timestamp"
}
```

---

## 7.11 Database Indexes

Create composite indexes in Firestore for optimized queries:

| Collection | Fields | Order |
|------------|--------|-------|
| `categories` | `order` | ASC |
| `categories/{}/lessons` | `order` | ASC |
| `categories/{}/lessons/{}/signs` | `order` | ASC |
| `leaderboard` | `xp` | DESC |
| `leaderboard` | `weeklyXp` | DESC |
| `leaderboard` | `monthlyXp` | DESC |
| `users/{}/progress` | `completedAt` | DESC |
| `daily_insights` | `date`, `isActive` | DESC, true |

---

# 8. Firebase Storage Structure

```
Firebase Storage Bucket:
├── signs/
│   ├── images/
│   │   └── {signId}.png          ← Static sign images
│   ├── gifs/
│   │   └── {signId}.gif          ← Animated demonstrations
│   └── videos/
│       └── {signId}.mp4          ← Video tutorials
├── categories/
│   └── icons/
│       └── {categoryId}.png      ← Category icons
├── achievements/
│   └── icons/
│       └── {achievementId}.png   ← Achievement badges
├── mascot/
│   └── robot_*.png               ← App mascot images
├── lessons/
│   └── thumbnails/
│       └── {lessonId}.png        ← Lesson thumbnails
└── users/
    └── {userId}/
        └── profile.jpg           ← User profile photos
```

## Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Public read for all media
    match /signs/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    match /categories/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    match /achievements/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    match /mascot/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    match /lessons/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    // Users can only access their own profile photos
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

# 9. Security Rules

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ==================== USERS ====================
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // User progress subcollection
      match /progress/{lessonId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // User achievements subcollection
      match /achievements/{achievementId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // ==================== CATEGORIES ====================
    // Categories and lessons are public read, admin write only
    match /categories/{categoryId} {
      allow read: if request.auth != null;
      allow write: if false; // Admin only via Firebase Console
      
      match /lessons/{lessonId} {
        allow read: if request.auth != null;
        allow write: if false;
        
        match /signs/{signId} {
          allow read: if request.auth != null;
          allow write: if false;
        }
      }
    }
    
    // ==================== DAILY INSIGHTS ====================
    match /daily_insights/{insightId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    // ==================== ACHIEVEMENTS ====================
    match /achievements/{achievementId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    // ==================== LEADERBOARD ====================
    // Public read, users can update their own entry
    match /leaderboard/{docId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == docId;
    }
  }
}
```

---

# 10. API & Cloud Functions

## 10.1 Recommended Cloud Functions

### Function 1: `onUserCreate`
**Trigger:** When a new user is created in Firebase Auth  
**Purpose:** Initialize user document with default values

```javascript
exports.onUserCreate = functions.auth.user().onCreate(async (user) => {
  await admin.firestore().collection('users').doc(user.uid).set({
    uid: user.uid,
    email: user.email,
    displayName: user.displayName || 'Learner',
    photoUrl: user.photoURL,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
    gems: 50,      // Welcome bonus
    coins: 100,    // Welcome bonus
    streakDays: 0,
    dailyGoalMinutes: 10,
    totalLessonsCompleted: 0,
    totalSignsLearned: 0,
    totalPracticeMinutes: 0,
    currentLevel: 1,
    xp: 0
  });
});
```

### Function 2: `onLessonComplete`
**Trigger:** When lesson progress status changes to "completed"  
**Purpose:** Update leaderboard, check for achievements

```javascript
exports.onLessonComplete = functions.firestore
  .document('users/{userId}/progress/{lessonId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    if (before.status !== 'completed' && after.status === 'completed') {
      // Update leaderboard
      // Check achievements
      // Award XP
    }
  });
```

### Function 3: `dailyStreakCheck` (Scheduled)
**Trigger:** Daily at midnight  
**Purpose:** Reset streaks for inactive users

```javascript
exports.dailyStreakCheck = functions.pubsub.schedule('0 0 * * *')
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    // Find users who haven't practiced yesterday
    // Reset their streak to 0
  });
```

### Function 4: `weeklyLeaderboardReset` (Scheduled)
**Trigger:** Every Monday at midnight  
**Purpose:** Reset weekly XP on leaderboard

```javascript
exports.weeklyLeaderboardReset = functions.pubsub.schedule('0 0 * * 1')
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    // Reset weeklyXp to 0 for all users
  });
```

---

# 11. Screen Flow & Navigation

## 11.1 App Screens

| Screen | File | Description |
|--------|------|-------------|
| Login | `login_page.dart` | Email/Password and Google Sign-In |
| Sign Up | `signup_page.dart` | New user registration |
| Onboarding | `onboarding_page.dart` | First-time user setup |
| Home | `home_page.dart`, `new_home_page.dart` | Main dashboard |
| Duolingo Home | `duolingo_home_page.dart` | Duolingo-style home |
| Categories | `category_page.dart` | Browse lesson categories |
| Lesson Detail | `lesson_detail_page.dart` | Individual lesson view |
| Practice | `practice_page.dart` | Camera-based practice |
| Quiz | `quiz_page.dart` | Interactive quizzes |
| Profile | `profile_page.dart` | User profile & settings |

## 11.2 Navigation Map

```
                                    ┌──────────────┐
                                    │   App Start  │
                                    └──────┬───────┘
                                           │
                                           ▼
                                    ┌──────────────┐
                               ┌────│  Auth Check  │────┐
                               │    └──────────────┘    │
                               │                        │
                               ▼                        ▼
                        ┌──────────────┐        ┌──────────────┐
                        │  Login Page  │        │  Home Page   │
                        └──────┬───────┘        └──────┬───────┘
                               │                       │
              ┌────────────────┼────────────────┐      │
              │                │                │      │
              ▼                ▼                ▼      │
       ┌──────────────┐ ┌──────────┐ ┌──────────────┐  │
       │  Sign Up     │ │  Google  │ │  Forgot      │  │
       │  Page        │ │  Sign-In │ │  Password    │  │
       └──────┬───────┘ └────┬─────┘ └──────────────┘  │
              │              │                         │
              └──────────────┴─────────────────────────┘
                             │
                             ▼
                      ┌──────────────┐
                      │  Onboarding  │ (if new user)
                      └──────┬───────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                         MAIN NAVIGATION                          │
│                                                                  │
│   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐    │
│   │   Home   │   │  Learn   │   │   Quiz   │   │ Profile  │    │
│   │   Tab    │   │   Tab    │   │   Tab    │   │   Tab    │    │
│   └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘    │
│        │              │              │              │           │
└────────┼──────────────┼──────────────┼──────────────┼───────────┘
         │              │              │              │
         ▼              ▼              ▼              ▼
  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐
  │ Daily      │  │ Categories │  │ Quiz List  │  │ User Stats │
  │ Insight    │  │ List       │  │            │  │ Settings   │
  │ Streak     │  └─────┬──────┘  └─────┬──────┘  │ Logout     │
  │ Progress   │        │               │         └────────────┘
  └────────────┘        ▼               ▼
                 ┌────────────┐  ┌────────────┐
                 │ Lessons    │  │ Quiz       │
                 │ List       │  │ Practice   │
                 └─────┬──────┘  │ (Camera)   │
                       │         └────────────┘
                       ▼
                ┌────────────┐
                │ Lesson     │
                │ Detail     │
                └─────┬──────┘
                      │
         ┌────────────┴────────────┐
         │                         │
         ▼                         ▼
  ┌────────────┐            ┌────────────┐
  │ Practice   │            │ Lesson     │
  │ (Camera)   │            │ Quiz       │
  └─────┬──────┘            └─────┬──────┘
        │                         │
        ▼                         ▼
  ┌────────────┐            ┌────────────┐
  │ Results    │            │ Results    │
  │ + Rewards  │            │ + Rewards  │
  └────────────┘            └────────────┘
```

---

# 12. Sample Data

## 12.1 Initial Categories Setup

```javascript
// Category: Greetings
{
  id: "greetings",
  name: "Greetings",
  description: "Learn common greeting signs in ISL",
  iconEmoji: "👋",
  color: "#4A90D9",
  order: 1,
  totalLessons: 3,
  totalSigns: 15,
  isLocked: false,
  requiredLevel: 1
}

// Category: Alphabets
{
  id: "alphabets",
  name: "Alphabets",
  description: "Master the ISL alphabet A-Z",
  iconEmoji: "🔤",
  color: "#9B59B6",
  order: 2,
  totalLessons: 5,
  totalSigns: 26,
  isLocked: false,
  requiredLevel: 1
}

// Category: Numbers
{
  id: "numbers",
  name: "Numbers",
  description: "Learn to sign numbers 1-100",
  iconEmoji: "🔢",
  color: "#27AE60",
  order: 3,
  totalLessons: 4,
  totalSigns: 20,
  isLocked: false,
  requiredLevel: 2
}
```

## 12.2 Recommended Lesson Structure

- Each category: 3-5 units/lessons
- Each lesson: 4-6 signs
- Estimated time: 5-10 minutes per lesson
- Progressive difficulty within each category

## 12.3 Sample Signs

```javascript
// Sign: Hello
{
  id: "hello",
  word: "Hello",
  wordInHindi: "नमस्ते",
  description: "Wave your hand with palm facing outward",
  instructions: [
    "Raise your dominant hand to shoulder level",
    "Keep palm facing outward",
    "Gently wave hand side to side"
  ],
  tips: "Keep fingers together for a cleaner sign",
  difficulty: "easy"
}

// Sign: Thank You
{
  id: "thank_you",
  word: "Thank You",
  wordInHindi: "धन्यवाद",
  description: "Touch chin and move hand forward",
  instructions: [
    "Place fingertips on your chin",
    "Move hand forward and down",
    "End with palm facing up"
  ],
  tips: "The motion should be smooth and grateful",
  difficulty: "easy"
}
```

---

# Summary

This document provides comprehensive documentation for the **KairoAI** Indian Sign Language Learning App, including:

✅ **Functional Requirements** - 40+ detailed requirements across 8 modules  
✅ **Non-Functional Requirements** - Performance, security, usability standards  
✅ **System Architecture** - High-level and detailed component diagrams  
✅ **Database Schema** - 10 collections with complete field definitions  
✅ **Security Rules** - Firestore and Storage security configurations  
✅ **Screen Flow** - Complete navigation map of the application  
✅ **Sample Data** - Ready-to-use initial data structures  

---

**Document Version:** 1.0.0  
**Last Updated:** January 4, 2026  
**Author:** Megh Modi
