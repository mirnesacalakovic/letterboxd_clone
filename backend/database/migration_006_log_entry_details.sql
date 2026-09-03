BEGIN;

-- Diary entries now keep the rating snapshot and tags that belonged to
-- that specific watch. The ratings table still keeps the user's CURRENT
-- rating for the film, while diary_entries.rating preserves history.
ALTER TABLE diary_entries
  ADD COLUMN IF NOT EXISTS rating NUMERIC(2,1),
  ADD COLUMN IF NOT EXISTS tags TEXT[] NOT NULL DEFAULT '{}';

-- A review created from the Log screen belongs to that diary entry.
-- This removes the old one-review-per-user/movie limitation for diary logs,
-- so rewatches can have separate reviews just like Letterboxd.
ALTER TABLE reviews
  ADD COLUMN IF NOT EXISTS diary_entry_id BIGINT REFERENCES diary_entries(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS comments_enabled BOOLEAN NOT NULL DEFAULT true;

ALTER TABLE reviews
  DROP CONSTRAINT IF EXISTS reviews_user_id_movie_id_key;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'valid_diary_rating'
  ) THEN
    ALTER TABLE diary_entries
      ADD CONSTRAINT valid_diary_rating CHECK (
        rating IS NULL OR (
          rating BETWEEN 0.5 AND 5.0
          AND (rating * 2) = trunc(rating * 2)
        )
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_diary_entries_tags
  ON diary_entries USING gin (tags);

CREATE INDEX IF NOT EXISTS idx_reviews_diary_entry_id
  ON reviews(diary_entry_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_reviews_one_per_diary_entry
  ON reviews(diary_entry_id)
  WHERE diary_entry_id IS NOT NULL;

COMMIT;