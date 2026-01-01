# How to Check for Issues in the App

This guide covers multiple ways to identify and check for issues in your Flutter application.

## 1. Static Analysis (Linter)

### Run Flutter Analyze
```bash
flutter analyze
```

This command will:
- Check for syntax errors
- Find potential bugs
- Identify code style issues
- Show warnings and errors
- Check for unused imports/variables

### In Your IDE (VS Code / Android Studio)
- Issues are automatically shown in the Problems panel
- Red squiggles = errors
- Yellow squiggles = warnings
- Blue squiggles = info/hints

## 2. Run Tests

### Run All Tests
```bash
flutter test
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### Run Specific Test Files
```bash
flutter test test/domain/models/lead_test.dart
```

## 3. Build Checks

### Check if App Compiles
```bash
# For Android
flutter build apk --debug

# For iOS
flutter build ios --debug

# For Web
flutter build web
```

### Check for Build Errors
```bash
flutter build apk --debug 2>&1 | tee build_errors.log
```

## 4. Validation Scripts

### Run Full Validation
```bash
./validate.sh
```

### Run Go/No-Go Validation
```bash
./validate_gonogo.sh
```

## 5. Dependency Checks

### Check for Outdated Packages
```bash
flutter pub outdated
```

### Check for Vulnerable Dependencies
```bash
flutter pub audit
```

### Verify Dependencies
```bash
flutter pub get
flutter pub upgrade
```

## 6. Code Quality Checks

### Check for Unused Code
```bash
# Install dart_code_metrics (if not already installed)
flutter pub add --dev dart_code_metrics

# Run metrics
dart run dart_code_metrics:metrics analyze lib
```

### Check for Code Duplication
```bash
dart run dart_code_metrics:metrics check lib
```

## 7. Runtime Checks

### Run in Debug Mode with Verbose Logging
```bash
flutter run --verbose
```

### Check for Memory Leaks
- Use Flutter DevTools
- Monitor memory usage
- Check for widget rebuild issues

### Check Performance
```bash
flutter run --profile
```

## 8. Firestore/Firebase Checks

### Verify Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### Check Firestore Indexes
```bash
firebase deploy --only firestore:indexes
```

### Test Firestore Rules
- Use Firebase Console
- Use Firestore Rules Playground

## 9. Common Issues to Check

### Enum Conversion Issues
- Check `fromString` methods for case-sensitivity bugs
- Verify enum names match Firestore data
- Check default values

### Null Safety Issues
- Check for missing null checks
- Verify nullable types are handled
- Check for potential null pointer exceptions

### Data Model Issues
- Verify Firestore serialization/deserialization
- Check for missing fields
- Verify default values

### State Management Issues
- Check for memory leaks in providers
- Verify state updates correctly
- Check for unnecessary rebuilds

### UI/UX Issues
- Check for layout overflow errors
- Verify responsive design
- Check accessibility

## 10. Automated Issue Detection

### Create a Comprehensive Check Script

Save this as `check_all_issues.sh`:

```bash
#!/bin/bash

echo "=== Running Flutter Analyze ==="
flutter analyze

echo -e "\n=== Checking Dependencies ==="
flutter pub outdated

echo -e "\n=== Running Tests ==="
flutter test

echo -e "\n=== Checking Build ==="
flutter build apk --debug --no-tree-shake-icons

echo -e "\n=== All Checks Complete ==="
```

## 11. IDE-Specific Checks

### VS Code
- Problems panel (Ctrl+Shift+M / Cmd+Shift+M)
- Output panel for build errors
- Dart DevTools extension

### Android Studio
- Problems tool window
- Build output window
- Flutter Inspector

## 12. Continuous Integration

### GitHub Actions / CI Pipeline
- Run `flutter analyze` on every commit
- Run tests automatically
- Check build on multiple platforms

## Quick Reference Commands

```bash
# Quick check (most common)
flutter analyze

# Full validation
./validate.sh

# Test everything
flutter test

# Check dependencies
flutter pub outdated

# Build check
flutter build apk --debug
```

## Tips

1. **Run `flutter analyze` regularly** - Catches most issues early
2. **Fix warnings, not just errors** - Warnings can become bugs
3. **Run tests before committing** - Catch regressions early
4. **Use IDE linter** - Real-time feedback while coding
5. **Check logs** - Runtime errors show in console/logs
6. **Monitor Firebase Console** - Check for Firestore errors
7. **Use Flutter DevTools** - Profile and debug performance issues

