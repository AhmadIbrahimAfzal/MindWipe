# Product Requirements Document (PRD)
## Project: Zero-Friction Aesthetic Task & Habit Tracker

### 1. Project Overview
An ultra-minimal, widget-first task storage and reminder application designed primarily for Android. The application fills the gap for high-aesthetic, non-corporate productivity tools on the Android platform. It prioritizes frictionless capture and visually satisfying micro-interactions over complex nested menus and gamification. 

### 2. Inspirations & Core Philosophy
* **Did I do? (iOS):** Inspiration for home-screen-first interactions and satisfying, single-tap widget completions.
* **mymind (iOS):** Inspiration for the "private, calming oasis" feel and the zero-friction, folder-less brain dump approach to capturing tasks.
* **Design Language:** Clean, elegant, material-inspired but highly customized. Focus on fluid animations, glassmorphic elements, soft shadows, and generous negative space. 
* **Feature Scope constraint:** No gamification for the Phase 1 MVP to prevent feature creep.

### 3. Tech Stack Requirements
* **Core Application Framework:** Flutter (Dart) for high-fidelity custom UI and future-proofing for iOS deployment.
* **Widget Development:** Native Kotlin using Jetpack Glance to ensure Android widgets are highly responsive, modern, and deeply integrated with the OS.
* **Local Storage:** Offline-first database (e.g., Isar, Hive, or SQLite via Flutter) for instant load times.
* **Communication Bridge:** Method channels to sync state bi-directionally between Native Kotlin widgets and the Flutter backend.

### 4. Core App Functionality (MVP)
* **The "Inbox" (Main App Screen):** A beautifully uncluttered central feed where all captured thoughts and tasks live without forced categorization.
* **Frictionless Entry:** The ability to open the app and add a task in under two seconds.
* **State Syncing:** Widgets must reflect the app's state immediately, and actions taken on widgets must update the app's backend without fully launching the Flutter UI.

### 5. Widget Concepts (The "Secret Sauce")
The application will feature three primary home screen widgets, designed to minimize the need to actually open the app.

#### A. The "Micro-Habit" Pill (1x1 or 2x1)
* **Purpose:** Tracking a single, daily recurring action (e.g., "Hit 100g Protein target", "Take Creatine").
* **UI/UX:** A minimalist, glassmorphic pill shape.
* **Interaction:** Tapping the widget on the home screen triggers a satisfying fill animation (like liquid filling a capsule) or a smooth gradient color shift. Zero app navigation required.

#### B. The "Frictionless Brain Dump" Bar (4x1 or 4x2)
* **Purpose:** Instant capture of fleeting thoughts and to-dos (e.g., "Order 20mm metal Casio spring bars", "Pack trekking gear for Fairy Meadows").
* **UI/UX:** A clean, translucent search-bar style input resting on the home screen.
* **Interaction:** Tapping immediately invokes the system keyboard. Hitting 'Enter' triggers a dissolve or swoosh animation, sending the text directly to the app's central inbox without asking for tags or due dates. The widget resets instantly.

#### C. The "Aesthetic Timeline" Stack (2x3 or 4x3)
* **Purpose:** Visualizing the day's flow without the visual clutter of a traditional corporate calendar.
* **UI/UX:** Tasks appear as floating, rounded cards utilizing deep negative space. Past tasks fade into a subtle opacity. 
* **Interaction:** Tapping a card expands it for details (e.g., "Chest & Triceps Split - 5 exercises"). Native swipe gestures dismiss completed items with a haptic snap.
