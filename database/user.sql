create extension if not exists "pgcrypto";

-- =========================
-- USERS / PROFILE
-- =========================

create table profiles (
  id uuid primary key,
  username text not null unique,
  email text not null unique,
  avatar_path text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- =========================
-- USER STATS
-- =========================

create table user_stats (
  user_id uuid primary key references profiles(id) on delete cascade,
  xp int not null default 0,
  level int not null default 1,
  coins int not null default 0,
  diamonds int not null default 0,
  streak int not null default 0,
  current_energy int not null default 5,
  max_energy int not null default 5,
  updated_at timestamptz default now()
);

-- =========================
-- FRIENDS
-- =========================

create table friends (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null references profiles(id) on delete cascade,
  friend_user_id uuid not null references profiles(id) on delete cascade,

  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'blocked')),

  created_at timestamptz default now(),

  constraint no_self_friend check (user_id <> friend_user_id),
  constraint unique_friend_pair unique (user_id, friend_user_id)
);

-- =========================
-- INVENTORY
-- =========================
-- Base item list

create table inventory_items (
  id text primary key,
  name text not null,
  type text not null,
  image_path text default '',
  description text not null default '',
  category text not null default 'consumable'
    check (category in (
      'progression',
      'consumable',
      'access',
      'special',
      'support',
      'potion',
      'boost',
      'ticket'
    )),
  item_type text not null default 'generic'
    check (item_type in (
      'generic',
      'evolutionCore',
      'xpBoostChip',
      'egg',
      'energyRefill',
      'battleTicket'
    )),
  is_premium boolean not null default false,
  is_consumable boolean not null default true,
  evolution_stages_granted int not null default 0
    check (evolution_stages_granted >= 0),
  xp_multiplier numeric(6,2),
  xp_boost_battle_count int
    check (xp_boost_battle_count is null or xp_boost_battle_count >= 0),
  egg_subject_id text,
  egg_hatch_battle_requirement int
    check (egg_hatch_battle_requirement is null or egg_hatch_battle_requirement >= 0),
  egg_hatch_duration_seconds int
    check (egg_hatch_duration_seconds is null or egg_hatch_duration_seconds >= 0),
  energy_restore_amount int
    check (energy_restore_amount is null or energy_restore_amount >= 0),
  energy_restores_to_full boolean,
  energy_pve_only boolean,
  battle_ticket_mode text
    check (battle_ticket_mode is null or battle_ticket_mode in ('pvp', 'ranked', 'both')),
  battle_ticket_required_per_entry int
    check (
      battle_ticket_required_per_entry is null
      or battle_ticket_required_per_entry > 0
    ),
  updated_at timestamptz default now()
);

-- Items owned by user

create table user_inventory (
  user_id uuid not null references profiles(id) on delete cascade,
  item_id text not null references inventory_items(id) on delete cascade,

  quantity int not null default 1,

  primary key (user_id, item_id),
  constraint positive_quantity check (quantity >= 0)
);

create table user_egg_instances (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  inventory_item_id text not null references inventory_items(id) on delete cascade,
  subject_id text,
  hatch_battle_requirement int not null default 0,
  battles_completed int not null default 0,
  hatch_duration_seconds int,
  hatched_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  constraint user_egg_instances_hatch_requirement_non_negative
    check (hatch_battle_requirement >= 0),
  constraint user_egg_instances_battles_completed_non_negative
    check (battles_completed >= 0),
  constraint user_egg_instances_duration_non_negative
    check (hatch_duration_seconds is null or hatch_duration_seconds >= 0),
  constraint user_egg_instances_battles_not_over_requirement
    check (battles_completed <= hatch_battle_requirement or hatch_battle_requirement = 0)
);

-- =========================
-- AUTH -> PROFILE SYNC
-- =========================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  base_username text;
  candidate_username text;
begin
  base_username := nullif(trim(coalesce(new.raw_user_meta_data ->> 'username', '')), '');

  if base_username is null then
    base_username := nullif(split_part(coalesce(new.email, ''), '@', 1), '');
  end if;

  if base_username is null then
    base_username := 'trainer';
  end if;

  candidate_username := base_username;

  if exists (
    select 1
    from public.profiles
    where username = candidate_username
      and id <> new.id
  ) then
    candidate_username := base_username || '_' || left(replace(new.id::text, '-', ''), 8);
  end if;

  insert into public.profiles (
    id,
    username,
    email,
    avatar_path,
    created_at,
    updated_at
  )
  values (
    new.id,
    candidate_username,
    coalesce(new.email, ''),
    'assets/pokemons/pikachu.png',
    now(),
    now()
  )
  on conflict (id) do update
  set
    email = excluded.email,
    updated_at = now();

  insert into public.user_stats (
    user_id
  )
  values (
    new.id
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.get_login_email_by_username(input_username text)
returns text
language sql
security definer
set search_path = public
as $$
  select email
  from public.profiles
  where lower(username) = lower(trim(input_username))
  limit 1;
$$;

grant execute on function public.get_login_email_by_username(text) to anon;
grant execute on function public.get_login_email_by_username(text) to authenticated;

-- =========================
-- ROW LEVEL SECURITY
-- =========================

alter table profiles enable row level security;
alter table user_stats enable row level security;
alter table friends enable row level security;
alter table user_inventory enable row level security;
alter table user_egg_instances enable row level security;

create policy "profiles_select_own"
on profiles
for select
to authenticated
using (auth.uid() = id);

create policy "profiles_insert_own"
on profiles
for insert
to authenticated
with check (auth.uid() = id);

create policy "profiles_update_own"
on profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "user_stats_select_own"
on user_stats
for select
to authenticated
using (auth.uid() = user_id);

create policy "user_stats_insert_own"
on user_stats
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "user_stats_update_own"
on user_stats
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "friends_select_involving_own_user"
on friends
for select
to authenticated
using (auth.uid() = user_id or auth.uid() = friend_user_id);

create policy "friends_insert_own"
on friends
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "friends_update_involving_own_user"
on friends
for update
to authenticated
using (auth.uid() = user_id or auth.uid() = friend_user_id)
with check (auth.uid() = user_id or auth.uid() = friend_user_id);

create policy "user_inventory_select_own"
on user_inventory
for select
to authenticated
using (auth.uid() = user_id);

create policy "user_inventory_insert_own"
on user_inventory
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "user_inventory_update_own"
on user_inventory
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "user_egg_instances_select_own"
on user_egg_instances
for select
to authenticated
using (auth.uid() = user_id);

create policy "user_egg_instances_insert_own"
on user_egg_instances
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "user_egg_instances_update_own"
on user_egg_instances
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

insert into inventory_items (
  id,
  name,
  type,
  image_path,
  description,
  category,
  item_type,
  is_premium,
  is_consumable,
  evolution_stages_granted,
  xp_multiplier,
  xp_boost_battle_count,
  egg_subject_id,
  egg_hatch_battle_requirement,
  egg_hatch_duration_seconds,
  energy_restore_amount,
  energy_restores_to_full,
  energy_pve_only,
  battle_ticket_mode,
  battle_ticket_required_per_entry,
  updated_at
)
values
  (
    'evolution_core',
    'Evolution Core',
    'progression',
    '',
    'Instantly evolves a Pokemon to its next stage.',
    'progression',
    'evolutionCore',
    true,
    true,
    1,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    now()
  ),
  (
    'xp_boost_chip',
    'XP Boost Chip',
    'boost',
    '',
    '+50% XP for the next 3 battles.',
    'boost',
    'xpBoostChip',
    false,
    true,
    0,
    1.50,
    3,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    now()
  ),
  (
    'academy_egg',
    'Academy Egg',
    'egg',
    '',
    'Hatches over time or after enough battles.',
    'progression',
    'egg',
    false,
    true,
    0,
    null,
    null,
    null,
    5,
    86400,
    null,
    null,
    null,
    null,
    null,
    now()
  ),
  (
    'energy_refill',
    'Energy Refill',
    'potion',
    '',
    'Restores stamina used for PvE modules.',
    'potion',
    'energyRefill',
    false,
    true,
    0,
    null,
    null,
    null,
    null,
    null,
    1,
    true,
    true,
    null,
    null,
    now()
  ),
  (
    'battle_ticket',
    'Battle Ticket',
    'ticket',
    '',
    'Required to enter PvP or ranked battles.',
    'ticket',
    'battleTicket',
    false,
    true,
    0,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    'both',
    1,
    now()
  );

