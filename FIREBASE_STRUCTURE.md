# KairoAI Firebase Database Structure

## Overview
This document outlines the complete Firebase Firestore database structure for KairoAI - the Indian Sign Language learning app.

---

## Collections Structure

```
firestore/
├── users/
│   └── {userId}/
│       ├── profile (document fields)
│       └── progress/ (subcollection)
│           └── {lessonId}/
├── categories/
│   └── {categoryId}/
│       └── lessons/ (subcollection)
│           └── {lessonId}/
│               └── signs/ (subcollection)
│                   └── {signId}/
├── daily_insights/
│   └── {insightId}/
├── achievements/
│   └── {achievementId}/
└── leaderboard/
    └── {userId}/
```

---

## 1. Users Collection

### Path: `users/{userId}`

```json
{
  "uid": "firebase_auth_uid",
  "email": "user@example.com",
  "displayName": "John Doe",
  "photoUrl": "https://...",
  "createdAt": "Timestamp",
  "lastLoginAt": "Timestamp",
  
  // Gamification
  "gems": 144,
  "coins": 2321,
  "streakDays": 7,
  "lastStreakDate": "Timestamp",
  
  // Settings from onboarding
  "learningGoal": "Communicate with family",
  "dailyGoalMinutes": 10,
  
  // Progress summary
  "totalLessonsCompleted": 15,
  "totalSignsLearned": 45,
  "totalPracticeMinutes": 120,
  "currentLevel": 3,
  "xp": 1250
}
```

### Subcollection: `users/{userId}/progress/{lessonId}`

```json
{
  "lessonId": "greetings_unit1",
  "categoryId": "greetings",
  "status": "completed", // "not_started", "in_progress", "completed"
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

## 2. Categories Collection

### Path: `categories/{categoryId}`

```json
{
  "id": "greetings",
  "name": "Greetings",
  "description": "Learn common greeting signs",
  "iconUrl": "https://...",
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

**Sample Categories:**
- `greetings` - Greetings (👋)
- `numbers` - Numbers (🔢)
- `history` - History (📜)
- `alphabets` - Alphabets (🔤)
- `family` - Family (👨‍👩‍👧‍👦)
- `emotions` - Emotions (😊)
- `food` - Food & Drinks (🍎)
- `animals` - Animals (🐕)
- `colors` - Colors (🎨)
- `daily_words` - Daily Words (📝)

### Subcollection: `categories/{categoryId}/lessons/{lessonId}`

```json
{
  "id": "greetings_unit1",
  "categoryId": "greetings",
  "unitNumber": 1,
  "title": "Greetings",
  "subtitle": "Basic greeting signs",
  "description": "Learn to say hello, goodbye, and thank you in ISL",
  "thumbnailUrl": "https://...",
  "order": 1,
  "totalSigns": 4,
  "estimatedMinutes": 5,
  "difficulty": "beginner", // "beginner", "intermediate", "advanced"
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

### Subcollection: `categories/{categoryId}/lessons/{lessonId}/signs/{signId}`

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
    // Normalized landmark positions for validation (optional)
    "fingerSpread": 0.2,
    "palmDirection": "outward"
  },
  "createdAt": "Timestamp"
}
```

---

## 3. Daily Insights Collection

### Path: `daily_insights/{insightId}`

```json
{
  "id": "insight_20251231",
  "date": "2025-12-31",
  "title": "Day Insight",
  "message": "Listen every Day Insight about your education",
  "tip": "Practice makes perfect! Try to practice for at least 10 minutes daily.",
  "funFact": "Did you know? ISL has regional variations across India!",
  "motivationalQuote": "Every sign you learn brings you closer to connection.",
  "audioUrl": "https://...", // Optional audio insight
  "imageUrl": "https://...",
  "isActive": true,
  "createdAt": "Timestamp"
}
```

---

## 4. Achievements Collection

### Path: `achievements/{achievementId}`

```json
{
  "id": "first_lesson",
  "name": "First Steps",
  "description": "Complete your first lesson",
  "iconUrl": "https://...",
  "iconEmoji": "🎯",
  "type": "milestone", // "milestone", "streak", "mastery", "social"
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

**Sample Achievements:**
- `first_lesson` - Complete first lesson
- `streak_7` - 7 day streak
- `streak_30` - 30 day streak
- `alphabets_master` - Learn all alphabets
- `category_complete_greetings` - Complete Greetings category
- `perfect_score` - Get 100% on a lesson
- `speed_learner` - Complete lesson under 3 minutes
- `practice_100` - Practice for 100 minutes total

---

## 5. Leaderboard Collection

### Path: `leaderboard/{userId}`

```json
{
  "userId": "firebase_auth_uid",
  "displayName": "John Doe",
  "photoUrl": "https://...",
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

## 6. User Achievements Subcollection

### Path: `users/{userId}/achievements/{achievementId}`

```json
{
  "achievementId": "first_lesson",
  "unlockedAt": "Timestamp",
  "claimed": true,
  "claimedAt": "Timestamp"
}
```

---

## Firebase Storage Structure

```
storage/
├── signs/
│   ├── images/
│   │   └── {signId}.png
│   ├── gifs/
│   │   └── {signId}.gif
│   └── videos/
│       └── {signId}.mp4
├── categories/
│   └── icons/
│       └── {categoryId}.png
├── achievements/
│   └── icons/
│       └── {achievementId}.png
├── mascot/
│   └── robot_*.png
└── users/
    └── {userId}/
        └── profile.jpg
```

---

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /progress/{lessonId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /achievements/{achievementId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Categories and lessons are public read
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
    
    // Daily insights are public read
    match /daily_insights/{insightId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    // Achievements are public read
    match /achievements/{achievementId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    // Leaderboard is public read, users can update their own entry
    match /leaderboard/{odocId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == docId;
    }
  }
}
```

---

## Sample Data for Initial Setup

### Categories to Create:
1. **Greetings** - Hello, Goodbye, Thank You, Please, Sorry
2. **Numbers** - 1-10, then 11-20, etc.
3. **Alphabets** - A-Z (can be split into multiple lessons)
4. **Family** - Mother, Father, Brother, Sister, etc.
5. **Emotions** - Happy, Sad, Angry, Excited, etc.
6. **Daily Words** - Yes, No, Help, Water, Food, etc.

### Recommended Lesson Structure:
- Each category has 3-5 units
- Each unit has 4-6 signs
- Estimated time: 5-10 minutes per unit
- Progressive difficulty within category

---

## Indexes Required

Create composite indexes in Firestore for these queries:

1. `categories` - order by `order` ascending
2. `lessons` - order by `order` ascending, filter by `categoryId`
3. `signs` - order by `order` ascending, filter by `lessonId`
4. `leaderboard` - order by `xp` descending
5. `leaderboard` - order by `weeklyXp` descending
6. `users/{userId}/progress` - order by `completedAt` descending

---

## Cloud Functions (Optional)

For automated tasks, consider these Cloud Functions:

1. **onUserCreate** - Initialize user document with default values
2. **onLessonComplete** - Update leaderboard, check achievements
3. **dailyStreakCheck** - Reset streaks for inactive users (scheduled)
4. **weeklyLeaderboardReset** - Reset weekly XP (scheduled)

---

This structure supports:
- ✅ Scalable lesson content
- ✅ User progress tracking
- ✅ Gamification (gems, coins, XP)
- ✅ Achievements system
- ✅ Leaderboards
- ✅ Daily insights/tips
- ✅ Offline capability (Firestore caching)
