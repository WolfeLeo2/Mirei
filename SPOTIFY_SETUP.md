# 🎵 Spotify Integration Setup Guide for Mirei

This guide will help you set up the hybrid Spotify integration that works for both Premium and Free users.

## 🎯 What You Get

### ✅ **For Premium Users:**
- Full music playback directly in your app
- Complete playback control (play, pause, skip, seek)
- Real-time player state updates
- Seamless in-app experience

### ✅ **For Free Users:**
- Music discovery and search
- 30-second track previews
- Redirect to Spotify app/web for full playback
- Beautiful music browsing experience

---

## 📋 Prerequisites

1. **Spotify Developer Account** (free)
2. **Flutter 3.10.6+** / **Dart 3.0.6+**
3. **Android device** with Spotify app installed
4. **iOS device** with Spotify app installed (for iOS testing)

---

## 🚀 Step 1: Spotify Developer Dashboard Setup

### Create Spotify App
1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Click **"Create App"**
3. Fill out the form:
   ```
   App Name: Mirei Mental Wellness
   App Description: A mental wellness app with music integration
   Website: https://your-website.com (or leave blank)
   Redirect URIs: com.yourapp.mirei://spotify-auth
   Which API/SDKs are you planning to use: Web API, Android SDK, iOS SDK
   ```
4. Check the boxes for **Terms of Service** and **Developer Policy**
5. Click **"Save"**

### Get Your Credentials
1. In your app dashboard, note down:
   - **Client ID**: `abc123def456...`
   - **Client Secret**: `xyz789uvw456...` (click "Show Client Secret")

### Configure Redirect URI
1. In **Settings** → **Redirect URIs**, add:
   ```
   com.yourapp.mirei://spotify-auth
   ```
2. Click **"Add"** and **"Save"**

---

## 🔧 Step 2: Update Your Flutter App

### 1. Update Dependencies
The dependencies have already been added to your `pubspec.yaml`:
```yaml
dependencies:
  spotify: ^0.13.7  # For Web API (works with free users)
  spotify_sdk: ^3.0.2  # For full playback (Premium users only)
  url_launcher: ^6.2.2  # For opening Spotify app/web
```

Run:
```bash
flutter pub get
```

### 2. Update Spotify Service Configuration
The app now uses environment variables for secure credential storage:

1. **Copy the template file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit the `.env` file** and replace the placeholder values:
   ```bash
   # Open .env file and replace with your actual credentials
   SPOTIFY_CLIENT_ID=abc123def456...  # Your actual Client ID
   SPOTIFY_CLIENT_SECRET=xyz789uvw456...  # Your actual Client Secret
   SPOTIFY_REDIRECT_URL=com.yourapp.mirei://spotify-auth
   ```

3. **Verify the file is ignored by git:**
   ```bash
   git status  # .env should NOT appear in untracked files
   ```

**Important Security Notes:**
- ✅ The `.env` file is automatically ignored by git
- ✅ Never commit your actual credentials to version control
- ✅ Use the `.env.example` file as a template for other developers

---

## 📱 Step 3: Android Setup

### 1. Add Spotify SDK
Run the setup script (recommended):
```bash
cd /Users/app/AndroidStudioProjects/Mirei
dart run spotify_sdk:android_setup
```

Or manually:
1. Download [Spotify Android SDK](https://github.com/spotify/android-sdk/releases)
2. Extract `spotify-app-remote-release-x.x.x.aar`
3. Place it in `android/spotify-app-remote/`
4. Create `android/spotify-app-remote/build.gradle`:
   ```gradle
   configurations.maybeCreate("default")
   artifacts.add("default", file('spotify-app-remote-release-x.x.x.aar'))
   ```

### 2. Update Android Configuration
Edit `android/settings.gradle`:
```gradle
include ':spotify-app-remote'
```

Edit `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        manifestPlaceholders = [
            redirectSchemeName: "com.yourapp.mirei", 
            redirectHostName: "spotify-auth"
        ]
        // ... existing config
    }
}
```

### 3. Add SHA-1 Fingerprint
Get your SHA-1 fingerprint:
```bash
cd android
./gradlew signingReport
```

Copy the SHA1 fingerprint and add it to your Spotify app settings in the developer dashboard.

---

## 🍎 Step 4: iOS Setup

### 1. Add to Info.plist
Edit `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>spotify-auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.yourapp.mirei</string>
        </array>
    </dict>
</array>
```

### 2. Update Bundle ID
In Spotify Developer Dashboard, add your iOS Bundle ID to the app settings.

---

## 🧪 Step 5: Testing

### Test the Integration
1. **Run the app**: `flutter run`
2. **Navigate** to the Media tab
3. **Tap** on "Discover Wellness Music" (Spotify section)
4. **Try connecting** to Spotify
5. **Search** for meditation music
6. **Test both scenarios**:
   - **Premium users**: Should be able to play music in-app
   - **Free users**: Should be redirected to Spotify app/web

### Test Cases
- [ ] Search functionality works
- [ ] Premium users can play music in-app
- [ ] Free users get redirected to Spotify
- [ ] 30-second previews work for all users
- [ ] Connection status is displayed correctly
- [ ] Error handling works properly

---

## 🎨 UI Features

### Premium User Experience
```
🟢 Connected to Spotify
   Premium account - Full playback available

[🎵 Track Name]
[👑 Premium] [▶️ Play] [🔊 Preview]
```

### Free User Experience  
```
🟠 Connected to Spotify
   Free account - Discovery mode only

[🎵 Track Name]
[🔗 Open in Spotify] [🔊 Preview]
```

---

## 🚨 Troubleshooting

### Common Issues

#### 1. "Authentication Failed"
- ✅ Check Client ID and Client Secret are correct
- ✅ Verify Redirect URI matches exactly
- ✅ Ensure SHA-1 fingerprint is added (Android)

#### 2. "SDK Connection Failed"
- ✅ Make sure Spotify app is installed
- ✅ User must have Spotify Premium for SDK features
- ✅ Check Android SDK is properly integrated

#### 3. "Search Not Working"
- ✅ Check internet connection
- ✅ Verify Web API credentials
- ✅ Check rate limiting (429 errors)

#### 4. "Previews Not Playing"
- ✅ Some tracks don't have preview URLs
- ✅ Check audio permissions
- ✅ Verify just_audio is working

### Debug Mode
Enable detailed logging by adding this to your main():
```dart
import 'dart:developer' as developer;

void main() {
  developer.log('Spotify Integration Debug Mode Enabled');
  runApp(MyApp());
}
```

---

## 🔒 Security Notes

### Important
- ✅ **Credentials are now secure** using `.env` files
- ✅ **Never commit** your `.env` file to version control
- ✅ **Use `.env.example`** as a template for other developers
- ✅ **Environment variables** are loaded at app startup
- ✅ **Error handling** shows helpful messages if credentials are missing

### For Production Deployment
```dart
// The app automatically validates credentials on startup
// and shows clear error messages if they're missing or invalid
```

---

## 🎉 You're Done!

Your Mirei app now has a beautiful, hybrid Spotify integration with **secure credential management**!

### Next Steps
1. **Copy `.env.example` to `.env`** and add your credentials
2. **Test thoroughly** on both Android and iOS
3. **Gather user feedback** on the music discovery experience
4. **Consider adding** more advanced features like:
   - Playlist creation
   - Favorite tracks
   - Music recommendations based on mood
   - Integration with meditation sessions

### Support
If you run into issues, check the [Spotify Web API docs](https://developer.spotify.com/documentation/web-api/) and [Spotify SDK docs](https://developer.spotify.com/documentation/android/).