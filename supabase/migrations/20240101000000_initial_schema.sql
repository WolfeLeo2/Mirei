-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- USER PROFILES TABLE
-- ============================================================================
CREATE TABLE public.user_profiles (
    uid TEXT PRIMARY KEY, -- Firebase UID
    email TEXT NOT NULL UNIQUE,
    display_name TEXT,
    photo_url TEXT, -- Firebase profile picture URL
    custom_avatar_url TEXT, -- User-selected custom avatar
    provider TEXT NOT NULL DEFAULT 'email', -- 'google', 'apple', 'email'
    is_email_verified BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP
    WITH
        TIME ZONE NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMP
    WITH
        TIME ZONE NOT NULL DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX idx_user_profiles_email ON public.user_profiles (email);

CREATE INDEX idx_user_profiles_updated_at ON public.user_profiles (updated_at DESC);

-- ============================================================================
-- MOOD ENTRIES TABLE
-- ============================================================================
CREATE TABLE public.mood_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL REFERENCES public.user_profiles(uid) ON DELETE CASCADE,
    mood TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    note TEXT,

-- Enhanced mood tracking fields
intensity INTEGER CHECK (
    intensity >= 1
    AND intensity <= 10
),
context TEXT,
triggers TEXT, -- Comma-separated list
activities TEXT, -- Comma-separated list
location TEXT,
check_in_type TEXT, -- 'morning', 'afternoon', 'evening', 'manual'
sequence_number INTEGER,

-- Sync metadata
synced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes for common query patterns
CREATE INDEX idx_mood_entries_user_id ON public.mood_entries (user_id);

CREATE INDEX idx_mood_entries_created_at ON public.mood_entries (user_id, created_at DESC);

CREATE INDEX idx_mood_entries_mood ON public.mood_entries (user_id, mood);

-- ============================================================================
-- JOURNAL ENTRIES TABLE
-- ============================================================================
CREATE TABLE public.journal_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL REFERENCES public.user_profiles(uid) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT '',
    content TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

-- Media references (stored as JSONB for flexibility)
image_paths JSONB DEFAULT '[]'::jsonb,
    audio_recordings JSONB DEFAULT '[]'::jsonb,

-- Journal-specific mood context
entry_mood TEXT,
entry_mood_intensity INTEGER CHECK (
    entry_mood_intensity >= 1
    AND entry_mood_intensity <= 10
),
entry_mood_context TEXT,

-- Sync metadata
synced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes for common query patterns
CREATE INDEX idx_journal_entries_user_id ON public.journal_entries (user_id);

CREATE INDEX idx_journal_entries_created_at ON public.journal_entries (user_id, created_at DESC);

CREATE INDEX idx_journal_entries_entry_mood ON public.journal_entries (user_id, entry_mood);

-- GIN index for JSONB columns for faster searches
CREATE INDEX idx_journal_entries_image_paths ON public.journal_entries USING GIN (image_paths);

-- ============================================================================
-- MEMORY ENTRIES TABLE
-- ============================================================================
CREATE TABLE public.memory_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL REFERENCES public.user_profiles(uid) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    caption TEXT,

-- Media references (images and videos)
media_paths JSONB DEFAULT '[]'::jsonb,

-- Highlight selection (indices of media that are highlights)
highlight_indices JSONB DEFAULT '[]'::jsonb,

-- Cover image index (default 0 for first image)
cover_index INTEGER DEFAULT 0,

-- Additional memory metadata
description TEXT, -- "What made this memory special"

-- Sync metadata
synced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes for common query patterns
CREATE INDEX idx_memory_entries_user_id ON public.memory_entries (user_id);

CREATE INDEX idx_memory_entries_created_at ON public.memory_entries (user_id, created_at DESC);

-- GIN index for JSONB columns
CREATE INDEX idx_memory_entries_media_paths ON public.memory_entries USING GIN (media_paths);

-- ============================================================================
-- TRIGGERS FOR AUTOMATIC TIMESTAMP UPDATES
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for each table
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mood_entries_updated_at BEFORE UPDATE ON public.mood_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_journal_entries_updated_at BEFORE UPDATE ON public.journal_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_memory_entries_updated_at BEFORE UPDATE ON public.memory_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.mood_entries ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.memory_entries ENABLE ROW LEVEL SECURITY;

-- User Profiles: Users can only read/update their own profile
CREATE POLICY "Users can view own profile"
    ON public.user_profiles FOR SELECT
    USING (auth.uid()::text = uid);

CREATE POLICY "Users can update own profile"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid()::text = uid);

CREATE POLICY "Users can insert own profile"
    ON public.user_profiles FOR INSERT
    WITH CHECK (auth.uid()::text = uid);

-- Mood Entries: Users can only access their own mood entries
CREATE POLICY "Users can view own mood entries"
    ON public.mood_entries FOR SELECT
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own mood entries"
    ON public.mood_entries FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own mood entries"
    ON public.mood_entries FOR UPDATE
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own mood entries"
    ON public.mood_entries FOR DELETE
    USING (auth.uid()::text = user_id);

-- Journal Entries: Users can only access their own journal entries
CREATE POLICY "Users can view own journal entries"
    ON public.journal_entries FOR SELECT
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own journal entries"
    ON public.journal_entries FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own journal entries"
    ON public.journal_entries FOR UPDATE
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own journal entries"
    ON public.journal_entries FOR DELETE
    USING (auth.uid()::text = user_id);

-- Memory Entries: Users can only access their own memory entries
CREATE POLICY "Users can view own memory entries"
    ON public.memory_entries FOR SELECT
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own memory entries"
    ON public.memory_entries FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own memory entries"
    ON public.memory_entries FOR UPDATE
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own memory entries"
    ON public.memory_entries FOR DELETE
    USING (auth.uid()::text = user_id);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to get mood stats for a user within a date range
CREATE OR REPLACE FUNCTION get_mood_stats(
    p_user_id TEXT,
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
    mood TEXT,
    count BIGINT,
    avg_intensity NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.mood,
        COUNT(*)::BIGINT as count,
        ROUND(AVG(m.intensity)::NUMERIC, 2) as avg_intensity
    FROM public.mood_entries m
    WHERE m.user_id = p_user_id
        AND m.created_at >= p_start_date
        AND m.created_at <= p_end_date
    GROUP BY m.mood
    ORDER BY count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get journal entries for a specific month
CREATE OR REPLACE FUNCTION get_journals_by_month(
    p_user_id TEXT,
    p_year INTEGER,
    p_month INTEGER
)
RETURNS SETOF public.journal_entries AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.journal_entries
    WHERE user_id = p_user_id
        AND EXTRACT(YEAR FROM created_at) = p_year
        AND EXTRACT(MONTH FROM created_at) = p_month
    ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get total counts for user dashboard
CREATE OR REPLACE FUNCTION get_user_counts(p_user_id TEXT)
RETURNS TABLE (
    mood_count BIGINT,
    journal_count BIGINT,
    memory_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM public.mood_entries WHERE user_id = p_user_id),
        (SELECT COUNT(*) FROM public.journal_entries WHERE user_id = p_user_id),
        (SELECT COUNT(*) FROM public.memory_entries WHERE user_id = p_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- STORAGE BUCKETS (to be created via Supabase Dashboard or API)
-- ============================================================================
-- Note: These are created via Supabase Storage API, not SQL
-- Buckets needed:
--   - journal-images: For journal entry images
--   - journal-audio: For journal entry audio recordings
--   - memory-media: For memory photos and videos
--   - avatars: For user profile pictures

-- Storage policies will be defined in the next migration file
