-- Migration: Add sync support to tables
-- Run this in Supabase SQL Editor

-- ============================================================
-- ADD last_modified COLUMN TO EXISTING TABLES
-- ============================================================

-- Add to mood_entries if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'mood_entries' AND column_name = 'last_modified'
  ) THEN
    ALTER TABLE mood_entries ADD COLUMN last_modified TIMESTAMPTZ DEFAULT NOW();
    
    -- Initialize last_modified for existing rows
    UPDATE mood_entries SET last_modified = created_at WHERE last_modified IS NULL;
    
    -- Make it NOT NULL after initialization
    ALTER TABLE mood_entries ALTER COLUMN last_modified SET NOT NULL;
  END IF;
END $$;

-- Add to journal_entries if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'journal_entries' AND column_name = 'last_modified'
  ) THEN
    ALTER TABLE journal_entries ADD COLUMN last_modified TIMESTAMPTZ DEFAULT NOW();
    UPDATE journal_entries SET last_modified = created_at WHERE last_modified IS NULL;
    ALTER TABLE journal_entries ALTER COLUMN last_modified SET NOT NULL;
  END IF;
END $$;

-- Add to memory_entries if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'memory_entries' AND column_name = 'last_modified'
  ) THEN
    ALTER TABLE memory_entries ADD COLUMN last_modified TIMESTAMPTZ DEFAULT NOW();
    UPDATE memory_entries SET last_modified = created_at WHERE last_modified IS NULL;
    ALTER TABLE memory_entries ALTER COLUMN last_modified SET NOT NULL;
  END IF;
END $$;

-- ============================================================
-- CREATE INDEXES FOR EFFICIENT SYNC QUERIES
-- ============================================================

-- Index for mood_entries sync queries
CREATE INDEX IF NOT EXISTS idx_mood_entries_user_modified ON mood_entries (user_id, last_modified DESC);

-- Index for journal_entries sync queries
CREATE INDEX IF NOT EXISTS idx_journal_entries_user_modified ON journal_entries (user_id, last_modified DESC);

-- Index for memory_entries sync queries
CREATE INDEX IF NOT EXISTS idx_memory_entries_user_modified ON memory_entries (user_id, last_modified DESC);

-- ============================================================
-- CREATE FUNCTIONS TO AUTO-UPDATE last_modified
-- ============================================================

-- Function to update last_modified timestamp
CREATE OR REPLACE FUNCTION update_last_modified()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_modified = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for mood_entries
DROP TRIGGER IF EXISTS update_mood_entries_last_modified ON mood_entries;

CREATE TRIGGER update_mood_entries_last_modified
  BEFORE UPDATE ON mood_entries
  FOR EACH ROW
  EXECUTE FUNCTION update_last_modified();

-- Trigger for journal_entries
DROP TRIGGER IF EXISTS update_journal_entries_last_modified ON journal_entries;

CREATE TRIGGER update_journal_entries_last_modified
  BEFORE UPDATE ON journal_entries
  FOR EACH ROW
  EXECUTE FUNCTION update_last_modified();

-- Trigger for memory_entries
DROP TRIGGER IF EXISTS update_memory_entries_last_modified ON memory_entries;

CREATE TRIGGER update_memory_entries_last_modified
  BEFORE UPDATE ON memory_entries
  FOR EACH ROW
  EXECUTE FUNCTION update_last_modified();

-- ============================================================
-- VERIFY SETUP
-- ============================================================

-- Check that all tables have the required columns
SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE
    table_name IN (
        'mood_entries',
        'journal_entries',
        'memory_entries'
    )
    AND column_name IN (
        'user_id',
        'created_at',
        'last_modified'
    )
ORDER BY table_name, column_name;

-- Check that all indexes were created
SELECT schemaname, tablename, indexname
FROM pg_indexes
WHERE
    tablename IN (
        'mood_entries',
        'journal_entries',
        'memory_entries'
    )
    AND indexname LIKE '%_user_modified';

COMMIT;


