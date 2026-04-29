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
  image_path text default ''
);

-- Items owned by user

create table user_inventory (
  user_id uuid not null references profiles(id) on delete cascade,
  item_id text not null references inventory_items(id) on delete cascade,

  quantity int not null default 1,

  primary key (user_id, item_id),
  constraint positive_quantity check (quantity >= 0)
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

