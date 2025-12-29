# Lead Management App - Step 1

Flutter + Firebase Lead Management App with Authentication and Role-Based Navigation.

## Features

- ✅ Firebase Authentication (Email/Password)
- ✅ User Model with role-based access (Admin/Sales)
- ✅ Firestore integration for user data
- ✅ Riverpod state management
- ✅ Clean Architecture
- ✅ Role-based navigation (Admin → AdminHomeScreen, Sales → SalesHomeScreen)
- ✅ Route guards and access control
- ✅ Inactive user blocking
- ✅ Logout functionality
- ✅ Loading and error states

## Tech Stack

- **Flutter** (Web + Android)
- **Firebase Auth** (Email/Password)
- **Cloud Firestore**
- **Riverpod** (State Management)
- **Clean Architecture**

## Project Structure

```
lib/
├── core/
│   ├── constants/      # App constants (Firebase collections, etc.)
│   ├── errors/         # Error handling (Failures)
│   └── utils/          # Utility functions
├── data/
│   ├── models/         # Data layer models (Firestore models)
│   └── repositories/   # Repository implementations
├── domain/
│   ├── models/         # Domain models (Business entities)
│   └── repositories/   # Repository interfaces
└── presentation/
    ├── providers/      # Riverpod providers
    ├── screens/        # UI screens
    └── widgets/        # Reusable widgets
```

## Setup Instructions

### 1. Prerequisites

- Flutter SDK (3.9.2 or higher)
- Firebase project with Authentication and Firestore enabled
- FlutterFire CLI (optional, for auto-configuration)

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

#### Option A: Using FlutterFire CLI (Recommended)

1. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

2. Configure Firebase:
```bash
flutterfire configure
```

This will automatically generate `lib/firebase_options.dart` with your Firebase configuration.

#### Option B: Manual Configuration

1. Go to Firebase Console → Project Settings
2. Add Web and Android apps to your Firebase project
3. Download configuration files:
   - Web: Copy config from Firebase Console
   - Android: Download `google-services.json` and place in `android/app/`
4. Update `lib/firebase_options.dart` with your Firebase configuration

### 4. Firestore Setup

Create a `users` collection in Firestore with the following document structure:

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "role": "admin",  // or "sales"
  "region": "india",  // or "usa"
  "active": true
}
```

**Important:** The document ID should match the Firebase Auth UID.

### 5. Firebase Authentication Setup

1. Go to Firebase Console → Authentication
2. Enable Email/Password authentication
3. Create test users or use the Authentication UI to create users

### 6. Run the App

#### Web:
```bash
flutter run -d chrome
```

#### Android:
```bash
flutter run
```

## User Roles

- **Admin**: Access to `AdminHomeScreen`
- **Sales**: Access to `SalesHomeScreen`

## User Model

The User model contains:
- `uid`: Firebase Auth UID
- `name`: User's full name
- `email`: User's email address
- `role`: User role (`admin` or `sales`)
- `region`: User region (`india` or `usa`)
- `active`: Boolean flag for account status

## Authentication Flow

1. User enters email and password on LoginScreen
2. Firebase Auth authenticates the user
3. App fetches user document from Firestore `users/{uid}`
4. If user is inactive, access is blocked
5. Based on role, user is routed to:
   - Admin → `AdminHomeScreen`
   - Sales → `SalesHomeScreen`

## Route Guards

The `AuthGuard` widget handles:
- Loading state during authentication check
- Redirecting unauthenticated users to LoginScreen
- Blocking inactive users
- Role-based routing

## Logout

Logout functionality is available in both Admin and Sales home screens via the logout button in the AppBar.

## Next Steps (Not Included in Step 1)

- Lead management features
- Notifications
- Dashboards
- Additional screens

## Notes

- All dropdown data should come from Firestore `dropdowns` collection (for future steps)
- The app uses Clean Architecture for maintainability
- Riverpod is used for state management following latest patterns
- Error handling is implemented with custom Failure classes
