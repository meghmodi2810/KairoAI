Chapter 1:  Introduction
1.1	Problem Definition
Indian Sign Language (ISL) still doesn’t have good, easy-to-use digital resources - not even for the basics like the alphabet or numbers. Most of what’s out there is just static content, so learners never really know if they’re doing the signs right. There’s no real-time feedback, no way to check your work as you go. People end up confused, picking up mistakes, and needing to rely on face-to-face teaching. Without interactive tools that offer feedback, learning ISL on your own feels almost impossible and pretty unreliable.

1.2	Project Purpose
The purpose of this project is to enable learners to accurately learn and practice the fundamentals of Indian Sign Language—specifically alphabets (A–Z) and numbers (0–9)—in a self-guided manner. The project aims to make independent ISL learning more reliable by allowing learners to verify their sign performance during practice, reduce confusion, and avoid developing incorrect signing habits, thereby minimizing dependence on face-to-face instruction for basic ISL skills.

1.3	Project Scope
The scope of this project is limited to teaching and practicing Indian Sign Language alphabets (A–Z) and numbers (0–9). The system focuses on recognizing single-hand sign gestures performed in front of a device camera and validating them individually. The project includes guided practice and basic assessment of these signs only.
The project does not cover sentence formation, word-level signing, two-hand complex gestures, facial expressions, regional ISL variations, or advanced vocabulary. It is intended as a foundational learning tool and does not aim to replace formal ISL instruction or human teachers.
 
Chapter 2: Overall Description
2.1 Product Perspective/Environment Description

KairoAI is a standalone mobile learning application designed to teach Indian Sign Language (ISL) to children aged 6-14 using real-time AI-powered hand gesture recognition. The product operates within the following context:

Aspect	Description
System Type	Cross-platform mobile application (Android primary, iOS future)
Architecture	Hybrid architecture with Flutter UI layer + Native Kotlin ML layer
Backend	Firebase-as-a-Service (BaaS) - serverless architecture
AI Pipeline		On-device ML inference (no cloud dependency for detection)
User Environment		Personal smartphones/tablets with camera access
Connectivity		Internet required for authentication, progress sync, and content updates.



2.1.1 Hardware Interface/ Hardware Specification


	Supported devices

Platform	Version	Notes
Android	API 26+ (Android 8+, oreo+)	Primary platform
IOS	IOS 12+	Future support
Tablets	7’’ – 12’’ screen	Fully supported





	Other specifications

Component	Requirements
Processor	Quad-core 1.5 GHz+
RAM	3 GB minimum
Storage	600 MB available
Camera	Front-facing, 5MP+
Display	5’’ – 12’’, 480p+
GPU	OpenGL ES 3.0
Network	WiFi / Mobile Data


2.1.2 Software Interface/ Software Specification

	Development Tech Stack

Layer	Technology	Version	Purpose
Frontend Framework	Flutter	3.16+	Cross-platform UI development
Programming Language for UI	Dart	3.2+	Flutter application logic and frontend
Programming Language for Backend	Kotlin	1.9+	Native android and ML integration

	AI/ML integration tech stack

Layer	Version	Purpose
Mediapipe tasks vision	0.10.14	Hand landmark detection (21 landmarks and palm or front)
Tensorflow lite	3.2+	Flutter application logic and frontend

	Database services

Service	Purpose	Libraries and version
Firebase authentication	User sign-in (Email / Password, Google account integration)	firebase_auth : ^4.16.0
Cloud firebase	NoSQL database for user data, lessons, progress	cloud_firestore : ^4.14.0
Firebase storage	Media storage (Images for profile pic)	firebase_storage : ^11.6.0
Firebase analytics	User tracking and insights	firebase_analytics : ^10.8.0


	AI/ML Libraries for model training

Library	Version	Purpose
Tensorflow	2.15.0	Deep learning framework for model training
Mediapipe	0.10.9	Hand landmark detection and extraction
OpenCV	4.8.1	Image processing module
NumPy	1.26.2	Numerical operations for landmarks
Pandas	2.1.3	Dataset manipulation and csv creation
Scikit-learn	1.3.2	Train/Test splitting and metrics

 
Chapter 3: System Specific Requirements

3.1 Functional Requirements
	User Authentication :-
Requirement No.	Description	Comment
FR1	The system shall allow users to register using email address and password.	Account creation
FR2	The system shall allow users to authenticate using email address and password.	Login mechanism
FR3	The system shall support authentication via Google Sign-In.	Third-party authentication
FR4	The system shall provide a password reset mechanism via email verification.	Account recovery
FR5	The system shall maintain user session state across application launches.	Session persistence
FR6	The system shall allow users to log out and terminate their session.	Session termination
FR7	The system shall validate email format during registration.	Input validation
FR8	The system shall enforce minimum password strength requirements.	Security constraint


3.2 Non- Functional Requirements
(Non-functional requirements describe system qualities such as performance, security, and usability.)
Requirement No.	Description	Comment
NFR1		
NFR2		

Chapter 4: System Analysis
4.1 Use Case Diagrams
(Provide a diagram to illustrate how users interact with the system.)

4.2 Activity Diagrams
(Include an activity diagram that outlines the flow of activities within the system.)

















Chapter 5: System Design
5.1 System Design (Describes the database structure.)

5.1.1 Data Dictionary
	USER
Field Name	Datatype	Size	Constraint	Description
user_id	VARCHAR	128	PRIMARY KEY	Firebase authentication UID
email	VARCHAR	255	UNIQUE, NOT NULL	User’s email address
display_name	VARCHAR	100	NOT NULL	User’s display name
photo_url	TEXT	-	-	Profile photo URL for user
created_at	TIMESTAMP	-	NOT NULL	Account creation date and time
last_login_at	TIMESTAMP	-	NOT NULL	Last login timestamp


	USER_STATS
Field Name	Datatype	Size	Constraint	Description
user_id	VARCHAR	128	FOREIGN KEY, PRIMARY KEY	User id reference from USER table
gems	INT	-	DEFAULT 0	Game currency (gems)
coins	INT	-	DEFAULT 0	Game currency (coins)
xp	INT	-	DEFAULT 0	User’s experience point for progression
current_level	INT	-	DEFAULT 1	Current level of the user
streak_days	INT	-	DEFAULT 0	User’s consecutive login days
last_streak_day	DATE	-	-	Last streak day of user
total_lessons_completed	INT	-	DEFAULT 0	Total finished sessions
total_signs_learned		INT	-	DEFAULT 0	Total number of signs learned
total_practice_minutes		INT	-	DEFAULT 0	Total number of minutes practiced






	USER_PREFERENCES
Field Name	Datatype	Size	Constraint	Description
user_id	VARCHAR	128	FOREIGN KEY, PRIMARY KEY	User id reference from USER table
learning_goal		VARCHAR	255	NULL	User’s learning objective
daily_goal_minutes		INT	-	DEFAULT 10	Daily practice learning minutes
onboarding_completed		BOOLEAN	-	DEFAULT FALSE	Onboarding status
preferred_language	VARCHAR	1	DEFAULT ‘en’	Preferred language
notifications_enabled		BOOLEAN	-	DEFAULT FALSE	Push notifications settings on/off


	CATEGORIES
Field Name	Datatype	Size	Constraint	Description
category_id		VARCHAR	50	PRIMARY KEY	Category id’s for the category table
name	VARCHAR	100	NOT NULL	Category display name
description		TEXT	-	NOT NULL	Category description
icon_url	TEXT	-	NULL	Category icon url reference address
total_lessons	INT	-	NOT NULL	Total number of lessons in the category
total_signs	INT	-	NOT NULL	Total number of signs in the category
is_locked	BOOLEAN	-	DEFAULT TRUE	If the category is locked or not
required_level	INT	-	DEFAULT 1	Level needed to unlock the category
created_at	TIMESTAMP	-	NOT NULL	Created timestamp

	LESSONS
Field Name	Datatype	Size	Constraint	Description
lesson_id	VARCHAR	100	PRIMARY KEY	Unique Identifier for lessons
category_id	VARCHAR	50	FK → CATEGORIES, NOT NULL		Reference from categories
unit_number	INT	-	NOT NULL	Unit number within the category
title	VARCHAR	100	NOT NULL	Lesson title
description	TEXT	-	NOT NULL	Detailed description of the lesson
thumbnail_url	TEXT	-	NULL	Thumbnail url of lesson
display_order	INT	-	NOT NULL	Display order of lessons
total_signs	INT	-	NOT NULL	Total number of signs
estimated_minutes	INT	-	NOT NULL	Estimated completion time of lesson
difficulty	ENUM(‘Beginner’, ‘Intermediate’, ‘Advanced’)	-	NOT NULL	Difficulty level of each lesson
gems_reward	INT	-	DEFAULT 0	Gems rewarded in the lesson
coins_reward	INT	-	DEFAULT 0	Coins rewarded in the lesson
xp_reward	INT	-	DEFAULT 0	Xp rewarded in the lesson
is_locked	BOOLEAN	-	DEFAULT FALSE	Lock status of the lesson
required_lesson_id	VARCHAR	100	FK → LESSONS, NULL		Prerequisite lesson
created_at	TIMESTAMP	-	NOT NULL	Created timestamp


	SIGNS
Field Name	Datatype	Size	Constraint	Description
sign_id	VARCHAR	100	PRIMARY KEY	Unique identifier of signs
lesson_id	VARCHAR	100	FK → LESSONS, NOT NULL	Parent lesson
word	VARCHAR	100	NOT NULL	Signs alphabet
display_order	INT	-	NOT NULL	Display order of the signs
image_url	TEXT	-	NULL	Static image URL
description	TEXT	-	NOT NULL	Description of the sign
is_locked	BOOLEAN	-	DEFAULT TRUE	If the category is locked or not
required_level	INT	-	DEFAULT 1	Level needed to unlock the category
created_at	TIMESTAMP	-	NOT NULL	Created timestamp


	USER_LESSON_PROGRESS
Field Name	Datatype	Size	Constraint	Description
progress_id	INT	-	PRIMARY KEY, AUTO_INCREMENT	Unique id for each user’s progress
user_id	VARCHAR	128	FK → USERS, NOT NULL	Reference from user’s table
lesson_id	VARCHAR	100	FK → LESSONS, NOT NULL		Reference from lesson table
category_id	VARCHAR	50	FK → CATEGORIES, NOT NULL		Reference from category
status	ENUM(‘Not Started’, ‘In Progress’, ‘Completed’)	-	DEFAULT Not Started	Progress of each lesson of user
started_at	TIMESTAMP	-	NULL	Time when the user started the lesson
completed_at	TIMESTAMP	-	NULL	Time when the user completed the lesson
accuracy	DECIMAL(5,2)	-	DEFAULT 0	Accuracy percentage between 0 -100
time_spent_seconds	INT	-	DEFAULT 0	Time spend on each lesson
attempts_count	INT	-	DEFAULT 0	Total number of attempts for each lesson
gems_earned	INT	-	DEFAULT 0	Total gems earned from each lesson
coins_earned	INT	-	DEFAULT 0	Total coins earned from each lesson
UNIQUE	(user_id, lesson_id)	Prevent duplicate user’s progress



	USER_LESSON_PROGRESS
Field Name	Datatype	Size	Constraint	Description
user_sign_progress_id	INT	-	PRIMARY KEY, AUTO_INCREMENT	Unique id for each user’s lesson progress
progress_id	INT	-	FK → USER_LESSON_PROGRES, NOT NULL		Reference from user_lesson_progress table
sign_id	VARCHAR	100	FK → SIGNS, NOT NULL		Reference from signs table
completed_at	TIMESTAMP	-	NOT NULL	Timestamp of sign completion
UNIQUE	(progress_id, sign_id)	To prevent duplication of signs learned

	ACHIEVEMENTS
Field Name	Datatype	Size	Constraint	Description
achievements_id	VARCHAR	50	PRIMARY KEY	Unique identifier for achievements
name	VARCHAR	100	NOT NULL	Achievement display name
description	TEXT	-	NOT NULL	Achievement description
icon_url	TEXT	-	NOT NULL	Achievement icon photo url
type	ENUM(‘Milestone’, ‘Streak’, ‘Mastery’, ‘Social’)	-	NOT NULL	Achievement type
requirement_type	VARCHAR	100	NOT NULL	Requirement type of achievements
requirement_value	INT	-	NOT NULL	Value needed to unlock that achievement
gems_reward	INT	-	DEFAULT 0	Gems rewards for this achievement
coins_reward	INT	-	DEFAULT 0	Coins rewards for this achievement
xp_rewards	INT	-	DEFAULT 0	Xp rewards for this achievement
is_hidden	BOOLEAN	-	DEFAULT FALSE	Hidden achievement flag
display_order	INT	-	NOT NULL	Display order of the achievement
created_at	TIMESTAMP	-	NOT NULL	Creation timestamp

	USER_ACHIEVEMENTS
Field Name	Datatype	Size	Constraint	Description
user_achievements_id	VARCHAR	50	PRIMARY KEY	Unique identifier for achievements
user_id	VARCHAR	128	FK → USERS, NOT NULL		User reference
achievement_id	VARCHAR	-	FK → ACHIEVEMENTS, NOT NULL		Reference from achievements table
unlocked_at	TIMESTAMP	-	NOT NULL	Timestamp of when it is unlocked
claimed	BOOLEAN	-	DEFAULT FALSE	Reward claimed status
claimed_at	TIMESTAMP	-	NULL	When was reward unlocked
UNIQUE	(user_id, achievement_id)	Prevents duplicate
	USER_ACTIVITY_LOG
Field Name	Datatype	Size	Constraint	Description
activity_id	INT	-	PRIMARY KEY, AUTO_INCREMENT	Unique ID for activity
user_id	VARCHAR	128	FK → USERS, NOT NULL		User reference
activity_type	VARCHAR	50	NOT NULL	Activity type for logs i.e., login, lesson_start, lesson_end, etc.
activity_timestamp	DATE	-	NOT NULL	Activity timestamp
reference_id	VARCHAR	100	NULL	Related lesson_id, session_id, etc
metadata	JSON	-	NULL	Additional activity logs
