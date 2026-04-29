-- =========================
-- OWNED POKEMONS
-- =========================
-- pokemon_id refers to your local Flutter Pokemon.id
-- Example: 'geofox_small'

create table owned_pokemons (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,

  pokemon_id text not null,

  level int not null default 1,
  xp int not null default 0,
  current_hp int not null,
  nickname text,

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

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

create table battle_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,

  opponent_name text not null,
  battle_type text not null check (battle_type in ('pve', 'pvp')),
  won boolean not null default false,

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
