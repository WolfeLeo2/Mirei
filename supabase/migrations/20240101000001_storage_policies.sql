-- ============================================================================
-- STORAGE BUCKET POLICIES
-- ============================================================================

-- Note: Before running this, create the following buckets via Supabase Dashboard:
-- 1. journal-images (public: false)
-- 2. journal-audio (public: false)
-- 3. memory-media (public: false)
-- 4. avatars (public: true)

-- ============================================================================
-- JOURNAL IMAGES BUCKET
-- ============================================================================

-- Allow users to upload their own journal images
CREATE POLICY "Users can upload own journal images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'journal-images' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to view their own journal images
CREATE POLICY "Users can view own journal images"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'journal-images' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to delete their own journal images
CREATE POLICY "Users can delete own journal images"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'journal-images' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================================================
-- JOURNAL AUDIO BUCKET
-- ============================================================================

-- Allow users to upload their own journal audio
CREATE POLICY "Users can upload own journal audio"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'journal-audio' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to view their own journal audio
CREATE POLICY "Users can view own journal audio"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'journal-audio' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to delete their own journal audio
CREATE POLICY "Users can delete own journal audio"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'journal-audio' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================================================
-- MEMORY MEDIA BUCKET
-- ============================================================================

-- Allow users to upload their own memory media
CREATE POLICY "Users can upload own memory media"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'memory-media' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to view their own memory media
CREATE POLICY "Users can view own memory media"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'memory-media' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to delete their own memory media
CREATE POLICY "Users can delete own memory media"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'memory-media' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================================================
-- AVATARS BUCKET (Public)
-- ============================================================================

-- Allow users to upload their own avatars
CREATE POLICY "Users can upload own avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow anyone to view avatars (public bucket)
CREATE POLICY "Anyone can view avatars" ON storage.objects FOR
SELECT TO public USING (bucket_id = 'avatars');

-- Allow users to update their own avatars
CREATE POLICY "Users can update own avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to delete their own avatars
CREATE POLICY "Users can delete own avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);
