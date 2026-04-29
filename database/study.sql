-- =========================
-- MODULES
-- =========================

create table modules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,

  title text not null,
  topic text not null,
  category text not null default 'General',
  difficulty text not null check (difficulty in ('easy', 'normal', 'hard', 'exam')),

  source_type text not null check (source_type in ('topic', 'upload', 'generated')),
  file_url text,
  image_url text,

  summary text,
  status text not null default 'processing'
    check (status in ('processing', 'ready', 'failed', 'completed')),
  popularity_count int not null default 0,
  last_used_at timestamptz,

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists modules_user_updated_idx
on modules(user_id, updated_at desc);

-- =========================
-- MODULE LESSONS
-- =========================

create table module_lessons (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references modules(id) on delete cascade,
  title text not null,
  description text,
  order_index int not null default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists module_lessons_module_order_idx
on module_lessons(module_id, order_index);

-- =========================
-- TOPICS
-- =========================

create table topics (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references profiles(id) on delete set null,
  title text not null,
  topic text not null,
  category text not null default 'General',
  difficulty text not null check (difficulty in ('easy', 'normal', 'hard', 'exam')),
  summary text,
  image_url text,
  popularity_count int not null default 0,
  status text not null default 'ready'
    check (status in ('processing', 'ready', 'failed', 'completed')),
  source_type text not null default 'curated'
    check (source_type in ('curated', 'community', 'generated')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists topics_status_popularity_idx
on topics(status, popularity_count desc, updated_at desc);

create index if not exists topics_category_title_idx
on topics(category, title);

alter table modules
  add column topic_id uuid references topics(id) on delete set null;

create index if not exists modules_topic_id_idx
on modules(topic_id);

create index if not exists modules_popularity_category_idx
on modules(popularity_count desc, category, title);

-- =========================
-- TOPIC LESSONS
-- =========================

create table topic_lessons (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references topics(id) on delete cascade,
  title text not null,
  description text,
  order_index int not null default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists topic_lessons_topic_order_idx
on topic_lessons(topic_id, order_index);

-- =========================
-- QUESTIONS
-- =========================

create table questions (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references modules(id) on delete cascade,

  question_text text not null,
  question_type text not null check (
    question_type in ('mcq', 'identification', 'true_false')
  ),

  choices jsonb,
  correct_answer text not null,
  explanation text,
  difficulty text not null check (difficulty in ('easy', 'normal', 'hard', 'exam')),

  order_index int not null default 0,

  created_at timestamptz default now()
);

create index if not exists questions_module_type_order_idx
on questions(module_id, question_type, order_index, created_at);

-- =========================
-- MODULE ATTEMPTS
-- =========================

create table module_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  module_id uuid not null references modules(id) on delete cascade,

  score int not null default 0,
  total_questions int not null default 0,
  accuracy numeric not null default 0,

  xp_earned int not null default 0,
  coins_earned int not null default 0,
  energy_before int,
  energy_change int not null default 0,
  energy_after int,
  used_energy_refill boolean not null default false,

  passed boolean not null default false,

  started_at timestamptz default now(),
  completed_at timestamptz
);

-- =========================
-- QUESTION ATTEMPTS
-- =========================

create table question_attempts (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references module_attempts(id) on delete cascade,
  question_id uuid not null references questions(id) on delete cascade,

  selected_answer text,
  is_correct boolean not null default false,
  response_time_ms int,

  damage_dealt int not null default 0,

  answered_at timestamptz default now()
);

-- =========================
-- REVIEWERS
-- =========================

create table reviewers (
  id uuid primary key default gen_random_uuid(),

  module_id uuid not null references modules(id) on delete cascade,

  title text not null,
  content text not null,

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- =========================
-- FLASHCARDS
-- =========================

create table flashcards (
  id uuid primary key default gen_random_uuid(),

  module_id uuid not null references modules(id) on delete cascade,

  question text not null,
  answer text not null,

  difficulty text not null default 'normal'
    check (difficulty in ('easy', 'normal', 'hard', 'exam')),

  order_index int not null default 0,

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- =========================
-- FLASHCARD PROGRESS
-- =========================

create table flashcard_progress (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null references profiles(id) on delete cascade,
  flashcard_id uuid not null references flashcards(id) on delete cascade,

  correct_count int not null default 0,
  wrong_count int not null default 0,

  last_reviewed_at timestamptz,
  next_review_at timestamptz,

  created_at timestamptz default now(),
  updated_at timestamptz default now(),

  constraint unique_user_flashcard_progress unique (user_id, flashcard_id)
);
