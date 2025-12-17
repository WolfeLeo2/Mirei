# Supabase Google OAuth Migration Guide

## ✅ What's Been Completed

1. **Storage Buckets Created** ✅

   - `journal-images` (50MB limit, private)
   - `journal-audio` (100MB limit, private)
   - `memory-media` (200MB limit, private)
   - `avatars` (5MB limit, public)

2. **Storage Policies Applied** ✅

   - Users can only access their own files
   - Files organized by user ID

3. **Database Policies Updated** ✅

   - RLS now uses Supabase Auth (`auth.uid()`)
   - Each user sees only their own data

4. **New Auth Service Created** ✅
   - `lib/services/supabase_auth_service.dart`
   - Supports Google OAuth and Email/Password

---

## 🚀 Migration Steps

### Step 1: Enable Google OAuth in Supabase Dashboard

1. Go to **Supabase Dashboard** → **Authentication** → **Providers**
2. Click on **Google** provider
3. Toggle **Enable Sign in with Google** to ON
4. Add your **Google OAuth credentials**:
   - **Client ID**: Get from Google Cloud Console
   - **Client Secret**: Get from Google Cloud Console
5. Add **Redirect URLs**:
   - `https://your-project.supabase.co/auth/v1/callback`
   - `io.supabase.flutterquickstart://login-callback` (for mobile)

#### Getting Google OAuth Credentials:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create new)
3. Navigate to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth 2.0 Client ID**
5. Choose **Web application**
6. Add authorized redirect URIs from Supabase
7. Copy **Client ID** and **Client Secret**

---

### Step 2: Update Environment Variables

Add to your `.env` file:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
```

---

### Step 3: Update `main.dart`

Replace Firebase Auth initialization with Supabase:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const MyApp());
}
```

---

### Step 4: Update Authentication Screens

Replace Firebase Auth calls with Supabase Auth:

#### Google Sign In (OLD - Firebase):

```dart
// OLD CODE - REMOVE THIS
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final FirebaseAuth auth = FirebaseAuth.instance;

Future<User?> signInWithGoogle() async {
  final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  final userCredential = await auth.signInWithCredential(credential);
  return userCredential.user;
}
```

#### Google Sign In (NEW - Supabase):

```dart
// NEW CODE - USE THIS
import 'package:mirei/services/supabase_auth_service.dart';

final authService = SupabaseAuthService.instance;

Future<void> signInWithGoogle() async {
  try {
    final response = await authService.signInWithGoogle();
    // User is now signed in!
    final user = response.user;
    print('Signed in: ${user?.email}');
  } catch (e) {
    // Handle error
    print('Sign in failed: $e');
  }
}
```

---

### Step 5: Update User State Management

#### Listen to Auth State Changes:

```dart
import 'package:mirei/services/supabase_auth_service.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Listen to auth state changes
    SupabaseAuthService.instance.authStateChanges.listen((AuthState state) {
      final user = state.session?.user;
      if (user != null) {
        // User is signed in
        print('User signed in: ${user.email}');
      } else {
        // User is signed out
        print('User signed out');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SupabaseAuthService.instance.isSignedIn
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
```

---

### Step 6: Update All Auth Calls

Find and replace throughout your codebase:

#### Get Current User:

```dart
// OLD
final user = FirebaseAuth.instance.currentUser;

// NEW
final user = SupabaseAuthService.instance.currentUser;
```

#### Get User ID:

```dart
// OLD
final uid = FirebaseAuth.instance.currentUser?.uid;

// NEW
final uid = SupabaseAuthService.instance.currentUserId;
```

#### Sign Out:

```dart
// OLD
await FirebaseAuth.instance.signOut();

// NEW
await SupabaseAuthService.instance.signOut();
```

#### Check if Signed In:

```dart
// OLD
final isSignedIn = FirebaseAuth.instance.currentUser != null;

// NEW
final isSignedIn = SupabaseAuthService.instance.isSignedIn;
```

---

### Step 7: Update Data Services

Update any services that reference Firebase Auth:

```dart
// In database_helper.dart, mood_repository.dart, etc.

// OLD
import 'package:firebase_auth/firebase_auth.dart';
final userId = FirebaseAuth.instance.currentUser?.uid;

// NEW
import 'package:mirei/services/supabase_auth_service.dart';
final userId = SupabaseAuthService.instance.currentUserId;
```

---

### Step 8: Optional - Remove Firebase Auth

After migration is complete, you can optionally remove Firebase Auth:

1. Remove from `pubspec.yaml`:

```yaml
dependencies:
  # firebase_auth: ^4.x.x  # Remove this
  # firebase_core: ^2.x.x  # Keep if using other Firebase services
```

2. Remove Firebase initialization from `main.dart` if not using other Firebase services

---

## 🔄 Data Migration

### Existing Users:

If you have existing users with Firebase Auth, they'll need to:

1. Sign in again with Google using Supabase Auth
2. Their Realm local data will remain on device
3. New Supabase user ID will be created
4. Data will sync to Supabase under new user ID

### Fresh Start (Recommended):

Since you mentioned you haven't saved anything in local database yet:

1. Users sign in with Supabase Google Auth
2. Each user gets unique Supabase user ID
3. All data is properly isolated per user
4. Cross-device sync works automatically

---

## 🎯 Benefits of Migration

### Before (Firebase Auth + Supabase Backend):

- ❌ Users share same data (no proper user isolation)
- ❌ Complex auth token passing between Firebase and Supabase
- ❌ Two auth systems to maintain
- ❌ RLS policies don't work properly

### After (Supabase Auth Only):

- ✅ Each user has completely separate data
- ✅ Single auth system (simpler codebase)
- ✅ RLS policies work automatically
- ✅ Built-in Google OAuth (no extra setup)
- ✅ Better Supabase integration
- ✅ Cross-device sync works perfectly

---

## 📋 Checklist

- [ ] Enable Google OAuth in Supabase Dashboard
- [ ] Add Google OAuth credentials from Google Cloud Console
- [ ] Update `.env` with Supabase URL and API key
- [ ] Update `main.dart` to initialize Supabase
- [ ] Replace Firebase Auth calls with Supabase Auth
- [ ] Update all screens that use authentication
- [ ] Update data services to use Supabase user ID
- [ ] Test Google sign in flow
- [ ] Test data isolation (create 2 test accounts)
- [ ] Test cross-device sync
- [ ] (Optional) Remove Firebase Auth dependencies

---

## 🧪 Testing

### Test User Isolation:

1. Sign in with Google account #1
2. Create a journal entry
3. Sign out
4. Sign in with Google account #2
5. Verify you DON'T see account #1's journal entry ✅

### Test Cross-Device Sync:

1. Sign in on Device A
2. Create data (journal, mood, memory)
3. Sign in on Device B with same account
4. Verify data appears on Device B ✅

---

## 🆘 Troubleshooting

### Issue: "Google Sign in failed"

**Solution**:

- Check Google OAuth credentials in Supabase Dashboard
- Verify redirect URLs are correct
- Check Google Cloud Console OAuth consent screen is published

### Issue: "User can't see their data"

**Solution**:

- Check RLS policies are enabled
- Verify user is authenticated (`SupabaseAuthService.instance.isSignedIn`)
- Check user ID matches in database queries

### Issue: "RLS policy violation"

**Solution**:

- Ensure you're using `auth.uid()` in policies (already done)
- User must be signed in to Supabase Auth
- Check database logs in Supabase Dashboard

---

## 📞 Need Help?

Check these resources:

- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [Google OAuth Setup](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)

---

**Status**:

- ✅ Database & Storage Setup Complete
- ✅ Auth Service Created
- ✅ RLS Policies Updated
- 🔲 App Migration Needed (follow steps above)
