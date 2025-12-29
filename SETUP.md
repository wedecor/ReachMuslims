# Quick Setup Guide

## Firebase Configuration Required

Before running the app, you need to configure Firebase:

### 1. Install FlutterFire CLI (Recommended)
```bash
dart pub global activate flutterfire_cli
```

### 2. Configure Firebase
```bash
flutterfire configure
```

This will:
- Detect your Firebase projects
- Generate `lib/firebase_options.dart` with proper configuration
- Set up Android and Web platforms

### 3. Firestore Setup

Create a `users` collection in Firestore. Each document should:
- Use the Firebase Auth UID as the document ID
- Contain these fields:
  ```json
  {
    "name": "John Doe",
    "email": "john@example.com",
    "role": "admin",  // or "sales"
    "region": "india",  // or "usa"
    "active": true
  }
  ```

### 4. Firebase Authentication

Enable Email/Password authentication in Firebase Console:
1. Go to Authentication → Sign-in method
2. Enable Email/Password provider
3. Create test users or use the console to create users

### 5. Test User Creation Example

To create a test user:
1. Create user in Firebase Authentication (Email/Password)
2. Copy the UID
3. Create a document in Firestore `users` collection with that UID
4. Add the required fields (name, email, role, region, active)

## Running the App

```bash
# Web
flutter run -d chrome

# Android
flutter run
```

## Project Structure Summary

- **Domain Layer**: Business logic and entities (`User` model, `AuthRepository` interface)
- **Data Layer**: Firebase implementations (`AuthRepositoryImpl`, `UserModel`)
- **Presentation Layer**: UI screens and Riverpod providers
- **Core**: Constants, errors, utilities

## Key Features Implemented

✅ Email/Password authentication  
✅ User document fetching from Firestore  
✅ Role-based navigation (Admin/Sales)  
✅ Inactive user blocking  
✅ Logout functionality  
✅ Loading and error states  
✅ Clean Architecture structure  
✅ Riverpod state management  

