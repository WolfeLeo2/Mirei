# Google Sign-In Setup for Supabase

## Issue Fixed

Added the required `serverClientId` (Web Client ID) to the GoogleSignIn configuration. This is **critical** for Supabase authentication to work properly.

## What You Need to Do

### 1. Get Your Google Web Client ID

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create one)
3. Navigate to **APIs & Services** → **Credentials**
4. Find your OAuth 2.0 Client IDs
5. You need the **Web application** client ID (not Android)
   - It should look like: `123456789-abcdefg.apps.googleusercontent.com`
   - If you don't have a Web client ID, create one:
     - Click **+ CREATE CREDENTIALS** → **OAuth client ID**
     - Select **Web application**
     - Add authorized redirect URIs (if using Supabase):
       ```
       https://your-project-ref.supabase.co/auth/v1/callback
       ```

### 2. Configure Supabase

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Navigate to **Authentication** → **Providers**
3. Enable **Google** provider
4. Add your Google OAuth credentials:
   - **Client ID**: Your Web Client ID
   - **Client Secret**: From Google Cloud Console

### 3. Update Your .env File

Add the Web Client ID to your `.env` file:

```bash
# Supabase Configuration
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-anon-key

# Google OAuth (Required for Google Sign-In with Supabase)
GOOGLE_WEB_CLIENT_ID=123456789-abcdefg.apps.googleusercontent.com
```

### 4. Configure Android

Make sure you have the SHA-1 fingerprint registered in Google Cloud Console:

```bash
# Get your debug SHA-1
cd android
./gradlew signingReport

# For release, use your keystore SHA-1
keytool -list -v -keystore path/to/your/keystore.jks -alias your-key-alias
```

Add the SHA-1 fingerprints to your Google Cloud Console OAuth client (Android type).

## Why This Is Required

### The Problem

Without the `serverClientId`, the Google Sign-In flow generates tokens that:

- ✅ Work for Google authentication
- ❌ **Cannot be verified by Supabase**
- ❌ Have incorrect audience claims
- ❌ Missing required fields for server-side auth

### The Solution

By providing the `serverClientId`, you ensure:

- ✅ ID tokens are generated with correct audience
- ✅ Supabase can verify the tokens
- ✅ Tokens include all required claims
- ✅ Server-side authentication works properly

## Troubleshooting

### Error: "No ID Token found"

- Make sure you've added the Web Client ID to `.env`
- Verify the client ID is correct (should end in `.apps.googleusercontent.com`)

### Error: "Failed to sign in with Google"

- Check Supabase logs in Dashboard → Logs
- Verify Google provider is enabled in Supabase
- Ensure client ID and secret match in both Google Cloud Console and Supabase

### Error: "Invalid audience"

- The Web Client ID in `.env` must match the one in Google Cloud Console
- The Web Client ID must also be configured in Supabase

### Still Not Working?

1. Clear app data: Settings → Apps → Mirei → Storage → Clear Data
2. Uninstall and reinstall the app
3. Check Google Cloud Console quotas
4. Verify all redirect URIs are correct

## Testing

After setup:

1. Run the app: `flutter run`
2. Tap "Sign in with Google"
3. Select a Google account
4. Check console logs for success message: "✅ Google Sign-In successful"

## References

- [Google Sign-In Flutter Plugin](https://pub.dev/packages/google_sign_in)
- [Supabase Google Auth Docs](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Google Cloud Console](https://console.cloud.google.com/)





