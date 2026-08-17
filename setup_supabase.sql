-- Pink Memory - Supabase Complete Setup
-- Run this entire file once in Supabase SQL Editor.
-- Then create a PRIVATE Storage bucket named: memory-photos

create extension if not exists pgcrypto;

create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  title text not null default '我们的见面存档',
  invite_code text not null unique,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.game_members (
  game_id uuid not null references public.games(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null default '',
  created_at timestamptz not null default now(),
  primary key (game_id, user_id)
);

create table if not exists public.memories (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games(id) on delete cascade,
  title text not null default '',
  memory_date date,
  place text not null default '',
  note text not null default '',
  game_type text not null default 'puzzle',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.memory_photos (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games(id) on delete cascade,
  memory_id uuid not null references public.memories(id) on delete cascade,
  storage_path text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.progress (
  game_id uuid not null references public.games(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  memory_id uuid not null references public.memories(id) on delete cascade,
  completed boolean not null default true,
  updated_at timestamptz not null default now(),
  primary key (user_id, memory_id)
);

create index if not exists idx_game_members_user
  on public.game_members(user_id);

create index if not exists idx_memories_game
  on public.memories(game_id, sort_order);

create index if not exists idx_memory_photos_game
  on public.memory_photos(game_id, memory_id, sort_order);

create index if not exists idx_progress_game_user
  on public.progress(game_id, user_id);

alter table public.games enable row level security;
alter table public.game_members enable row level security;
alter table public.memories enable row level security;
alter table public.memory_photos enable row level security;
alter table public.progress enable row level security;

create or replace function public.is_game_member(p_game_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.game_members gm
    where gm.game_id = p_game_id
      and gm.user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_game_member(uuid) from public, anon;
grant execute on function public.is_game_member(uuid) to authenticated;

drop policy if exists games_select_member on public.games;
drop policy if exists games_update_member on public.games;
drop policy if exists members_select_member on public.game_members;
drop policy if exists memories_all_member on public.memories;
drop policy if exists photos_all_member on public.memory_photos;
drop policy if exists progress_select_own on public.progress;
drop policy if exists progress_insert_own on public.progress;
drop policy if exists progress_update_own on public.progress;
drop policy if exists progress_delete_own on public.progress;

create policy games_select_member
on public.games
for select
to authenticated
using (public.is_game_member(id));

create policy games_update_member
on public.games
for update
to authenticated
using (public.is_game_member(id))
with check (public.is_game_member(id));

create policy members_select_member
on public.game_members
for select
to authenticated
using (public.is_game_member(game_id));

create policy memories_all_member
on public.memories
for all
to authenticated
using (public.is_game_member(game_id))
with check (public.is_game_member(game_id));

create policy photos_all_member
on public.memory_photos
for all
to authenticated
using (public.is_game_member(game_id))
with check (public.is_game_member(game_id));

create policy progress_select_own
on public.progress
for select
to authenticated
using (
  user_id = (select auth.uid())
  and public.is_game_member(game_id)
);

create policy progress_insert_own
on public.progress
for insert
to authenticated
with check (
  user_id = (select auth.uid())
  and public.is_game_member(game_id)
);

create policy progress_update_own
on public.progress
for update
to authenticated
using (
  user_id = (select auth.uid())
  and public.is_game_member(game_id)
)
with check (
  user_id = (select auth.uid())
  and public.is_game_member(game_id)
);

create policy progress_delete_own
on public.progress
for delete
to authenticated
using (
  user_id = (select auth.uid())
  and public.is_game_member(game_id)
);

grant usage on schema public to authenticated;
grant select, update on public.games to authenticated;
grant select on public.game_members to authenticated;
grant select, insert, update, delete on public.memories to authenticated;
grant select, insert, update, delete on public.memory_photos to authenticated;
grant select, insert, update, delete on public.progress to authenticated;

create or replace function public.create_game(
  p_title text,
  p_display_name text
)
returns table (
  game_id uuid,
  title text,
  invite_code text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_code text;
begin
  if (select auth.uid()) is null then
    raise exception 'Not signed in';
  end if;

  loop
    v_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));
    exit when not exists (
      select 1
      from public.games g
      where g.invite_code = v_code
    );
  end loop;

  insert into public.games (
    title,
    invite_code,
    created_by
  )
  values (
    coalesce(nullif(trim(p_title), ''), '我们的见面存档'),
    v_code,
    (select auth.uid())
  )
  returning id into v_id;

  insert into public.game_members (
    game_id,
    user_id,
    display_name
  )
  values (
    v_id,
    (select auth.uid()),
    coalesce(nullif(trim(p_display_name), ''), '我')
  );

  return query
  select g.id, g.title, g.invite_code
  from public.games g
  where g.id = v_id;
end;
$$;

create or replace function public.join_game(
  p_invite_code text,
  p_display_name text
)
returns table (
  game_id uuid,
  title text,
  invite_code text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  if (select auth.uid()) is null then
    raise exception 'Not signed in';
  end if;

  select g.id
  into v_id
  from public.games g
  where upper(g.invite_code) = upper(trim(p_invite_code))
  limit 1;

  if v_id is null then
    raise exception '邀请码不存在';
  end if;

  insert into public.game_members (
    game_id,
    user_id,
    display_name
  )
  values (
    v_id,
    (select auth.uid()),
    coalesce(nullif(trim(p_display_name), ''), 'TA')
  )
  on conflict on constraint game_members_pkey
  do update
  set display_name = excluded.display_name;

  return query
  select g.id, g.title, g.invite_code
  from public.games g
  where g.id = v_id;
end;
$$;

revoke all on function public.create_game(text, text) from public, anon;
revoke all on function public.join_game(text, text) from public, anon;
grant execute on function public.create_game(text, text) to authenticated;
grant execute on function public.join_game(text, text) to authenticated;

-- Storage policies
-- Create a PRIVATE bucket named memory-photos before using photo uploads.

drop policy if exists memory_photos_storage_select on storage.objects;
drop policy if exists memory_photos_storage_insert on storage.objects;
drop policy if exists memory_photos_storage_update on storage.objects;
drop policy if exists memory_photos_storage_delete on storage.objects;

create policy memory_photos_storage_select
on storage.objects
for select
to authenticated
using (
  bucket_id = 'memory-photos'
  and public.is_game_member(((storage.foldername(name))[1])::uuid)
);

create policy memory_photos_storage_insert
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'memory-photos'
  and public.is_game_member(((storage.foldername(name))[1])::uuid)
);

create policy memory_photos_storage_update
on storage.objects
for update
to authenticated
using (
  bucket_id = 'memory-photos'
  and public.is_game_member(((storage.foldername(name))[1])::uuid)
)
with check (
  bucket_id = 'memory-photos'
  and public.is_game_member(((storage.foldername(name))[1])::uuid)
);

create policy memory_photos_storage_delete
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'memory-photos'
  and public.is_game_member(((storage.foldername(name))[1])::uuid)
);
