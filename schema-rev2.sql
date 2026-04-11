-- =========================================================
-- FITFUSION: COMPLETE REVISED SCHEMA (ERD-ready)
-- Based on fitfusion_docs/schema.sql + README context
-- Goal: remove redundant stored data, keep true relational design,
--       and unify admin/player under ONE users table.
-- PostgreSQL
-- =========================================================

-- Optional (for gen_random_uuid)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================================================
-- 0) DOMAIN TYPES
-- =========================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE public.user_role AS ENUM ('player', 'admin');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'workout_type') THEN
    CREATE TYPE public.workout_type AS ENUM ('squats', 'jumping_jacks', 'side_crunches');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'admin_action_target') THEN
    CREATE TYPE public.admin_action_target AS ENUM ('user', 'session', 'system');
  END IF;
END $$;

-- =========================================================
-- 1) USERS (single identity table for both admins and players)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.users (
  id uuid PRIMARY KEY,                                  -- should match auth.users.id
  username text NOT NULL UNIQUE,
  email text NOT NULL UNIQUE,
  role public.user_role NOT NULL DEFAULT 'player',
  is_email_verified boolean NOT NULL DEFAULT false,      -- applies to ALL roles
  show_tutorial boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON public.users(created_at);

-- =========================================================
-- 2) SESSIONS (single source of truth for game outcomes)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  workout_type public.workout_type NOT NULL,
  won boolean NOT NULL,
  rounds_completed integer NOT NULL DEFAULT 0 CHECK (rounds_completed BETWEEN 0 AND 10),
  total_reps integer NOT NULL DEFAULT 0 CHECK (total_reps BETWEEN 0 AND 65),
  lives_lost integer NOT NULL DEFAULT 0 CHECK (lives_lost BETWEEN 0 AND 3),
  total_time_seconds numeric(10,3) NOT NULL CHECK (total_time_seconds > 0),
  best_rep_interval_seconds numeric(10,3) CHECK (best_rep_interval_seconds IS NULL OR best_rep_interval_seconds > 0),
  avg_rep_interval_seconds numeric(10,3) CHECK (avg_rep_interval_seconds IS NULL OR avg_rep_interval_seconds > 0),
  completed_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON public.sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_workout_type ON public.sessions(workout_type);
CREATE INDEX IF NOT EXISTS idx_sessions_won ON public.sessions(won);
CREATE INDEX IF NOT EXISTS idx_sessions_completed_at ON public.sessions(completed_at);

-- =========================================================
-- 3) ACHIEVEMENTS (normalized master + junction)
--    Replaces wide boolean-column user_achievements model.
-- =========================================================
CREATE TABLE IF NOT EXISTS public.achievements (
  id smallserial PRIMARY KEY,
  code text NOT NULL UNIQUE,          -- machine key, e.g. first_blood
  title text NOT NULL UNIQUE,         -- display name
  description text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.user_achievements (
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  achievement_id smallint NOT NULL REFERENCES public.achievements(id) ON DELETE CASCADE,
  unlocked_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, achievement_id)
);

CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement_id ON public.user_achievements(achievement_id);

-- Seed 11 achievements aligned with README/app context
INSERT INTO public.achievements (code, title, description)
VALUES
  ('first_blood',   'First Blood',   'Complete your first session'),
  ('iron_will',     'Iron Will',     'Complete 30 total sessions'),
  ('blood_pumper',  'Blood Pumper',  'Reach 300 lifetime reps'),
  ('survivor',      'Survivor',      'Complete 100 total rounds'),
  ('halfway_hero',  'Halfway Hero',  'Reach 5 rounds in a single session'),
  ('monster_hunter','Monster Hunter','Win a full 10-round session'),
  ('triple_crown',  'Triple Crown',  'Win at least one session in all 3 workout types'),
  ('speed_demon',   'Speed Demon',   'Best rep interval under 1.8 seconds'),
  ('blinding_steel','Blinding Steel','Win with average rep interval under 2.3 seconds'),
  ('untouchable',   'Untouchable',   'Win with 0 lives lost'),
  ('last_stand',    'Last Stand',    'Win with exactly 2 lives lost')
ON CONFLICT (code) DO NOTHING;

-- =========================================================
-- 4) ADMIN LOGS (admin actor also references users table)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.admin_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  action text NOT NULL,
  target_kind public.admin_action_target NOT NULL DEFAULT 'system',
  target_user_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  target_session_id uuid REFERENCES public.sessions(id) ON DELETE SET NULL,
  details jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_logs_actor_user_id ON public.admin_logs(actor_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_logs_target_user_id ON public.admin_logs(target_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_logs_target_session_id ON public.admin_logs(target_session_id);
CREATE INDEX IF NOT EXISTS idx_admin_logs_created_at ON public.admin_logs(created_at);

-- =========================================================
-- 5) DERIVED VIEWS (NO redundant persistent summary tables)
--    These replace user_stats + leaderboard tables as stored data.
-- =========================================================

-- ---- 5.1 Lifetime user stats (used for stats/dashboard contexts)
CREATE OR REPLACE VIEW public.v_user_lifetime_stats AS
SELECT
  s.user_id,
  u.username,
  COUNT(*)::int AS total_sessions,
  COALESCE(SUM(s.total_reps), 0)::int AS total_reps,
  COALESCE(SUM(s.rounds_completed), 0)::int AS total_rounds,
  COALESCE(SUM(CASE WHEN s.won THEN 1 ELSE 0 END), 0)::int AS total_victories,
  COALESCE(SUM(CASE WHEN NOT s.won THEN 1 ELSE 0 END), 0)::int AS total_defeats
FROM public.sessions s
JOIN public.users u ON u.id = s.user_id
GROUP BY s.user_id, u.username;

-- ---- 5.2 Per-workout personal best clear time
CREATE OR REPLACE VIEW public.v_pb_clear_time_by_workout AS
SELECT
  s.workout_type,
  s.user_id,
  u.username,
  MIN(s.total_time_seconds) AS best_clear_time_seconds
FROM public.sessions s
JOIN public.users u ON u.id = s.user_id
WHERE s.won = true
GROUP BY s.workout_type, s.user_id, u.username;

-- ---- 5.3 Per-workout personal best rep interval
CREATE OR REPLACE VIEW public.v_pb_rep_interval_by_workout AS
SELECT
  s.workout_type,
  s.user_id,
  u.username,
  MIN(s.best_rep_interval_seconds) AS best_rep_interval_seconds
FROM public.sessions s
JOIN public.users u ON u.id = s.user_id
WHERE s.best_rep_interval_seconds IS NOT NULL
GROUP BY s.workout_type, s.user_id, u.username;

-- ---- 5.4 Top-10 leaderboard: clear time per workout
CREATE OR REPLACE VIEW public.v_top10_clear_time AS
SELECT *
FROM (
  SELECT
    p.workout_type,
    p.user_id,
    p.username,
    p.best_clear_time_seconds AS value,
    DENSE_RANK() OVER (
      PARTITION BY p.workout_type
      ORDER BY p.best_clear_time_seconds ASC
    ) AS rank
  FROM public.v_pb_clear_time_by_workout p
) x
WHERE x.rank <= 10;

-- ---- 5.5 Top-10 leaderboard: best rep interval per workout
CREATE OR REPLACE VIEW public.v_top10_best_rep_interval AS
SELECT *
FROM (
  SELECT
    p.workout_type,
    p.user_id,
    p.username,
    p.best_rep_interval_seconds AS value,
    DENSE_RANK() OVER (
      PARTITION BY p.workout_type
      ORDER BY p.best_rep_interval_seconds ASC
    ) AS rank
  FROM public.v_pb_rep_interval_by_workout p
  WHERE p.best_rep_interval_seconds IS NOT NULL
) x
WHERE x.rank <= 10;

-- ---- 5.6 Top-10 lifetime by total reps
CREATE OR REPLACE VIEW public.v_top10_lifetime_reps AS
SELECT *
FROM (
  SELECT
    l.user_id,
    l.username,
    l.total_reps AS value,
    DENSE_RANK() OVER (ORDER BY l.total_reps DESC) AS rank
  FROM public.v_user_lifetime_stats l
) x
WHERE x.rank <= 10;

-- ---- 5.7 Top-10 lifetime by total victories
CREATE OR REPLACE VIEW public.v_top10_lifetime_victories AS
SELECT *
FROM (
  SELECT
    l.user_id,
    l.username,
    l.total_victories AS value,
    DENSE_RANK() OVER (ORDER BY l.total_victories DESC) AS rank
  FROM public.v_user_lifetime_stats l
) x
WHERE x.rank <= 10;

-- =========================================================
-- 6) OPTIONAL HELPER VIEW FOR ADMIN LISTING
-- =========================================================
CREATE OR REPLACE VIEW public.v_admin_users AS
SELECT
  id,
  username,
  email,
  role,
  is_email_verified,
  created_at,
  updated_at
FROM public.users
WHERE role IN ('admin');

-- =========================================================
-- END
-- =========================================================
