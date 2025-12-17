# Complete Supabase Auth Migration Guide

This guide covers the complete migration from Firebase Authentication to Supabase Authentication with native Google Sign-In support for all platforms.

## ✅ Completed Migration Steps

### 1. Updated Dependencies

**Removed Firebase packages:**

- `firebase_core`
- `firebase_auth`
- `firebase_storage`
- `firebase_ai`

**Added Supabase package:**

- `supabase_flutter: ^2.8.0`

**Kept for native Google Sign-In:**

- `google_sign_in: ^6.2.1`

### 2. Updated Authentication Service

Migrated `lib/services/auth_service.dart` to use Supabase Auth:

- Replaced Firebase Auth with Supabase Auth client
- Implemented native Google Sign-In with ID token exchange
- Updated all auth methods (email/password sign-in, sign-up, password reset, etc.)
- Added automatic user profile creation in Supabase database
- Updated error handling for Supabase AuthException

### 3. Updated Main App Initialization

Modified `lib/main.dart`:

- Removed Firebase initialization
- Added Supabase initialization with PKCE auth flow
- Requires `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `.env` file

### 4. Updated Auth Wrapper

Modified `lib/screens/auth/auth_wrapper.dart`:

- Changed from Firebase User to Supabase User
- Updated auth state stream

### 5. Android Configuration

**Updated files:**

- `android/app/build.gradle.kts` - Removed google-services plugin
- `android/settings.gradle.kts` - Removed google-services plugin
- `android/app/src/main/AndroidManifest.xml` - Added deep linking for auth callback

**Removed files:**

- `android/app/google-services.json` - ✅ (Already didn't exist)

**Added deep linking:**

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="com.kanso.mirei.mirei"
        android:host="login-callback" />
</intent-filter>
```

### 6. iOS Configuration

**Updated files:**

- `ios/Runner/Info.plist` - Updated URL schemes and added Google Sign-In configuration

**Removed files:**

- `ios/Runner/GoogleService-Info.plist` - ✅ Deleted

**Added configuration:**

- Supabase auth callback URL scheme
- Google Sign-In URL scheme (requires iOS client ID)
- GIDClientID for native Google Sign-In

### 7. Removed Firebase Files

- ✅ Deleted `lib/firebase_options.dart`
- ✅ Deleted `ios/Runner/GoogleService-Info.plist`

---

## 🔧 Required Configuration Steps

### Step 1: Configure Google Cloud Console

You need to set up OAuth credentials for all platforms:

#### 1.1 Web Client (Already have)

Your web client ID: `50437670825-hlhi6qesougc52clkk90pbccika7a177.apps.googleusercontent.com`

#### 1.2 Android Client with SHA-1

1. Get your SHA-1 fingerprint:

```bash
# Debug SHA-1
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release SHA-1 (when you have a release keystore)
keytool -list -v -keystore /path/to/your-release-key.keystore -alias your-alias
```

2. In Google Cloud Console (https://console.cloud.google.com/):
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth 2.0 Client ID"
   - Application type: **Android**
   - Name: "Mirei Android"
   - Package name: `com.kanso.mirei.mirei`
   - SHA-1 certificate fingerprint: (paste your debug SHA-1)
   - Click "Create"

#### 1.3 iOS Client

1. In Google Cloud Console:

   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth 2.0 Client ID"
   - Application type: **iOS**
   - Name: "Mirei iOS"
   - Bundle ID: `com.kanso.mirei.mirei`
   - Click "Create"

2. Copy the iOS Client ID (format: `XXXXXXX-YYYYYYYY.apps.googleusercontent.com`)

3. Update `ios/Runner/Info.plist`:
   - Replace `com.googleusercontent.apps.YOUR-IOS-CLIENT-ID` with the **reversed** iOS Client ID
   - Example: If iOS Client ID is `123456-abc.apps.googleusercontent.com`, use `com.googleusercontent.apps.123456-abc`

---

### Step 2: Configure Supabase Dashboard

#### 2.1 Add Your Client IDs to Supabase

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Navigate to **Authentication** > **Providers**
4. Find **Google** provider and click to expand
5. Add all three client IDs:

**Web Client ID:**

```
50437670825-hlhi6qesougc52clkk90pbccika7a177.apps.googleusercontent.com
```

**Android Client ID:**

```
Your Android Client ID from Step 1.2
```

**iOS Client ID:**

```
Your iOS Client ID from Step 1.3
```

6. Enter the Client Secret (from your web OAuth client in Google Cloud Console)
7. Click **Save**

#### 2.2 Configure Redirect URLs

1. In Supabase Dashboard, go to **Authentication** > **URL Configuration**
2. Add these redirect URLs:

**For Web:**

```
http://localhost:3000
http://localhost:3000/auth/callback
```

**For Mobile (Deep Link):**

```
com.kanso.mirei.mirei://login-callback
```

3. Set your Site URL (your production URL when you deploy)

---

### Step 3: Environment Variables

Ensure your `.env` file contains:

```env
SUPABASE_URL=your-project-url.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key
```

Get these from:

- Supabase Dashboard > Project Settings > API

---

### Step 4: Update iOS Info.plist

Open `ios/Runner/Info.plist` and replace the placeholder:

Find this section:

```xml
<key>CFBundleURLSchemes</key>
<array>
    <!-- Replace with your iOS Client ID from Google Cloud Console -->
    <string>com.googleusercontent.apps.YOUR-IOS-CLIENT-ID</string>
</array>
```

Replace `com.googleusercontent.apps.YOUR-IOS-CLIENT-ID` with your **reversed iOS Client ID** from Step 1.3.

Example:
If your iOS Client ID is `123456789-abcdef.apps.googleusercontent.com`
Then use: `com.googleusercontent.apps.123456789-abcdef`

---

## 🧪 Testing the Migration

### Test Sign-In Flow

1. **Email/Password Sign-In:**

   - Create a new account
   - Sign in with existing account
   - Test password reset

2. **Google Sign-In:**
   - Test on Android (ensure SHA-1 is configured)
   - Test on iOS (ensure reversed client ID is correct)
   - Verify user profile is created in Supabase

### Verify User Profiles

After signing in, check your Supabase dashboard:

1. Go to **Authentication** > **Users**
2. Verify users appear
3. Go to **Table Editor** > **user_profiles**
4. Verify profile data is populated

---

## 📋 Summary of Changes

### Files Modified:

- ✅ `lib/services/auth_service.dart` - Complete rewrite for Supabase
- ✅ `lib/main.dart` - Supabase initialization
- ✅ `lib/screens/auth/auth_wrapper.dart` - Supabase User type
- ✅ `pubspec.yaml` - Removed Firebase, added Supabase
- ✅ `android/app/build.gradle.kts` - Removed google-services
- ✅ `android/settings.gradle.kts` - Removed google-services
- ✅ `android/app/src/main/AndroidManifest.xml` - Added deep linking
- ✅ `ios/Runner/Info.plist` - Updated URL schemes

### Files Deleted:

- ✅ `lib/firebase_options.dart`
- ✅ `ios/Runner/GoogleService-Info.plist`

### Files to Configure:

- ⚠️ `ios/Runner/Info.plist` - Add your iOS reversed client ID
- ⚠️ `.env` - Add Supabase URL and anon key

---

## 🚀 Next Steps

1. **Complete Google Cloud Setup:**
   - Create Android OAuth client with your SHA-1
   - Create iOS OAuth client with your Bundle ID
2. **Update Supabase Dashboard:**

   - Add all three client IDs to Google provider
   - Configure redirect URLs

3. **Update iOS Configuration:**

   - Replace placeholder with reversed iOS client ID in `Info.plist`

4. **Test:**

   - Test email/password authentication
   - Test Google Sign-In on Android
   - Test Google Sign-In on iOS

5. **Deploy:**
   - Update Site URL in Supabase for production
   - Add production redirect URLs

---

## 🔍 Troubleshooting

### Common Issues:

**"No Access Token found" or "No ID Token found":**

- Android: Check SHA-1 certificate is configured correctly in Google Cloud
- iOS: Check reversed client ID format in Info.plist

**"Sign in failed" or "Invalid credentials":**

- Verify all client IDs are added to Supabase Google provider
- Check client secret is correct in Supabase

**App crashes on auth callback:**

- Android: Verify deep link scheme matches `com.kanso.mirei.mirei`
- iOS: Verify URL schemes are configured in Info.plist

**User profile not created:**

- Check Supabase RLS policies allow insert on user_profiles
- Check database logs in Supabase dashboard

---

## 📚 Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Supabase Google Auth Guide](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Google Sign-In Flutter Package](https://pub.dev/packages/google_sign_in)
- [Supabase Flutter Package](https://pub.dev/packages/supabase_flutter)
