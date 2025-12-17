# 🚀 Supabase Auth Setup Checklist

Quick checklist to complete your Supabase + Google OAuth setup.

---

## ✅ Completed by Migration

- [x] Removed all Firebase dependencies
- [x] Added Supabase Flutter package
- [x] Migrated `AuthService` to Supabase
- [x] Updated `main.dart` with Supabase initialization
- [x] Configured Android deep linking
- [x] Configured iOS URL schemes (base)
- [x] Deleted Firebase config files

---

## ⏳ To Complete (Your Tasks)

### 1. Google Cloud Console - Create OAuth Clients

#### Android Client

- [ ] Run this command to get SHA-1:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

- [ ] Go to https://console.cloud.google.com/apis/credentials
- [ ] Create OAuth 2.0 Client ID > Android
- [ ] Package name: `com.kanso.mirei.mirei`
- [ ] Paste your SHA-1 fingerprint
- [ ] Save the Android Client ID

#### iOS Client

- [ ] Go to https://console.cloud.google.com/apis/credentials
- [ ] Create OAuth 2.0 Client ID > iOS
- [ ] Bundle ID: `com.kanso.mirei.mirei`
- [ ] Save the iOS Client ID
- [ ] **Reverse the iOS Client ID** (e.g., `123-abc.apps.googleusercontent.com` becomes `com.googleusercontent.apps.123-abc`)

---

### 2. Update iOS Info.plist

- [ ] Open `ios/Runner/Info.plist`
- [ ] Find line 77: `<string>com.googleusercontent.apps.YOUR-IOS-CLIENT-ID</string>`
- [ ] Replace `YOUR-IOS-CLIENT-ID` with your **reversed iOS Client ID**

---

### 3. Supabase Dashboard Configuration

#### Add Google Provider Credentials

- [ ] Go to https://supabase.com/dashboard
- [ ] Select your project
- [ ] Navigate to **Authentication** > **Providers** > **Google**
- [ ] Enter:
  - Web Client ID: `50437670825-hlhi6qesougc52clkk90pbccika7a177.apps.googleusercontent.com`
  - Android Client ID: (from step 1)
  - iOS Client ID: (from step 1, NOT reversed)
  - Client Secret: (from Google Cloud Console web client)
- [ ] Click **Save**

#### Configure Redirect URLs

- [ ] Go to **Authentication** > **URL Configuration**
- [ ] Add redirect URL: `com.kanso.mirei.mirei://login-callback`
- [ ] Set Site URL (your production domain when ready)
- [ ] Click **Save**

---

### 4. Environment Variables

- [ ] Verify `.env` file has:

```env
SUPABASE_URL=your-project-url.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key
```

Get these from: Supabase Dashboard > Settings > API

---

### 5. Test Authentication

#### Email/Password

- [ ] Create new account
- [ ] Sign in
- [ ] Test password reset
- [ ] Verify user appears in Supabase Dashboard > Authentication > Users

#### Google Sign-In - Android

- [ ] Run on Android device/emulator
- [ ] Tap Google Sign-In
- [ ] Complete Google OAuth flow
- [ ] Verify successful sign-in
- [ ] Check user profile in `user_profiles` table

#### Google Sign-In - iOS

- [ ] Run on iOS device/simulator
- [ ] Tap Google Sign-In
- [ ] Complete Google OAuth flow
- [ ] Verify successful sign-in
- [ ] Check user profile in `user_profiles` table

---

## 🐛 Quick Troubleshooting

**Problem:** "No Access Token found"

- **Android:** Check SHA-1 is correct in Google Cloud Console
- **iOS:** Check reversed client ID in Info.plist

**Problem:** Google Sign-In doesn't open

- **Android:** Verify package name is `com.kanso.mirei.mirei`
- **iOS:** Verify bundle ID is `com.kanso.mirei.mirei`

**Problem:** Auth callback doesn't work

- **Android:** Check deep link in AndroidManifest.xml
- **iOS:** Check URL schemes in Info.plist

**Problem:** User profile not created

- Check Supabase RLS policies
- View logs in Supabase Dashboard > Logs

---

## 📖 Full Documentation

For detailed instructions, see:

- `SUPABASE_AUTH_COMPLETE_MIGRATION.md` - Complete migration guide
- `SUPABASE_COMPLETE_SETUP.md` - Database and storage setup

---

## 🎉 Once Complete

When all checkboxes are done:

1. You'll have multi-user support with proper authentication
2. Users can sign in with Google (native) or email/password
3. Each user's data is isolated and secure
4. Ready for cross-device sync with Supabase

---

**Need help?** Check the full migration guide or Supabase documentation.
