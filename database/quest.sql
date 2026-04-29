create extension if not exists "pgcrypto";

-- =========================================================
-- QUESTS / REWARD CONFIG
-- Matches:
--   lib/core/models/quest.dart
--   lib/core/models/reward.dart
--   lib/core/data/quests.dart
--   lib/core/data/rewards.dart
-- =========================================================

-- =========================================================
-- QUEST CATALOG
-- =========================================================

create table if not exists public.quests (
  id text primary key,
  title text not null,
  description text not null,
  rarity text not null
    check (rarity in ('common', 'uncommon', 'rare', 'epic', 'legendary')),
  daily_appearance_chance numeric(6,5) not null
    check (daily_appearance_chance >= 0 and daily_appearance_chance <= 1),
  reward_xp int not null default 0 check (reward_xp >= 0),
  reward_coins int not null default 0 check (reward_coins >= 0),
  reward_diamonds int not null default 0 check (reward_diamonds >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.quest_reward_items (
  quest_id text not null references public.quests(id) on delete cascade,
  item_id text not null references public.inventory_items(id) on delete restrict,
  quantity int not null default 1 check (quantity > 0),
  primary key (quest_id, item_id)
);

create index if not exists quest_reward_items_item_id_idx
  on public.quest_reward_items(item_id);

-- Tracks which quests were assigned to a user on a given day.
create table if not exists public.user_daily_quests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  quest_id text not null references public.quests(id) on delete cascade,
  assigned_for_date date not null,
  progress int not null default 0 check (progress >= 0),
  goal int not null default 1 check (goal > 0),
  completed_at timestamptz,
  claimed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_daily_quests_unique_assignment
    unique (user_id, quest_id, assigned_for_date),
  constraint user_daily_quests_claim_requires_completion
    check (claimed_at is null or completed_at is not null)
);

create index if not exists user_daily_quests_user_date_idx
  on public.user_daily_quests(user_id, assigned_for_date);

-- =========================================================
-- PVE REWARD TABLES
-- =========================================================

create table if not exists public.pve_reward_scenarios (
  id text primary key,
  label text not null,
  min_performance numeric(4,3) not null
    check (min_performance >= 0 and min_performance <= 1),
  max_performance numeric(4,3) not null
    check (max_performance >= 0 and max_performance <= 1),
  xp_min int not null default 0 check (xp_min >= 0),
  xp_max int not null default 0 check (xp_max >= xp_min),
  coins_min int not null default 0 check (coins_min >= 0),
  coins_max int not null default 0 check (coins_max >= coins_min),
  diamonds_min int not null default 0 check (diamonds_min >= 0),
  diamonds_max int not null default 0 check (diamonds_max >= diamonds_min),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pve_reward_scenarios_performance_range_valid
    check (max_performance >= min_performance)
);

create table if not exists public.pve_reward_drops (
  scenario_id text not null references public.pve_reward_scenarios(id) on delete cascade,
  item_id text not null references public.inventory_items(id) on delete restrict,
  drop_chance numeric(6,5) not null
    check (drop_chance >= 0 and drop_chance <= 1),
  min_quantity int not null default 1 check (min_quantity > 0),
  max_quantity int not null default 1 check (max_quantity >= min_quantity),
  primary key (scenario_id, item_id)
);

-- =========================================================
-- LEVEL-UP REWARD TABLES
-- =========================================================

create table if not exists public.level_up_rewards (
  level int primary key check (level > 0),
  reward_xp int not null default 0 check (reward_xp >= 0),
  reward_coins int not null default 0 check (reward_coins >= 0),
  reward_diamonds int not null default 0 check (reward_diamonds >= 0),
  guaranteed_egg_item_id text not null
    references public.inventory_items(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.level_up_reward_items (
  level int not null references public.level_up_rewards(level) on delete cascade,
  item_id text not null references public.inventory_items(id) on delete restrict,
  quantity int not null default 1 check (quantity > 0),
  primary key (level, item_id)
);

-- =========================================================
-- WEEKLY DAILY CLAIM TABLES
-- =========================================================

create table if not exists public.weekly_claim_rewards (
  day_number int primary key
    check (day_number >= 1 and day_number <= 7),
  reward_xp int not null default 0 check (reward_xp >= 0),
  reward_coins int not null default 0 check (reward_coins >= 0),
  reward_diamonds int not null default 0 check (reward_diamonds >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.weekly_claim_reward_items (
  day_number int not null references public.weekly_claim_rewards(day_number) on delete cascade,
  item_id text not null references public.inventory_items(id) on delete restrict,
  quantity int not null default 1 check (quantity > 0),
  primary key (day_number, item_id)
);

create table if not exists public.user_weekly_claims (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  week_start_date date not null,
  current_day int not null default 1 check (current_day >= 1 and current_day <= 7),
  last_claimed_day int check (last_claimed_day is null or (last_claimed_day >= 1 and last_claimed_day <= 7)),
  last_claimed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_weekly_claims_unique_week unique (user_id, week_start_date)
);

create index if not exists user_weekly_claims_user_week_idx
  on public.user_weekly_claims(user_id, week_start_date desc);

-- =========================================================
-- SEED QUESTS
-- =========================================================

insert into public.quests (
  id,
  title,
  description,
  rarity,
  daily_appearance_chance,
  reward_xp,
  reward_coins,
  reward_diamonds,
  is_active,
  updated_at
)
values
  ('quest_first_review', 'First Review', 'Complete 1 study review session.', 'common', 0.55, 40, 180, 0, true, now()),
  ('quest_focus_sprint', 'Focus Sprint', 'Finish a 15-minute focus timer without leaving the session.', 'common', 0.55, 60, 240, 0, true, now()),
  ('quest_flashcard_chain', 'Flashcard Chain', 'Answer 20 flashcards in a single streak.', 'uncommon', 0.30, 85, 320, 2, true, now()),
  ('quest_two_victories', 'Double Victory', 'Win 2 PvE battles in one day.', 'uncommon', 0.30, 110, 420, 0, true, now()),
  ('quest_perfect_quiz', 'Perfect Quiz', 'Score 100% on a study activity with at least 10 prompts.', 'rare', 0.11, 140, 520, 4, true, now()),
  ('quest_boss_warmup', 'Boss Warm-Up', 'Defeat 3 standard PvE opponents without losing a round.', 'rare', 0.11, 160, 650, 0, true, now()),
  ('quest_study_marathon', 'Study Marathon', 'Accumulate 60 minutes of total focus time in one day.', 'epic', 0.035, 220, 900, 8, true, now()),
  ('quest_clean_sweep', 'Clean Sweep', 'Win 5 battles in a row across any game mode.', 'epic', 0.035, 260, 1100, 10, true, now()),
  ('quest_rank_climber', 'Rank Climber', 'Complete 3 PvP matches and win at least 2 of them.', 'legendary', 0.005, 320, 1400, 12, true, now()),
  ('quest_master_scholar', 'Master Scholar', 'Finish a study session, a focus session, and a battle streak all in the same day.', 'legendary', 0.005, 450, 1800, 20, true, now())
on conflict (id) do update
set
  title = excluded.title,
  description = excluded.description,
  rarity = excluded.rarity,
  daily_appearance_chance = excluded.daily_appearance_chance,
  reward_xp = excluded.reward_xp,
  reward_coins = excluded.reward_coins,
  reward_diamonds = excluded.reward_diamonds,
  is_active = excluded.is_active,
  updated_at = now();

insert into public.quest_reward_items (quest_id, item_id, quantity)
values
  ('quest_focus_sprint', 'reward_energy_refill', 1),
  ('quest_two_victories', 'reward_battle_ticket', 1),
  ('quest_perfect_quiz', 'reward_xp_boost_chip', 1),
  ('quest_boss_warmup', 'reward_egg_common', 1),
  ('quest_study_marathon', 'reward_egg_uncommon', 1),
  ('quest_clean_sweep', 'reward_egg_rare', 1),
  ('quest_rank_climber', 'reward_evolution_core', 1),
  ('quest_master_scholar', 'reward_egg_legendary', 1),
  ('quest_master_scholar', 'reward_xp_boost_chip', 1)
on conflict (quest_id, item_id) do update
set quantity = excluded.quantity;

-- =========================================================
-- SEED PVE REWARD CONFIG
-- =========================================================

insert into public.pve_reward_scenarios (
  id,
  label,
  min_performance,
  max_performance,
  xp_min,
  xp_max,
  coins_min,
  coins_max,
  diamonds_min,
  diamonds_max,
  updated_at
)
values
  ('pve_barely_cleared', 'Barely Cleared', 0.000, 0.349, 20, 80, 100, 300, 0, 2, now()),
  ('pve_steady_run', 'Steady Run', 0.350, 0.649, 70, 180, 250, 700, 0, 8, now()),
  ('pve_strong_finish', 'Strong Finish', 0.650, 0.899, 150, 320, 700, 1400, 3, 18, now()),
  ('pve_perfect_sweep', 'Perfect Sweep', 0.900, 1.000, 280, 500, 1200, 2000, 10, 30, now())
on conflict (id) do update
set
  label = excluded.label,
  min_performance = excluded.min_performance,
  max_performance = excluded.max_performance,
  xp_min = excluded.xp_min,
  xp_max = excluded.xp_max,
  coins_min = excluded.coins_min,
  coins_max = excluded.coins_max,
  diamonds_min = excluded.diamonds_min,
  diamonds_max = excluded.diamonds_max,
  updated_at = now();

insert into public.pve_reward_drops (
  scenario_id,
  item_id,
  drop_chance,
  min_quantity,
  max_quantity
)
values
  ('pve_barely_cleared', 'reward_energy_refill', 0.08000, 1, 1),
  ('pve_barely_cleared', 'reward_egg_common', 0.02000, 1, 1),
  ('pve_steady_run', 'reward_energy_refill', 0.14000, 1, 1),
  ('pve_steady_run', 'reward_battle_ticket', 0.08000, 1, 1),
  ('pve_steady_run', 'reward_egg_common', 0.04000, 1, 1),
  ('pve_strong_finish', 'reward_xp_boost_chip', 0.18000, 1, 1),
  ('pve_strong_finish', 'reward_battle_ticket', 0.12000, 1, 1),
  ('pve_strong_finish', 'reward_egg_uncommon', 0.06000, 1, 1),
  ('pve_strong_finish', 'reward_egg_rare', 0.02500, 1, 1),
  ('pve_perfect_sweep', 'reward_xp_boost_chip', 0.25000, 1, 2),
  ('pve_perfect_sweep', 'reward_energy_refill', 0.20000, 1, 1),
  ('pve_perfect_sweep', 'reward_evolution_core', 0.08000, 1, 1),
  ('pve_perfect_sweep', 'reward_egg_uncommon', 0.10000, 1, 1),
  ('pve_perfect_sweep', 'reward_egg_rare', 0.05000, 1, 1),
  ('pve_perfect_sweep', 'reward_egg_ultra_rare', 0.01500, 1, 1)
on conflict (scenario_id, item_id) do update
set
  drop_chance = excluded.drop_chance,
  min_quantity = excluded.min_quantity,
  max_quantity = excluded.max_quantity;

-- =========================================================
-- SEED WEEKLY DAILY CLAIM CONFIG
-- =========================================================

insert into public.weekly_claim_rewards (
  day_number,
  reward_xp,
  reward_coins,
  reward_diamonds,
  updated_at
)
values
  (1, 25, 150, 0, now()),
  (2, 35, 220, 0, now()),
  (3, 45, 300, 2, now()),
  (4, 55, 380, 0, now()),
  (5, 70, 450, 4, now()),
  (6, 90, 600, 0, now()),
  (7, 120, 900, 8, now())
on conflict (day_number) do update
set
  reward_xp = excluded.reward_xp,
  reward_coins = excluded.reward_coins,
  reward_diamonds = excluded.reward_diamonds,
  updated_at = now();

insert into public.weekly_claim_reward_items (day_number, item_id, quantity)
values
  (2, 'reward_energy_refill', 1),
  (4, 'reward_battle_ticket', 1),
  (6, 'reward_egg_common', 1),
  (7, 'reward_egg_legendary', 1)
on conflict (day_number, item_id) do update
set quantity = excluded.quantity;

-- =========================================================
-- SEED LEVEL-UP CONFIG
-- Add more rows over time as you define higher levels.
-- Every level-up guarantees an egg.
-- =========================================================

insert into public.level_up_rewards (
  level,
  reward_xp,
  reward_coins,
  reward_diamonds,
  guaranteed_egg_item_id,
  updated_at
)
values
  (1, 60, 310, 2, 'reward_egg_common', now()),
  (2, 70, 370, 2, 'reward_egg_common', now()),
  (3, 80, 430, 2, 'reward_egg_common', now()),
  (4, 90, 490, 3, 'reward_egg_common', now()),
  (5, 100, 550, 3, 'reward_egg_uncommon', now()),
  (6, 110, 610, 3, 'reward_egg_uncommon', now()),
  (7, 120, 670, 3, 'reward_egg_uncommon', now()),
  (8, 130, 730, 4, 'reward_egg_uncommon', now()),
  (9, 140, 790, 4, 'reward_egg_uncommon', now()),
  (10, 150, 850, 4, 'reward_egg_rare', now())
on conflict (level) do update
set
  reward_xp = excluded.reward_xp,
  reward_coins = excluded.reward_coins,
  reward_diamonds = excluded.reward_diamonds,
  guaranteed_egg_item_id = excluded.guaranteed_egg_item_id,
  updated_at = now();

insert into public.level_up_reward_items (level, item_id, quantity)
values
  (5, 'reward_xp_boost_chip', 1),
  (10, 'reward_xp_boost_chip', 1),
  (10, 'reward_evolution_core', 1)
on conflict (level, item_id) do update
set quantity = excluded.quantity;

-- =========================================================
-- RLS
-- Catalog/config tables are readable by authenticated users.
-- User progress tables are private to each player.
-- =========================================================

alter table public.quests enable row level security;
alter table public.quest_reward_items enable row level security;
alter table public.user_daily_quests enable row level security;
alter table public.pve_reward_scenarios enable row level security;
alter table public.pve_reward_drops enable row level security;
alter table public.level_up_rewards enable row level security;
alter table public.level_up_reward_items enable row level security;
alter table public.weekly_claim_rewards enable row level security;
alter table public.weekly_claim_reward_items enable row level security;
alter table public.user_weekly_claims enable row level security;

create policy "quests_select_authenticated"
on public.quests
for select
to authenticated
using (true);

create policy "quest_reward_items_select_authenticated"
on public.quest_reward_items
for select
to authenticated
using (true);

create policy "pve_reward_scenarios_select_authenticated"
on public.pve_reward_scenarios
for select
to authenticated
using (true);

create policy "pve_reward_drops_select_authenticated"
on public.pve_reward_drops
for select
to authenticated
using (true);

create policy "level_up_rewards_select_authenticated"
on public.level_up_rewards
for select
to authenticated
using (true);

create policy "level_up_reward_items_select_authenticated"
on public.level_up_reward_items
for select
to authenticated
using (true);

create policy "weekly_claim_rewards_select_authenticated"
on public.weekly_claim_rewards
for select
to authenticated
using (true);

create policy "weekly_claim_reward_items_select_authenticated"
on public.weekly_claim_reward_items
for select
to authenticated
using (true);

create policy "user_daily_quests_select_own"
on public.user_daily_quests
for select
to authenticated
using (auth.uid() = user_id);

create policy "user_daily_quests_insert_own"
on public.user_daily_quests
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "user_daily_quests_update_own"
on public.user_daily_quests
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "user_weekly_claims_select_own"
on public.user_weekly_claims
for select
to authenticated
using (auth.uid() = user_id);

create policy "user_weekly_claims_insert_own"
on public.user_weekly_claims
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "user_weekly_claims_update_own"
on public.user_weekly_claims
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
