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
