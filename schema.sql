-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.admin_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  admin_id uuid,
  admin_email text NOT NULL,
  action text NOT NULL,
  target_id uuid,
  details jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT admin_logs_pkey PRIMARY KEY (id),
  CONSTRAINT admin_logs_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admin_users(id)
);
CREATE TABLE public.admin_users (
  id uuid NOT NULL,
  email text NOT NULL UNIQUE,
  role text NOT NULL DEFAULT 'admin'::text CHECK (role = ANY (ARRAY['admin'::text, 'superadmin'::text])),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT admin_users_pkey PRIMARY KEY (id)
);
CREATE TABLE public.leaderboard_entries (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  workout_type text NOT NULL CHECK (workout_type = ANY (ARRAY['squats'::text, 'jumping_jacks'::text, 'side_crunches'::text])),
  metric text NOT NULL CHECK (metric = ANY (ARRAY['clear_time'::text, 'best_rep_interval'::text])),
  user_id uuid NOT NULL,
  username text NOT NULL,
  value numeric NOT NULL,
  session_id uuid NOT NULL,
  rank integer NOT NULL CHECK (rank >= 1 AND rank <= 10),
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT leaderboard_entries_pkey PRIMARY KEY (id),
  CONSTRAINT leaderboard_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT leaderboard_entries_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.sessions(id)
);
CREATE TABLE public.lifetime_leaderboard_entries (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  metric text NOT NULL CHECK (metric = ANY (ARRAY['total_reps'::text, 'total_victories'::text])),
  user_id uuid NOT NULL,
  username text NOT NULL,
  value numeric NOT NULL,
  rank integer NOT NULL CHECK (rank >= 1 AND rank <= 10),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT lifetime_leaderboard_entries_pkey PRIMARY KEY (id),
  CONSTRAINT lifetime_leaderboard_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  workout_type text NOT NULL CHECK (workout_type = ANY (ARRAY['squats'::text, 'jumping_jacks'::text, 'side_crunches'::text])),
  won boolean NOT NULL,
  rounds_completed integer NOT NULL DEFAULT 0 CHECK (rounds_completed >= 0 AND rounds_completed <= 10),
  total_reps integer NOT NULL DEFAULT 0 CHECK (total_reps >= 0 AND total_reps <= 65),
  lives_lost integer NOT NULL DEFAULT 0 CHECK (lives_lost >= 0 AND lives_lost <= 3),
  total_time_seconds numeric NOT NULL CHECK (total_time_seconds > 0::numeric),
  best_rep_interval_seconds numeric,
  avg_rep_interval_seconds numeric,
  completed_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT sessions_pkey PRIMARY KEY (id),
  CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.user_achievements (
  user_id uuid NOT NULL,
  first_blood boolean NOT NULL DEFAULT false,
  first_blood_unlocked_at timestamp with time zone,
  iron_will boolean NOT NULL DEFAULT false,
  iron_will_unlocked_at timestamp with time zone,
  blood_pumper boolean NOT NULL DEFAULT false,
  blood_pumper_unlocked_at timestamp with time zone,
  survivor boolean NOT NULL DEFAULT false,
  survivor_unlocked_at timestamp with time zone,
  halfway_hero boolean NOT NULL DEFAULT false,
  halfway_hero_unlocked_at timestamp with time zone,
  monster_hunter boolean NOT NULL DEFAULT false,
  monster_hunter_unlocked_at timestamp with time zone,
  triple_crown boolean NOT NULL DEFAULT false,
  triple_crown_unlocked_at timestamp with time zone,
  speed_demon boolean NOT NULL DEFAULT false,
  speed_demon_unlocked_at timestamp with time zone,
  blinding_steel boolean NOT NULL DEFAULT false,
  blinding_steel_unlocked_at timestamp with time zone,
  untouchable boolean NOT NULL DEFAULT false,
  untouchable_unlocked_at timestamp with time zone,
  last_stand boolean NOT NULL DEFAULT false,
  last_stand_unlocked_at timestamp with time zone,
  CONSTRAINT user_achievements_pkey PRIMARY KEY (user_id),
  CONSTRAINT user_achievements_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.user_stats (
  user_id uuid NOT NULL,
  total_sessions integer NOT NULL DEFAULT 0,
  total_reps integer NOT NULL DEFAULT 0,
  total_rounds integer NOT NULL DEFAULT 0,
  total_victories integer NOT NULL DEFAULT 0,
  squats_victories integer NOT NULL DEFAULT 0,
  squats_defeats integer NOT NULL DEFAULT 0,
  squats_rounds_completed integer NOT NULL DEFAULT 0,
  squats_reps_finished integer NOT NULL DEFAULT 0,
  squats_pb_clear_time_seconds numeric,
  squats_avg_clear_time_seconds numeric,
  squats_pb_best_interval_seconds numeric,
  squats_avg_rep_interval_seconds numeric,
  jacks_victories integer NOT NULL DEFAULT 0,
  jacks_defeats integer NOT NULL DEFAULT 0,
  jacks_rounds_completed integer NOT NULL DEFAULT 0,
  jacks_reps_finished integer NOT NULL DEFAULT 0,
  jacks_pb_clear_time_seconds numeric,
  jacks_avg_clear_time_seconds numeric,
  jacks_pb_best_interval_seconds numeric,
  jacks_avg_rep_interval_seconds numeric,
  crunches_victories integer NOT NULL DEFAULT 0,
  crunches_defeats integer NOT NULL DEFAULT 0,
  crunches_rounds_completed integer NOT NULL DEFAULT 0,
  crunches_reps_finished integer NOT NULL DEFAULT 0,
  crunches_pb_clear_time_seconds numeric,
  crunches_avg_clear_time_seconds numeric,
  crunches_pb_best_interval_seconds numeric,
  crunches_avg_rep_interval_seconds numeric,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_stats_pkey PRIMARY KEY (user_id),
  CONSTRAINT user_stats_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.users (
  id uuid NOT NULL,
  username text NOT NULL,
  email text NOT NULL UNIQUE,
  is_email_verified boolean NOT NULL DEFAULT false,
  show_tutorial boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (id)
);
