# Fix Google Sign-In Error 10 (DEVELOPER_ERROR)

## The Problem

Error code 10 means Google can't verify your Android app. This happens when:

- ❌ SHA-1 fingerprint is not registered in Google Cloud Console
- ❌ Android OAuth client is missing or misconfigured
- ❌ Package name doesn't match

**Your package name**: `com.kanso.mirei.mirei`

## Step-by-Step Fix

### Step 1: Get Your SHA-1 Fingerprint

Run this command in your project root:

```bash
cd android
./gradlew signingReport
```

Look for output like this:

```
Variant: debug
Config: debug
Store: ~/.android/debug.keystore
Alias: AndroidDebugKey
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
```

**Copy both SHA-1 and SHA-256** for the debug variant.

For **release builds**, you'll need your production keystore SHA-1:

```bash
keytool -list -v -keystore path/to/your/release.keystore -alias your-key-alias
```

### Step 2: Configure Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to **APIs & Services** → **Credentials**

#### Option A: Add SHA-1 to Existing Android Client

If you have an Android OAuth client:

- Click on the Android client
- Add your SHA-1 fingerprints
- Save

#### Option B: Create New Android OAuth Client (Recommended)

If you don't have an Android OAuth client:

1. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
2. Select **Android**
3. Fill in:
   - **Name**: `Mirei Android`
   - **Package name**: `com.kanso.mirei.mirei`
   - **SHA-1 certificate fingerprint**: Paste your SHA-1 from Step 1
4. Click **CREATE**

**Important**: You need BOTH:

- ✅ **Web application** OAuth client (for `serverClientId`)
- ✅ **Android** OAuth client (for app verification)

### Step 3: Verify Your Configuration

Your Google Cloud Console should now have:

1. **Web application** OAuth client

   - Client ID: `xxxxx-xxxxx.apps.googleusercontent.com`
   - Used as `GOOGLE_WEB_CLIENT_ID` in your `.env` file

2. **Android** OAuth client
   - Package name: `com.kanso.mirei.mirei`
   - SHA-1 fingerprint: (your debug SHA-1)
   - This client verifies your app's signature

### Step 4: Update Supabase Configuration

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Navigate to **Authentication** → **Providers** → **Google**
3. Add your **Web application** OAuth credentials:
   - **Client ID**: Your Web Client ID
   - **Client Secret**: From Google Cloud Console (Web client)
4. Save

### Step 5: Update Your .env File

```bash
# Supabase
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# Google OAuth - Use the WEB client ID (not Android)
GOOGLE_WEB_CLIENT_ID=xxxxx-xxxxx.apps.googleusercontent.com
```

### Step 6: Clean and Rebuild

```bash
# Stop the app
# Then clean everything
flutter clean
cd android
./gradlew clean
cd ..

# Get dependencies
flutter pub get

# Rebuild and run
flutter run
```

## Architecture Explanation

Here's how it works with Supabase:

```
┌─────────────┐
│  Your App   │
│  (Android)  │
└──────┬──────┘
       │
       │ 1. User taps "Sign in with Google"
       │
       ▼
┌─────────────────────┐
│  Google Sign-In SDK │ ← Verifies using Android OAuth client + SHA-1
│  (google_sign_in)   │
└──────┬──────────────┘
       │
       │ 2. Returns: accessToken + idToken
       │
       ▼
┌─────────────────────┐
│   AuthService       │
│  (Your code)        │
└──────┬──────────────┘
       │
       │ 3. Sends tokens to Supabase
       │    signInWithIdToken(...)
       │
       ▼
┌─────────────────────┐
│   Supabase Auth     │ ← Verifies using Web OAuth client
│                     │
└─────────────────────┘
```

**Why you need both**:

- **Android OAuth client**: Verifies your app is legitimate (prevents error 10)
- **Web OAuth client**: Used by Supabase to verify the tokens

## Troubleshooting

### Still Getting Error 10?

1. **Wait 5-10 minutes** after adding SHA-1 (Google needs to propagate changes)

2. **Verify package name matches exactly**:

   ```bash
   # Check your actual package name
   cat android/app/build.gradle.kts | grep applicationId
   # Should show: applicationId = "com.kanso.mirei.mirei"
   ```

3. **Make sure you copied the correct SHA-1**:

   ```bash
   cd android
   ./gradlew signingReport | grep SHA1
   ```

4. **Clear Google Play Services cache** on your device:

   - Settings → Apps → Google Play Services → Storage → Clear Cache
   - Settings → Apps → Google Play Services → Storage → Clear Data

5. **Uninstall and reinstall your app**:
   ```bash
   flutter clean
   flutter run
   ```

### Error: "PlatformException(sign_in_canceled, ...)"

- User canceled the sign-in (this is normal)

### Error: "No ID Token found"

- Web Client ID is missing or incorrect in `.env`
- Check `GOOGLE_WEB_CLIENT_ID` value

### Error: "Invalid audience"

- Web Client ID doesn't match between:
  - Your `.env` file
  - Google Cloud Console
  - Supabase configuration

## Verification Checklist

Before testing, verify:

- [ ] SHA-1 fingerprint registered in Google Cloud Console
- [ ] Android OAuth client created with correct package name (`com.kanso.mirei.mirei`)
- [ ] Web OAuth client exists and Client ID is in `.env`
- [ ] Web OAuth credentials configured in Supabase
- [ ] Waited 5-10 minutes for Google changes to propagate
- [ ] Ran `flutter clean` and reinstalled app
- [ ] `.env` file has `GOOGLE_WEB_CLIENT_ID=...`

## Quick Test

After fixing, test with these logs:

```dart
// In auth_service.dart, the signInWithGoogle method should log:
I/flutter: ✅ Google Sign-In successful: user@gmail.com
```

If you still see error 10, double-check the SHA-1 and package name!

## Additional Resources

- [Google Sign-In Error Codes](https://developers.google.com/android/reference/com/google/android/gms/common/api/CommonStatusCodes)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Supabase Google Auth Guide](https://supabase.com/docs/guides/auth/social-login/auth-google)





