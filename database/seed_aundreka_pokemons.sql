begin;

do $$
declare
  target_user_id uuid;
begin
  select id
  into target_user_id
  from public.profiles
  where lower(username) = lower('aundreka')
  limit 1;

  if target_user_id is null then
    raise exception 'Profile with username "%" was not found.', 'aundreka';
  end if;

  insert into public.owned_pokemons (
    user_id,
    pokemon_id,
    level,
    xp,
    current_hp,
    nickname,
    created_at,
    updated_at
  )
  select
    target_user_id,
    seed.pokemon_id,
    seed.level,
    seed.xp,
    seed.current_hp,
    seed.nickname,
    now(),
    now()
  from (
    values
      ('abra1', 1, 0, 25, null),
      ('abra2', 1, 0, 45, null),
      ('abra3', 1, 0, 55, null),
      ('charmander1', 1, 0, 39, null),
      ('charmander2', 1, 0, 58, null),
      ('charmander3', 1, 0, 78, null),
      ('bulbasaur1', 1, 0, 45, null),
      ('bulbasaur2', 1, 0, 60, null),
      ('bulbasaur3', 1, 0, 80, null),
      ('squirtle1', 1, 0, 44, null),
      ('squirtle2', 1, 0, 59, null),
      ('squirtle3', 1, 0, 79, null),
      ('pichu1', 1, 0, 20, null),
      ('pichu2', 1, 0, 35, null),
      ('pichu3', 1, 0, 60, null),
      ('gastly1', 1, 0, 30, null),
      ('gastly2', 1, 0, 45, null),
      ('gastly3', 1, 0, 60, null),
      ('oddish1', 1, 0, 45, null),
      ('oddish2', 1, 0, 60, null),
      ('oddish3', 1, 0, 75, null),
      ('magikarp1', 1, 0, 20, null),
      ('magikarp2', 1, 0, 95, null),
      ('eevee1', 1, 0, 55, null),
      ('eevee2a', 1, 0, 130, null),
      ('eevee2b', 1, 0, 65, null),
      ('eevee2c', 1, 0, 65, null),
      ('ralts1', 1, 0, 28, null),
      ('ralts2', 1, 0, 38, null),
      ('ralts3', 1, 0, 68, null),
      ('dratini1', 1, 0, 41, null),
      ('dratini2', 1, 0, 61, null),
      ('dratini3', 1, 0, 91, null),
      ('pidgey1', 1, 0, 40, null),
      ('pidgey2', 1, 0, 63, null),
      ('pidgey3', 1, 0, 83, null),
      ('mewtwo1', 1, 0, 106, 'Lab Breakout')
  ) as seed(pokemon_id, level, xp, current_hp, nickname)
  where not exists (
    select 1
    from public.owned_pokemons existing
    where existing.user_id = target_user_id
      and existing.pokemon_id = seed.pokemon_id
  );
end;
$$;

commit;
