# Supabase Setup Guide for Mirei

## ✅ Database Schema - COMPLETED

Your Supabase database has been successfully set up with the following tables:

### Tables Created:

1. **`user_profiles`** - User profile information (synced with Firebase Auth)
2. **`mood_entries`** - Daily mood tracking entries
3. **`journal_entries`** - Journal entries with text, images, and audio
4. **`memory_entries`** - Memory collections with photos and videos

All tables have:

- ✅ Row Level Security (RLS) enabled
- ✅ Automatic timestamps (`created_at`, `updated_at`)
- ✅ Proper indexes for performance
- ✅ Foreign key relationships
- ✅ Helper functions for common queries

---

## 📦 Storage Buckets Setup

You need to create 4 storage buckets in your Supabase Dashboard:

### 1. Go to Supabase Dashboard → Storage

### 2. Create the following buckets:

#### **Bucket 1: `journal-images`**

- **Public**: `false` (private)
- **File size limit**: 50 MB
- **Allowed MIME types**: `image/jpeg`, `image/png`, `image/webp`, `image/gif`

#### **Bucket 2: `journal-audio`**

- **Public**: `false` (private)
- **File size limit**: 100 MB
- **Allowed MIME types**: `audio/mpeg`, `audio/wav`, `audio/mp4`, `audio/aac`, `audio/m4a`

#### **Bucket 3: `memory-media`**

- **Public**: `false` (private)
- **File size limit**: 200 MB
- **Allowed MIME types**:
  - Images: `image/jpeg`, `image/png`, `image/webp`, `image/gif`
  - Videos: `video/mp4`, `video/quicktime`, `video/webm`

#### **Bucket 4: `avatars`**

- **Public**: `true` (public)
- **File size limit**: 5 MB
- **Allowed MIME types**: `image/jpeg`, `image/png`, `image/webp`

### 3. Apply Storage Policies

After creating the buckets, the RLS policies are already configured to:

- ✅ Allow users to upload/view/delete their own files
- ✅ Organize files by user ID (`{user_id}/{file_name}`)
- ✅ Prevent unauthorized access

---

## 🔧 Flutter App Configuration

### 1. Add Environment Variables

Create or update your `.env` file in the project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
```

**How to get these values:**

1. Go to Supabase Dashboard → Settings → API
2. Copy **Project URL** → Use as `SUPABASE_URL`
3. Copy **anon/public key** → Use as `SUPABASE_ANON_KEY`

### 2. Update `main.dart`

Add Supabase initialization in your `main()` function:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mirei/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase (existing)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase
  await SupabaseService.initialize(
    supabaseUrl: dotenv.env['SUPABASE_URL']!,
    supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}
```

### 3. Sign in to Supabase After Firebase Auth

In your authentication flow, after Firebase sign-in is successful:

```dart
import 'package:mirei/services/supabase_service.dart';

// After Firebase sign-in
await SupabaseService.instance.signInWithFirebase();
```

### 4. Enable Auto-Sync

To automatically sync data when online:

```dart
import 'package:mirei/services/sync_service.dart';

// Call this after user signs in
await SyncService.instance.syncAll();

// Or set up periodic sync
Timer.periodic(Duration(minutes: 15), (_) {
  SyncService.instance.syncAll();
});
```

---

## 🔄 How Sync Works

### Data Flow:

1. **Local First**: All data is stored locally in Realm DB
2. **Background Sync**: When online, data syncs to Supabase
3. **Cross-Device**: Same user can access data on multiple devices
4. **Conflict Resolution**: Last-write-wins strategy

### What Gets Synced:

- ✅ User Profile
- ✅ Mood Entries
- ✅ Journal Entries (text + media files)
- ✅ Memory Entries (photos + videos)

### Media Handling:

- **Upload**: Local files → Supabase Storage → URL stored in database
- **Download**: URLs downloaded → Cached locally → Displayed in app
- **Space Saving**: Local Realm only stores metadata, not full media files

---

## 📊 Database Schema Reference

### user_profiles

```sql
uid (TEXT, PK) - Firebase UID
email (TEXT, UNIQUE)
display_name (TEXT, nullable)
photo_url (TEXT, nullable)
custom_avatar_url (TEXT, nullable)
provider (TEXT) - 'google', 'apple', 'email'
is_email_verified (BOOLEAN)
created_at (TIMESTAMPTZ)
updated_at (TIMESTAMPTZ)
```

### mood_entries

```sql
id (UUID, PK)
user_id (TEXT, FK → user_profiles.uid)
mood (TEXT)
created_at (TIMESTAMPTZ)
note (TEXT, nullable)
intensity (INTEGER, 1-10, nullable)
context (TEXT, nullable)
triggers (TEXT, nullable)
activities (TEXT, nullable)
location (TEXT, nullable)
check_in_type (TEXT, nullable)
sequence_number (INTEGER, nullable)
synced_at (TIMESTAMPTZ)
updated_at (TIMESTAMPTZ)
```

### journal_entries

```sql
id (UUID, PK)
user_id (TEXT, FK → user_profiles.uid)
title (TEXT)
content (TEXT)
created_at (TIMESTAMPTZ)
image_paths (JSONB) - Array of Supabase Storage URLs
audio_recordings (JSONB) - Array of {path, duration, timestamp}
entry_mood (TEXT, nullable)
entry_mood_intensity (INTEGER, 1-10, nullable)
entry_mood_context (TEXT, nullable)
synced_at (TIMESTAMPTZ)
updated_at (TIMESTAMPTZ)
```

### memory_entries

```sql
id (UUID, PK)
user_id (TEXT, FK → user_profiles.uid)
created_at (TIMESTAMPTZ)
caption (TEXT, nullable)
media_paths (JSONB) - Array of Supabase Storage URLs
highlight_indices (JSONB) - Array of indices for highlights
cover_index (INTEGER) - Index of cover image/video
description (TEXT, nullable)
synced_at (TIMESTAMPTZ)
updated_at (TIMESTAMPTZ)
```

---

## 🛠️ Helper Functions

### Get Mood Statistics

```sql
SELECT * FROM get_mood_stats(
  'firebase_user_id',
  '2024-01-01'::timestamptz,
  '2024-12-31'::timestamptz
);
```

### Get Journals by Month

```sql
SELECT * FROM get_journals_by_month(
  'firebase_user_id',
  2024,
  10
);
```

### Get User Counts

```sql
SELECT * FROM get_user_counts('firebase_user_id');
```

---

## 🔐 Security

### Row Level Security (RLS):

- ✅ All tables have RLS enabled
- ✅ Users can only access their own data
- ✅ Service role has full access for sync operations

### Storage Security:

- ✅ Private buckets require authentication
- ✅ Files organized by user ID
- ✅ No cross-user file access

---

## 🚀 Testing the Setup

### 1. Verify Tables

Run this in Supabase SQL Editor:

```sql
SELECT COUNT(*) FROM user_profiles;
SELECT COUNT(*) FROM mood_entries;
SELECT COUNT(*) FROM journal_entries;
SELECT COUNT(*) FROM memory_entries;
```

### 2. Test File Upload

```dart
final supabase = SupabaseService.instance;
await supabase.uploadFile(
  bucket: 'journal-images',
  path: 'test',
  file: File('path/to/test/image.jpg'),
);
```

### 3. Monitor Sync Status

```dart
final sync = SyncService.instance;
print('Is syncing: ${sync.isSyncing}');
print('Last sync: ${sync.lastSyncTime}');
```

---

## 📝 Next Steps

1. ✅ **Database Schema** - COMPLETED
2. 🔲 **Create Storage Buckets** - Go to Supabase Dashboard
3. 🔲 **Add Environment Variables** - Create `.env` file
4. 🔲 **Update `main.dart`** - Initialize Supabase
5. 🔲 **Test Sync** - Sign in and verify data syncs

---

## 🆘 Troubleshooting

### Issue: "Failed to sign in to Supabase"

- **Solution**: Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` are correct
- Check Firebase user is signed in before calling `signInWithFirebase()`

### Issue: "No internet connection"

- **Solution**: Sync service automatically skips when offline
- Local Realm DB continues to work without internet

### Issue: "File upload failed"

- **Solution**: Check storage bucket exists and policies are applied
- Verify file size is within bucket limits

### Issue: "RLS error: permission denied"

- **Solution**: Ensure user is authenticated via Firebase
- Check RLS policies allow service role access

---

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [Supabase Storage Guide](https://supabase.com/docs/guides/storage)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

---

**Status**: ✅ Database setup complete! Create storage buckets next.
