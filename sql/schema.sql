-- event_id is the UNIQUE dedupe key: reprocessing the same event
-- (Pub/Sub retry) will NOT create a duplicate row.
CREATE TABLE IF NOT EXISTS events (
    event_id      TEXT PRIMARY KEY,
    event_type    TEXT        NOT NULL,
    payload       JSONB       NOT NULL,
    event_time    TIMESTAMPTZ NOT NULL,
    ingested_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_events_event_time ON events (event_time);

-- Idempotent upsert used by the pipeline:
--   INSERT ... ON CONFLICT (event_id) DO NOTHING;