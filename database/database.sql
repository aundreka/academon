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

