# Deployment Version Guide

## ⚠️ IMPORTANT: Always Increment Version/Build Number Before Deployment

### Why?
**Every deployment must increment the build number** to avoid package conflict errors when users update the app. This is especially critical for Android APK installations.

### Version Format
```
version: X.Y.Z+BUILD_NUMBER
```
- **X.Y.Z** = Version number (e.g., 1.3.0)
- **BUILD_NUMBER** = Build number (must increment for each deployment)

### Deployment Checklist

#### Before Every Deployment:
1. ✅ **Increment build number** in `pubspec.yaml`
   - Example: `1.3.0+7` → `1.3.0+8`
   - For major features, increment version: `1.3.0+8` → `1.4.0+1`
   
2. ✅ **Build the app** with new version:
   ```bash
   flutter build web --release      # For web
   flutter build apk --release      # For Android
   ```

3. ✅ **Deploy**:
   ```bash
   firebase deploy --only hosting   # For web
   ```

4. ✅ **Commit and push** the version change:
   ```bash
   git add pubspec.yaml
   git commit -m "chore: Bump version to X.Y.Z+BUILD_NUMBER for deployment"
   git push origin main
   ```

### Version Numbering Strategy

- **Patch (Z)**: Bug fixes, small improvements → `1.3.0` → `1.3.1`
- **Minor (Y)**: New features, enhancements → `1.3.0` → `1.4.0`
- **Major (X)**: Breaking changes, major rewrites → `1.3.0` → `2.0.0`
- **Build Number (+N)**: Always increment for every deployment

### Current Version
Check `pubspec.yaml` for current version.

### Failure to Increment
If you forget to increment the build number:
- Android users will get "Package conflict" error when trying to install
- App stores may reject the update
- Users cannot update the app

**Always increment before deployment!**

