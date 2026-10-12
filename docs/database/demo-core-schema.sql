create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create table public.profiles (
 id uuid primary key references auth.users(id) on delete restrict,
 full_name text not null check (length(trim(full_name)) between 1 and 120),
 status text not null default 'active' check (status in ('active','disabled')),
 registration_source text not null default 'self' check (registration_source in ('self','assisted')),
 created_by uuid references auth.users(id),
 is_demo boolean not null default true,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table public.roles (
 code text primary key check (code in ('user','editor','activity_manager','administrator')),
 name text not null,
 description text not null
);
create table public.user_roles (
 user_id uuid not null references public.profiles(id) on delete restrict,
 role_code text not null references public.roles(code),
 assigned_by uuid references auth.users(id),
 assignment_reason text not null check (length(trim(assignment_reason)) > 0),
 assigned_at timestamptz not null default now(),
 primary key (user_id,role_code)
);
create table public.spaces (
 id uuid primary key default gen_random_uuid(),
 slug text not null unique,
 name text not null check (length(trim(name)) between 1 and 120),
 capacity integer not null check (capacity > 0),
 description text not null default '',
 active boolean not null default true,
 is_demo boolean not null default true
);
create table public.activities (
 id uuid primary key default gen_random_uuid(),
 slug text not null unique,
 title text not null check (length(trim(title)) between 1 and 180),
 description text not null,
 category text not null check (category in ('reading_club','children_workshop','writing_workshop','other')),
 audience text not null default 'Comunidad',
 requirements text not null default '',
 publication_status text not null default 'draft' check (publication_status in ('draft','approved','published','withdrawn')),
 authorization_reference text,
 publication_reference text,
 created_by uuid references auth.users(id),
 is_demo boolean not null default true,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 check (publication_status = 'draft' or length(trim(coalesce(authorization_reference,''))) > 0),
 check (publication_status <> 'published' or length(trim(coalesce(publication_reference,''))) > 0)
);
create table public.activity_sessions (
 id uuid primary key default gen_random_uuid(),
 activity_id uuid not null references public.activities(id),
 space_id uuid not null references public.spaces(id),
 starts_at timestamptz not null,
 ends_at timestamptz not null,
 capacity integer not null check (capacity > 0),
 status text not null default 'draft' check (status in ('draft','scheduled','cancelled','completed')),
 registration_open boolean not null default false,
 authorization_reference text,
 is_demo boolean not null default true,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 check (ends_at > starts_at),
 check (not registration_open or status = 'scheduled'),
 check (status not in ('scheduled','completed') or length(trim(coalesce(authorization_reference,''))) > 0),
 unique (activity_id,starts_at)
);
create table public.session_staff (
 session_id uuid not null references public.activity_sessions(id),
 user_id uuid not null references public.profiles(id),
 assigned_by uuid references auth.users(id),
 assigned_at timestamptz not null default now(),
 primary key(session_id,user_id)
);
create table public.enrollments (
 id uuid primary key default gen_random_uuid(),
 session_id uuid not null references public.activity_sessions(id),
 user_id uuid not null references public.profiles(id),
 status text not null default 'pending' check (status in ('pending','confirmed','rejected','cancelled')),
 decision_by uuid references auth.users(id),
 decision_reason text,
 decided_at timestamptz,
 is_demo boolean not null default true,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(session_id,user_id),
 check (status not in ('confirmed','rejected') or (decision_by is not null and decided_at is not null)),
 check (status <> 'rejected' or length(trim(coalesce(decision_reason,''))) > 0)
);
create table public.enrollment_history (
 id uuid primary key default gen_random_uuid(),
 enrollment_id uuid not null references public.enrollments(id),
 previous_status text,
 new_status text not null,
 changed_by uuid references auth.users(id),
 reason text,
 changed_at timestamptz not null default now()
);
create table public.attendances (
 id uuid primary key default gen_random_uuid(),
 session_id uuid not null references public.activity_sessions(id),
 user_id uuid not null references public.profiles(id),
 status text not null check (status in ('present','absent')),
 recorded_by uuid not null references auth.users(id),
 recorded_at timestamptz not null default now(),
 correction_reason text,
 is_demo boolean not null default true,
 unique(session_id,user_id)
);
create table public.library_credentials (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id),
 credential_number text not null check (length(trim(credential_number)) between 1 and 60),
 issued_on date not null,
 expires_on date not null,
 validation_status text not null default 'pending' check (validation_status in ('pending','validated','rejected')),
 verified_by uuid references auth.users(id),
 verified_at timestamptz,
 verification_reference text,
 is_demo boolean not null default true,
 created_at timestamptz not null default now(),
 unique(credential_number,issued_on),
 unique(user_id,issued_on),
 check (expires_on = (issued_on + interval '2 years')::date),
 check (validation_status <> 'validated' or (verified_by is not null and verified_at is not null and length(trim(coalesce(verification_reference,''))) > 0))
);

create index profiles_created_by_idx on public.profiles(created_by);
create index user_roles_role_idx on public.user_roles(role_code);
create index user_roles_assigned_by_idx on public.user_roles(assigned_by);
create index activities_created_by_idx on public.activities(created_by);
create index activities_published_idx on public.activities(publication_status);
create index sessions_space_time_idx on public.activity_sessions(space_id,starts_at);
create index session_staff_user_idx on public.session_staff(user_id);
create index session_staff_assigned_by_idx on public.session_staff(assigned_by);
create index enrollments_user_idx on public.enrollments(user_id);
create index enrollments_decision_by_idx on public.enrollments(decision_by);
create index enrollments_capacity_idx on public.enrollments(session_id,status);
create index enrollment_history_enrollment_idx on public.enrollment_history(enrollment_id,changed_at);
create index enrollment_history_changed_by_idx on public.enrollment_history(changed_by);
create index attendances_user_idx on public.attendances(user_id);
create index attendances_recorded_by_idx on public.attendances(recorded_by);
create index credentials_verified_by_idx on public.library_credentials(verified_by);

-- Definer helpers are in a non-exposed schema. They only evaluate the current caller.
create function private.has_role(required_role text) returns boolean
language sql stable security definer set search_path = '' as $$
 select auth.uid() is not null and exists (
 select 1 from public.user_roles r join public.profiles p on p.id=r.user_id
 where r.user_id=(select auth.uid()) and r.role_code=required_role and p.status='active')
$$;
create function private.manages_session(target_session uuid) returns boolean
language sql stable security definer set search_path = '' as $$
 select auth.uid() is not null and private.has_role('activity_manager') and exists (
 select 1 from public.session_staff s where s.session_id=target_session and s.user_id=(select auth.uid()))
$$;

-- Trigger exclusively creates a basic profile, never staff privileges from metadata.
create function private.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id,full_name)
 values(new.id,coalesce(nullif(left(trim(new.raw_user_meta_data->>'full_name'),120),''),'Usuario de prueba'));
 insert into public.user_roles(user_id,role_code,assignment_reason)
 values(new.id,'user','Cuenta básica creada por Supabase Auth');
 return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
for each row execute function private.handle_new_user();

create function private.touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at=now(); return new; end $$;

-- Lock a space before checking schedule conflicts. Writes are for the trusted backend only.
create function private.check_session() returns trigger
language plpgsql set search_path = '' as $$
declare max_capacity integer; confirmed integer;
begin
 if TG_OP='UPDATE' and (new.space_id <> old.space_id) then
   perform 1 from public.spaces where id in (new.space_id,old.space_id) order by id for update;
 end if;
 select capacity into max_capacity from public.spaces where id=new.space_id for update;
 if new.capacity>max_capacity then raise exception 'Session capacity exceeds space capacity' using errcode='23514'; end if;
 if new.status in ('scheduled','completed') and exists (
 select 1 from public.activity_sessions s where s.id<>new.id and s.space_id=new.space_id
 and s.status in ('scheduled','completed') and s.starts_at<new.ends_at and s.ends_at>new.starts_at)
 then raise exception 'Space already assigned for this time' using errcode='23514'; end if;
 select count(*) into confirmed from public.enrollments where session_id=new.id and status='confirmed';
 if new.capacity<confirmed then raise exception 'Capacity below confirmed enrollments' using errcode='23514'; end if;
 return new;
end $$;
create trigger check_session before insert or update on public.activity_sessions
for each row execute function private.check_session();

create function private.check_enrollment() returns trigger
language plpgsql set search_path = '' as $$
declare s public.activity_sessions%rowtype; used integer;
begin
 if TG_OP='UPDATE' and (new.session_id<>old.session_id or new.user_id<>old.user_id) then
 raise exception 'Enrollment identity cannot change' using errcode='23514'; end if;
 select * into s from public.activity_sessions where id=new.session_id for update;
 if not found then raise exception 'Session missing' using errcode='23503'; end if;
 if TG_OP='INSERT' then
   if new.status<>'pending' then raise exception 'New enrollment must be pending' using errcode='23514'; end if;
   if not s.registration_open or s.status<>'scheduled' or s.starts_at<=now() then
   raise exception 'Registration is closed' using errcode='23514'; end if;
   if not exists(select 1 from public.activities where id=s.activity_id and publication_status='published') then
   raise exception 'Activity is not published' using errcode='23514'; end if;
 end if;
 if not exists(select 1 from public.profiles where id=new.user_id and status='active') then
 raise exception 'Account disabled' using errcode='23514'; end if;
 if TG_OP='UPDATE' and new.status<>old.status then
   if old.status not in ('pending','confirmed') or
     (old.status='confirmed' and new.status not in ('cancelled','rejected')) or new.status='pending' then
   raise exception 'Invalid enrollment transition' using errcode='23514'; end if;
 end if;
 if new.status='confirmed' and (TG_OP='INSERT' or old.status<>'confirmed') then
   if s.status<>'scheduled' or not s.registration_open or s.starts_at<=now() then
   raise exception 'Confirmation is closed' using errcode='23514'; end if;
   select count(*) into used from public.enrollments where session_id=new.session_id and status='confirmed' and id<>new.id;
   if used>=s.capacity then raise exception 'No places available' using errcode='23514'; end if;
 end if;
 new.updated_at=now();
 return new;
end $$;
create trigger check_enrollment before insert or update on public.enrollments
for each row execute function private.check_enrollment();

create function private.record_enrollment_history() returns trigger
language plpgsql set search_path = '' as $$
begin
 if TG_OP='INSERT' then
 insert into public.enrollment_history(enrollment_id,new_status,changed_by)
 values(new.id,new.status,coalesce(auth.uid(),new.user_id));
 elsif new.status<>old.status then
 insert into public.enrollment_history(enrollment_id,previous_status,new_status,changed_by,reason)
 values(new.id,old.status,new.status,coalesce(auth.uid(),new.decision_by),new.decision_reason);
 end if;
 return new;
end $$;
create trigger enrollment_history after insert or update on public.enrollments
for each row execute function private.record_enrollment_history();
create function private.check_attendance_correction() returns trigger
language plpgsql set search_path = '' as $$
begin
 if new.user_id<>old.user_id or new.session_id<>old.session_id then
 raise exception 'Attendance identity cannot change' using errcode='23514'; end if;
 if new.status<>old.status and (length(trim(coalesce(new.correction_reason,'')))=0 or new.recorded_by is null) then
 raise exception 'Correction requires responsible person and reason' using errcode='23514'; end if;
 return new;
end $$;
create trigger attendance_correction before update on public.attendances
for each row execute function private.check_attendance_correction();
create trigger profiles_updated before update on public.profiles for each row execute function private.touch_updated_at();
create trigger activities_updated before update on public.activities for each row execute function private.touch_updated_at();
create trigger sessions_updated before update on public.activity_sessions for each row execute function private.touch_updated_at();

-- Authenticated clients currently READ only. All mutations stay with trusted SQL/backend.
revoke all on all tables in schema public from anon,authenticated;
grant select on public.roles,public.spaces,public.activities,public.activity_sessions to anon,authenticated;
grant select on public.profiles,public.user_roles,public.session_staff,public.enrollments,public.enrollment_history,public.attendances,public.library_credentials to authenticated;
grant all on public.profiles,public.roles,public.user_roles,public.spaces,public.activities,public.activity_sessions,public.session_staff,public.enrollments,public.enrollment_history,public.attendances,public.library_credentials to service_role;
alter table public.profiles enable row level security;
alter table public.roles enable row level security;
alter table public.user_roles enable row level security;
alter table public.spaces enable row level security;
alter table public.activities enable row level security;
alter table public.activity_sessions enable row level security;
alter table public.session_staff enable row level security;
alter table public.enrollments enable row level security;
alter table public.enrollment_history enable row level security;
alter table public.attendances enable row level security;
alter table public.library_credentials enable row level security;

create policy profiles_read on public.profiles for select to authenticated
using(id=(select auth.uid()) or (select private.has_role('administrator')));
create policy roles_read on public.roles for select to anon,authenticated using(true);
create policy user_roles_read on public.user_roles for select to authenticated
using(user_id=(select auth.uid()) or (select private.has_role('administrator')));
create policy spaces_read on public.spaces for select to anon,authenticated using(active);
create policy activities_read on public.activities for select to anon,authenticated using(publication_status='published');
create policy sessions_read on public.activity_sessions for select to anon,authenticated
using(status<>'draft' and exists(select 1 from public.activities a where a.id=activity_id and a.publication_status='published'));
create policy staff_read on public.session_staff for select to authenticated
using(user_id=(select auth.uid()) or (select private.has_role('administrator')));
create policy enrollments_read on public.enrollments for select to authenticated
using(user_id=(select auth.uid()) or private.manages_session(session_id));
create policy enrollment_history_read on public.enrollment_history for select to authenticated
using(exists(select 1 from public.enrollments e where e.id=enrollment_id));
create policy attendance_read on public.attendances for select to authenticated
using(user_id=(select auth.uid()) or private.manages_session(session_id));
create policy credentials_read on public.library_credentials for select to authenticated
using(user_id=(select auth.uid()));
revoke all on all functions in schema private from public,anon,authenticated;
grant execute on function private.has_role(text),private.manages_session(uuid) to authenticated;

insert into public.roles(code,name,description) values
('user','Usuario / Cliente','Cuenta básica; gestiona lo propio, sin credencial obligatoria para inscripción.'),
('editor','Editor','Contenido editorial; no concede gestión de agenda.'),
('activity_manager','Responsable de actividades','Operación de actividades asignadas; no concede administración de cuentas.'),
('administrator','Administrador','Cuentas y roles; no concede automáticamente autoridad de actividades.');
