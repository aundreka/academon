begin;

-- Rename shop eggs to the new tier names.
update public.inventory_items
set name = 'Starter Egg',
    updated_at = now()
where id = 'egg_common_general';

update public.inventory_items
set name = 'Mystic Egg',
    updated_at = now()
where id = 'egg_uncommon_math';

update public.inventory_items
set name = 'Celestial Egg',
    updated_at = now()
where id = 'egg_ultra_rare_botany';

update public.inventory_items
set name = 'Mythic Egg',
    updated_at = now()
where id = 'egg_legendary_history';

-- Remove the old purchasable Rare egg from the shop catalog.
delete from public.inventory_items
where id = 'egg_rare_science';

-- Rename reward eggs to match the new naming.
update public.inventory_items
set name = 'Starter Egg',
    updated_at = now()
where id = 'reward_egg_common';

update public.inventory_items
set name = 'Mystic Egg',
    updated_at = now()
where id = 'reward_egg_uncommon';

update public.inventory_items
set name = 'Arcane Egg',
    updated_at = now()
where id = 'reward_egg_rare';

update public.inventory_items
set name = 'Celestial Egg',
    updated_at = now()
where id = 'reward_egg_ultra_rare';

update public.inventory_items
set name = 'Mythic Egg',
    updated_at = now()
where id = 'reward_egg_legendary';

-- Topic catalog used by study, arena, and chatbot generation.
create table if not exists public.topics (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references public.profiles(id) on delete set null,
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
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.modules
  add column if not exists category text not null default 'General',
  add column if not exists image_url text,
  add column if not exists popularity_count int not null default 0,
  add column if not exists last_used_at timestamptz,
  add column if not exists topic_id uuid references public.topics(id) on delete set null;

alter table public.modules
  drop constraint if exists modules_source_type_check;

alter table public.modules
  add constraint modules_source_type_check
  check (source_type in ('topic', 'upload', 'generated'));

create table if not exists public.module_lessons (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.modules(id) on delete cascade,
  title text not null,
  description text,
  order_index int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.topic_lessons (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references public.topics(id) on delete cascade,
  title text not null,
  description text,
  order_index int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists modules_user_updated_idx
  on public.modules(user_id, updated_at desc);

create index if not exists modules_topic_id_idx
  on public.modules(topic_id);

create index if not exists modules_popularity_category_idx
  on public.modules(popularity_count desc, category, title);

create index if not exists topics_status_popularity_idx
  on public.topics(status, popularity_count desc, updated_at desc);

create index if not exists topics_category_title_idx
  on public.topics(category, title);

create index if not exists module_lessons_module_order_idx
  on public.module_lessons(module_id, order_index);

create index if not exists topic_lessons_topic_order_idx
  on public.topic_lessons(topic_id, order_index);

create index if not exists questions_module_type_order_idx
  on public.questions(module_id, question_type, order_index, created_at);

-- Ranked PvP now writes pvp_ranked into battle_history.
alter table public.battle_history
  drop constraint if exists battle_history_battle_type_check;

alter table public.battle_history
  add constraint battle_history_battle_type_check
  check (battle_type in ('pve', 'pvp', 'ranked', 'pvp_ranked'));

commit;
