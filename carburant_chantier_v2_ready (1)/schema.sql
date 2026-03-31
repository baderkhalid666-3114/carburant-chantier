
-- Extensions
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text not null check (role in ('admin','magasinier','pointeur')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.engins (
  id uuid primary key default gen_random_uuid(),
  nom text not null unique,
  categorie text,
  affectation_defaut text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.saisies_carburant (
  id uuid primary key default gen_random_uuid(),
  date_saisie date not null,
  type_mouvement text not null check (type_mouvement in ('E','S')),
  engin_id uuid references public.engins(id) on delete set null,
  quantite_l numeric(12,2) not null check (quantite_l > 0),
  affectation text,
  commentaire text,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint sortie_avec_engin check (
    (type_mouvement = 'E') or (type_mouvement = 'S' and engin_id is not null)
  )
);

create table if not exists public.pointages_engins (
  id uuid primary key default gen_random_uuid(),
  date_pointage date not null,
  engin_id uuid not null references public.engins(id) on delete restrict,
  jours_travailles numeric(5,2) not null check (jours_travailles >= 0 and jours_travailles <= 31),
  commentaire text,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_pointage_jour unique (date_pointage, engin_id)
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_engins_updated_at on public.engins;
create trigger trg_engins_updated_at
before update on public.engins
for each row execute function public.set_updated_at();

drop trigger if exists trg_saisies_updated_at on public.saisies_carburant;
create trigger trg_saisies_updated_at
before update on public.saisies_carburant
for each row execute function public.set_updated_at();

drop trigger if exists trg_pointages_updated_at on public.pointages_engins;
create trigger trg_pointages_updated_at
before update on public.pointages_engins
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.engins enable row level security;
alter table public.saisies_carburant enable row level security;
alter table public.pointages_engins enable row level security;

create or replace function public.current_role()
returns text
language sql
stable
as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select coalesce((select role = 'admin' from public.profiles where id = auth.uid()), false)
$$;

-- profiles
drop policy if exists "profiles_select_own_or_admin" on public.profiles;
create policy "profiles_select_own_or_admin"
on public.profiles for select
using (id = auth.uid() or public.is_admin());

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self"
on public.profiles for insert
with check (
  id = auth.uid()
  and role in ('magasinier','pointeur')
);

drop policy if exists "profiles_update_own_or_admin" on public.profiles;
create policy "profiles_update_own_or_admin"
on public.profiles for update
using (id = auth.uid() or public.is_admin())
with check (
  public.is_admin()
  or (id = auth.uid() and role in ('magasinier','pointeur'))
);

-- engins
drop policy if exists "engins_read_all_authenticated" on public.engins;
create policy "engins_read_all_authenticated"
on public.engins for select
using (auth.uid() is not null);

drop policy if exists "engins_admin_write" on public.engins;
create policy "engins_admin_write"
on public.engins for all
using (public.is_admin())
with check (public.is_admin());

-- saisies
drop policy if exists "saisies_read_all_authenticated" on public.saisies_carburant;
create policy "saisies_read_all_authenticated"
on public.saisies_carburant for select
using (auth.uid() is not null);

drop policy if exists "saisies_insert_mag_or_admin" on public.saisies_carburant;
create policy "saisies_insert_mag_or_admin"
on public.saisies_carburant for insert
with check (
  auth.uid() = created_by
  and public.current_role() in ('admin','magasinier')
);

drop policy if exists "saisies_update_admin_only" on public.saisies_carburant;
create policy "saisies_update_admin_only"
on public.saisies_carburant for update
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "saisies_delete_admin_only" on public.saisies_carburant;
create policy "saisies_delete_admin_only"
on public.saisies_carburant for delete
using (public.is_admin());

-- pointages
drop policy if exists "pointages_read_all_authenticated" on public.pointages_engins;
create policy "pointages_read_all_authenticated"
on public.pointages_engins for select
using (auth.uid() is not null);

drop policy if exists "pointages_insert_pt_or_admin" on public.pointages_engins;
create policy "pointages_insert_pt_or_admin"
on public.pointages_engins for insert
with check (
  auth.uid() = created_by
  and public.current_role() in ('admin','pointeur')
);

drop policy if exists "pointages_delete_pt_or_admin" on public.pointages_engins;
create policy "pointages_delete_pt_or_admin"
on public.pointages_engins for delete
using (public.current_role() in ('admin','pointeur'));

drop policy if exists "pointages_update_admin_only" on public.pointages_engins;
create policy "pointages_update_admin_only"
on public.pointages_engins for update
using (public.is_admin())
with check (public.is_admin());

-- Admin bootstrap:
-- after creating your first account, run this once in SQL editor:
-- update public.profiles set role = 'admin' where id = 'USER_UUID_HERE';
