-- =========================
-- OWNED POKEMONS
-- =========================
-- pokemon_id refers to your local Flutter Pokemon.id
-- Example: 'geofox_small'

create table owned_pokemons (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,

  pokemon_id text not null,

  level int not null default 1 check (level >= 1),
  xp int not null default 0 check (xp >= 0),
  current_hp int not null check (current_hp >= 0),
  nickname text,

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists owned_pokemons_user_id_idx
on owned_pokemons(user_id, created_at desc);

-- =========================
-- POKEMON TEAMS
-- =========================

create table pokemon_teams (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  name text not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table pokemon_team_members (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references pokemon_teams(id) on delete cascade,
  owned_pokemon_id uuid not null references owned_pokemons(id) on delete cascade,
  slot_number int not null,

  constraint team_slot_limit check (slot_number between 1 and 5),
  constraint unique_team_slot unique (team_id, slot_number),
  constraint unique_pokemon_in_team unique (team_id, owned_pokemon_id)
);

-- =========================
-- BATTLE HISTORY
-- =========================

create table user_item_effects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  source_item_id text not null references inventory_items(id) on delete cascade,
  effect_type text not null check (effect_type in ('xp_boost')),
  multiplier numeric(6,2),
  remaining_battle_count int check (
    remaining_battle_count is null or remaining_battle_count >= 0
  ),
  started_at timestamptz not null default now(),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table battle_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,

  opponent_name text not null,
  battle_type text not null check (battle_type in ('pve', 'pvp', 'ranked', 'pvp_ranked')),
  won boolean not null default false,
  ticket_item_id text references inventory_items(id) on delete set null,
  ticket_cost int not null default 0 check (ticket_cost >= 0),
  xp_boost_effect_id uuid references user_item_effects(id) on delete set null,
  xp_multiplier_applied numeric(6,2) not null default 1.00,

  xp_earned int not null default 0,
  coins_earned int not null default 0,

  battled_at timestamptz not null default now()
);

-- =========================
-- ROW LEVEL SECURITY
-- =========================

alter table owned_pokemons enable row level security;
alter table pokemon_teams enable row level security;
alter table pokemon_team_members enable row level security;
alter table battle_history enable row level security;
alter table user_item_effects enable row level security;

create policy "owned_pokemons_select_own"
on owned_pokemons
for select
to authenticated
using (auth.uid() = user_id);

create policy "owned_pokemons_insert_own"
on owned_pokemons
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "owned_pokemons_update_own"
on owned_pokemons
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "pokemon_teams_select_own"
on pokemon_teams
for select
to authenticated
using (auth.uid() = user_id);

create policy "pokemon_teams_insert_own"
on pokemon_teams
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "pokemon_teams_update_own"
on pokemon_teams
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "pokemon_team_members_select_own"
on pokemon_team_members
for select
to authenticated
using (
  exists (
    select 1
    from pokemon_teams
    where pokemon_teams.id = pokemon_team_members.team_id
      and pokemon_teams.user_id = auth.uid()
  )
);

create policy "pokemon_team_members_insert_own"
on pokemon_team_members
for insert
to authenticated
with check (
  exists (
    select 1
    from pokemon_teams
    where pokemon_teams.id = pokemon_team_members.team_id
      and pokemon_teams.user_id = auth.uid()
  )
);

create policy "pokemon_team_members_update_own"
on pokemon_team_members
for update
to authenticated
using (
  exists (
    select 1
    from pokemon_teams
    where pokemon_teams.id = pokemon_team_members.team_id
      and pokemon_teams.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from pokemon_teams
    where pokemon_teams.id = pokemon_team_members.team_id
      and pokemon_teams.user_id = auth.uid()
  )
);

create policy "battle_history_select_own"
on battle_history
for select
to authenticated
using (auth.uid() = user_id);

create policy "battle_history_insert_own"
on battle_history
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "battle_history_update_own"
on battle_history
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "user_item_effects_select_own"
on user_item_effects
for select
to authenticated
using (auth.uid() = user_id);

create policy "user_item_effects_insert_own"
on user_item_effects
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "user_item_effects_update_own"
on user_item_effects
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
