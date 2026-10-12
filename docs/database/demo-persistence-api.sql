create function private.require_active_user() returns uuid language plpgsql stable security definer set search_path='' as $$
declare uid uuid:=auth.uid();
begin
 if uid is null or not exists(select 1 from public.profiles where id=uid and status='active') then
 raise exception 'Inicia sesión con una cuenta activa.' using errcode='42501'; end if;
 return uid;
end $$;

create function private.request_enrollment(target_session uuid) returns uuid language plpgsql security definer set search_path='' as $$
declare uid uuid:=private.require_active_user(); eid uuid;
begin
 perform 1 from public.activity_sessions where id=target_session for update;
 if exists(select 1 from public.enrollments where session_id=target_session and user_id=uid) then
 raise exception 'Ya tienes una solicitud para esta sesión. Consulta Mi cuenta.' using errcode='23505'; end if;
 insert into public.enrollments(session_id,user_id) values(target_session,uid) returning id into eid;
 return eid;
end $$;
create function private.cancel_enrollment(target_enrollment uuid) returns void language plpgsql security definer set search_path='' as $$
declare uid uuid:=private.require_active_user(); sid uuid; e public.enrollments%rowtype;
begin
 select session_id into sid from public.enrollments where id=target_enrollment and user_id=uid;
 if sid is null then raise exception 'Solicitud no disponible.' using errcode='42501'; end if;
 perform 1 from public.activity_sessions where id=sid for update;
 select * into e from public.enrollments where id=target_enrollment and user_id=uid for update;
 if e.status not in ('pending','confirmed') then raise exception 'La solicitud ya está resuelta o cancelada.'; end if;
 if exists(select 1 from public.activity_sessions where id=sid and starts_at<=now()) then
 raise exception 'La actividad ya comenzó. Contacta al personal para cancelar.'; end if;
 update public.enrollments set status='cancelled',decision_by=uid,decided_at=now(),decision_reason='Cancelación solicitada por el titular' where id=e.id;
end $$;
create function private.review_enrollment(target_enrollment uuid,new_status text,reason text default null) returns void language plpgsql security definer set search_path='' as $$
declare uid uuid:=private.require_active_user(); sid uuid; e public.enrollments%rowtype;
begin
 select session_id into sid from public.enrollments where id=target_enrollment;
 if sid is null or not private.manages_session(sid) then raise exception 'No tienes permiso sobre esta sesión.' using errcode='42501'; end if;
 if new_status not in ('confirmed','rejected') then raise exception 'Resolución no válida.'; end if;
 if new_status='rejected' and length(trim(coalesce(reason,'')))=0 then raise exception 'Indica el motivo del rechazo.'; end if;
 perform 1 from public.activity_sessions where id=sid for update;
 select * into e from public.enrollments where id=target_enrollment for update;
 if e.user_id=uid then raise exception 'No puedes resolver tu propia inscripción.' using errcode='42501'; end if;
 if e.status<>'pending' then raise exception 'La solicitud ya fue resuelta. Actualiza la lista.'; end if;
 update public.enrollments set status=new_status,decision_by=uid,decided_at=now(),decision_reason=nullif(trim(reason),'') where id=e.id;
end $$;
create function private.staff_requests() returns table(id uuid,user_id uuid,session_id uuid,full_name text,status text,created_at timestamptz)
language plpgsql stable security definer set search_path='' as $$
begin
 perform private.require_active_user();
 return query select e.id,e.user_id,e.session_id,p.full_name,e.status,e.created_at
 from public.enrollments e join public.profiles p on p.id=e.user_id
 where private.manages_session(e.session_id) order by e.created_at desc;
end $$;
-- Public API wrappers keep privileged implementations out of the exposed schema.
create function public.request_enrollment(target_session uuid) returns uuid
language sql security invoker set search_path='' as $$ select private.request_enrollment(target_session) $$;
create function public.cancel_enrollment(target_enrollment uuid) returns void
language sql security invoker set search_path='' as $$ select private.cancel_enrollment(target_enrollment) $$;
create function public.review_enrollment(target_enrollment uuid,new_status text,reason text default null) returns void
language sql security invoker set search_path='' as $$ select private.review_enrollment(target_enrollment,new_status,reason) $$;
create function public.staff_requests() returns table(id uuid,user_id uuid,session_id uuid,full_name text,status text,created_at timestamptz)
language sql stable security invoker set search_path='' as $$ select * from private.staff_requests() $$;
revoke all on function private.require_active_user(),private.request_enrollment(uuid),private.cancel_enrollment(uuid),private.review_enrollment(uuid,text,text),private.staff_requests() from public,anon,authenticated;
revoke all on function public.request_enrollment(uuid),public.cancel_enrollment(uuid),public.review_enrollment(uuid,text,text),public.staff_requests() from public,anon,authenticated;
grant execute on function private.request_enrollment(uuid),private.cancel_enrollment(uuid),private.review_enrollment(uuid,text,text),private.staff_requests() to authenticated;
grant execute on function public.request_enrollment(uuid),public.cancel_enrollment(uuid),public.review_enrollment(uuid,text,text),public.staff_requests() to authenticated;
