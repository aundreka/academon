create extension if not exists "pgcrypto";

-- =========================
-- INVENTORY ITEM UPGRADES
-- =========================

alter table if exists public.inventory_items
  add column if not exists coin_value int not null default 0;

alter table if exists public.inventory_items
  add column if not exists diamond_value int not null default 0;

alter table if exists public.inventory_items
  add column if not exists egg_rarity text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'inventory_items_coin_value_non_negative'
  ) then
    alter table public.inventory_items
      add constraint inventory_items_coin_value_non_negative
      check (coin_value >= 0);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'inventory_items_diamond_value_non_negative'
  ) then
    alter table public.inventory_items
      add constraint inventory_items_diamond_value_non_negative
      check (diamond_value >= 0);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'inventory_items_egg_rarity_check'
  ) then
    alter table public.inventory_items
      add constraint inventory_items_egg_rarity_check
      check (
        egg_rarity is null
        or egg_rarity in ('common', 'uncommon', 'rare', 'ultra_rare', 'legendary')
      );
  end if;
end $$;

update public.inventory_items
set coin_value = 0
where coin_value is null;

update public.inventory_items
set diamond_value = 0
where diamond_value is null;

-- =========================
-- EGG INSTANCE UPGRADES
-- =========================

alter table if exists public.user_egg_instances
  add column if not exists egg_rarity text not null default 'common';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'user_egg_instances_egg_rarity_check'
  ) then
    alter table public.user_egg_instances
      add constraint user_egg_instances_egg_rarity_check
      check (egg_rarity in ('common', 'uncommon', 'rare', 'ultra_rare', 'legendary'));
  end if;
end $$;

update public.user_egg_instances
set egg_rarity = 'common'
where egg_rarity is null;

create or replace function public.enforce_max_active_egg_instances()
returns trigger
language plpgsql
as $$
declare
  active_egg_count int;
begin
  if new.hatched_at is not null then
    return new;
  end if;

  select count(*)
  into active_egg_count
  from public.user_egg_instances
  where user_id = new.user_id
    and hatched_at is null
    and id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid);

  if active_egg_count >= 3 then
    raise exception 'Only 3 eggs can be hatched at one time.';
  end if;

  return new;
end;
$$;

drop trigger if exists user_egg_instances_max_active_trigger on public.user_egg_instances;

create trigger user_egg_instances_max_active_trigger
before insert or update on public.user_egg_instances
for each row execute procedure public.enforce_max_active_egg_instances();

-- =========================
-- ROW LEVEL SECURITY UPGRADES
-- =========================

alter table if exists public.inventory_items enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'inventory_items'
      and policyname = 'inventory_items_select_authenticated'
  ) then
    create policy "inventory_items_select_authenticated"
    on public.inventory_items
    for select
    to authenticated
    using (true);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'user_inventory'
      and policyname = 'user_inventory_delete_own'
  ) then
    create policy "user_inventory_delete_own"
    on public.user_inventory
    for delete
    to authenticated
    using (auth.uid() = user_id);
  end if;
end $$;

-- =========================
-- CATALOG DATA UPGRADES
-- =========================

insert into public.inventory_items (
  id,
  name,
  type,
  image_path,
  description,
  coin_value,
  diamond_value,
  category,
  item_type,
  is_premium,
  is_consumable,
  evolution_stages_granted,
  xp_multiplier,
  xp_boost_battle_count,
  egg_subject_id,
  egg_rarity,
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
    'assets/items/evolution_core.png',
    'Instantly evolves a Pokemon to its next stage.',
    2500,
    25,
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
    null,
    now()
  ),
  (
    'xp_boost_chip',
    'XP Boost Chip',
    'boost',
    'assets/items/xp_boost_chip.png',
    '+50% XP for the next 3 battles.',
    500,
    5,
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
    null,
    now()
  ),
  (
    'egg_common_general',
    'Common Egg',
    'egg',
    'assets/items/common_egg.png',
    'Hatches over time or after enough battles.',
    750,
    8,
    'progression',
    'egg',
    false,
    true,
    0,
    null,
    null,
    'General Knowledge',
    'common',
    3,
    1800,
    null,
    null,
    null,
    null,
    null,
    now()
  ),
  (
    'egg_uncommon_math',
    'Uncommon Egg',
    'egg',
    'assets/items/uncommon_egg.png',
    'Hatches over time or after enough battles.',
    950,
    10,
    'progression',
    'egg',
    false,
    true,
    0,
    null,
    null,
    'Mathematics',
    'uncommon',
    4,
    3600,
    null,
    null,
    null,
    null,
    null,
    now()
  ),
  (
    'egg_rare_science',
    'Rare Egg',
    'egg',
    'assets/items/rare_egg.png',
    'Hatches over time or after enough battles.',
    1200,
    12,
    'progression',
    'egg',
    false,
    true,
    0,
    null,
    null,
    'Science',
    'rare',
    5,
    7200,
    null,
    null,
    null,
    null,
    null,
    now()
  ),
  (
    'egg_ultra_rare_botany',
    'Ultra Rare Egg',
    'egg',
    'assets/items/ultra_rare_egg.png',
    'Hatches over time or after enough battles.',
    1800,
    18,
    'progression',
    'egg',
    false,
    true,
    0,
    null,
    null,
    'Botany',
    'ultra_rare',
    6,
    14400,
    null,
    null,
    null,
    null,
    null,
    now()
  ),
  (
    'egg_legendary_history',
    'Legendary Egg',
    'egg',
    'assets/items/legendary_egg.png',
    'Hatches over time or after enough battles.',
    2400,
    24,
    'progression',
    'egg',
    false,
    true,
    0,
    null,
    null,
    'History',
    'legendary',
    8,
    28800,
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
    'assets/items/energy_refill.png',
    'Restores stamina used for PvE modules.',
    300,
    3,
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
    'assets/items/battle_ticket.png',
    'Required to enter PvP or ranked battles.',
    400,
    4,
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
    null,
    'both',
    1,
    now()
  ),
  (
    'reward_egg_common',
    'Campus Egg',
    'egg',
    'assets/items/common_egg.png',
    'Quest reward egg for General Knowledge progression.',
    750,
    8,
    'progression',
    'egg',
    false,
    true,
    0,
    null,
    null,
    'General Knowledge',
    'common',
    3,
    1800,
    null,
    null,
    null,
    null,
    null,
    now()
  ),
  (
    'reward_egg_uncommon',
    'Quiz Egg',
    'egg',
    'assets/items/common_egg.png',
    'Quest reward egg for Literature progression.',
    900,
    10,
    'progression',
    'egg',
    false,
    true,
    0,
    null,
    null,
    'Literature',
    'uncommon',
    4,
    3600,
    null,
    null,
    null,
    null,
    null,
    now()
  ),
  (
    'reward_egg_rare',
    'Scholar Egg',
    'egg',
    'assets/items/rare_egg.png',
    'Quest reward egg for Science progression.',
    1200,
    12,
    'progression',
    'egg',
    false,
    true,
    0,
    null,
    null,
    'Science',
    'rare',
    5,
    7200,
    null,
    null,
    null,
    null,
    null,
    now()
  ),
  (
    'reward_egg_ultra_rare',
    'Prism Egg',
    'egg',
    'assets/items/ultra_rare_egg.png',
    'Quest reward egg for Botany progression.',
    1800,
    18,
    'progression',
    'egg',
    false,
    true,
    0,
    null,
    null,
    'Botany',
    'ultra_rare',
    6,
    14400,
    null,
    null,
    null,
    null,
    null,
    now()
  ),
  (
    'reward_egg_legendary',
    'Mythic Egg',
    'egg',
    'assets/items/legendary_egg.png',
    'High-tier reward egg for History progression.',
    2400,
    24,
    'progression',
    'egg',
    false,
    true,
    0,
    null,
    null,
    'History',
    'legendary',
    8,
    28800,
    null,
    null,
    null,
    null,
    null,
    now()
  ),
  (
    'reward_xp_boost_chip',
    'XP Boost Chip',
    'boost',
    'assets/items/xp_boost_chip.png',
    '+50% XP for the next 3 battles.',
    500,
    5,
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
    null,
    now()
  ),
  (
    'reward_energy_refill',
    'Energy Refill',
    'potion',
    'assets/items/energy_refill.png',
    'Restores stamina used for PvE modules.',
    300,
    3,
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
    null,
    1,
    true,
    true,
    null,
    null,
    now()
  ),
  (
    'reward_battle_ticket',
    'Battle Ticket',
    'ticket',
    'assets/items/battle_ticket.png',
    'Required to enter PvP or ranked battles.',
    400,
    4,
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
    null,
    'both',
    1,
    now()
  ),
  (
    'reward_evolution_core',
    'Evolution Core',
    'progression',
    'assets/items/evolution_core.png',
    'Instantly evolves a Pokemon to its next stage.',
    2500,
    25,
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
    null,
    now()
  )
on conflict (id) do update
set
  name = excluded.name,
  type = excluded.type,
  image_path = excluded.image_path,
  description = excluded.description,
  coin_value = excluded.coin_value,
  diamond_value = excluded.diamond_value,
  category = excluded.category,
  item_type = excluded.item_type,
  is_premium = excluded.is_premium,
  is_consumable = excluded.is_consumable,
  evolution_stages_granted = excluded.evolution_stages_granted,
  xp_multiplier = excluded.xp_multiplier,
  xp_boost_battle_count = excluded.xp_boost_battle_count,
  egg_subject_id = excluded.egg_subject_id,
  egg_rarity = excluded.egg_rarity,
  egg_hatch_battle_requirement = excluded.egg_hatch_battle_requirement,
  egg_hatch_duration_seconds = excluded.egg_hatch_duration_seconds,
  energy_restore_amount = excluded.energy_restore_amount,
  energy_restores_to_full = excluded.energy_restores_to_full,
  energy_pve_only = excluded.energy_pve_only,
  battle_ticket_mode = excluded.battle_ticket_mode,
  battle_ticket_required_per_entry = excluded.battle_ticket_required_per_entry,
  updated_at = now();
