-- ============================================================================
-- STORAGE BUCKETS SETUP
-- ============================================================================
-- Note: Run these commands in your Supabase SQL Editor
-- Or use the Supabase Dashboard UI: Storage → Create bucket

-- Create buckets via SQL
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('journal-images', 'journal-images', false, 52428800, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']),
  ('journal-audio', 'journal-audio', false, 104857600, ARRAY['audio/mpeg', 'audio/wav', 'audio/mp4', 'audio/aac', 'audio/m4a']),
  ('memory-media', 'memory-media', false, 209715200, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'video/mp4', 'video/quicktime', 'video/webm']),
  ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

-- Verify buckets were created
SELECT id, name, public, file_size_limit FROM storage.buckets;
