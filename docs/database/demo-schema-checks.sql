begin;
create temporary table demo_check_results(test text,passed boolean);
do $$
declare u1 uuid:=gen_random_uuid(); u2 uuid:=gen_random_uuid(); staff uuid:=gen_random_uuid();
sp uuid; a uuid; s uuid; e1 uuid; e2 uuid; n integer; blocked boolean;
begin
 -- Disposable Auth fixtures: no passwords, no emails sent; transaction is rolled back.
 insert into auth.users(id,aud,role,email,email_confirmed_at,raw_user_meta_data)
 values(u1,'authenticated','authenticated','schema-reader-1@example.invalid',now(),'{"full_name":"Prueba 1","role":"administrator"}'),
 (u2,'authenticated','authenticated','schema-reader-2@example.invalid',now(),'{"full_name":"Prueba 2"}'),
 (staff,'authenticated','authenticated','schema-staff@example.invalid',now(),'{"full_name":"Personal de prueba"}');
 insert into demo_check_results values('Auth creates profile and only basic role',
 (select count(*)=1 from public.user_roles where user_id=u1) and
 (select role_code='user' from public.user_roles where user_id=u1));
 insert into public.user_roles(user_id,role_code,assigned_by,assignment_reason)
 values(staff,'activity_manager',staff,'Prueba transaccional');
 insert into public.spaces(slug,name,capacity) values('transaction-test-room','Espacio de prueba temporal',2) returning id into sp;
 insert into public.activities(slug,title,description,category,publication_status,authorization_reference,publication_reference)
 values('transaction-test-event','Actividad temporal','Se revierte al terminar','other','published','TEST','TEST') returning id into a;
 insert into public.activity_sessions(activity_id,space_id,starts_at,ends_at,capacity,status,registration_open,authorization_reference)
 values(a,sp,now()+interval '2 days',now()+interval '2 days 1 hour',1,'scheduled',true,'TEST') returning id into s;
 insert into public.session_staff(session_id,user_id,assigned_by) values(s,staff,staff);
 insert into public.enrollments(session_id,user_id) values(s,u1) returning id into e1;
 insert into public.enrollments(session_id,user_id) values(s,u2) returning id into e2;
 insert into demo_check_results values('Enrollment without credential stays pending',
 (select status='pending' from public.enrollments where id=e1) and not exists(select 1 from public.library_credentials where user_id=u1));
 blocked:=false;
 begin insert into public.enrollments(session_id,user_id) values(s,u1);
 exception when unique_violation then blocked:=true; end;
 insert into demo_check_results values('Duplicate enrollment rejected',blocked);
 blocked:=false;
 begin insert into public.enrollments(session_id,user_id,status,decision_by,decided_at)
 values(s,staff,'confirmed',staff,now());
 exception when check_violation then blocked:=true; end;
 insert into demo_check_results values('Automatic confirmation on insert rejected',blocked);
 update public.enrollments set status='confirmed',decision_by=staff,decided_at=now() where id=e1;
 blocked:=false;
 begin update public.enrollments set status='confirmed',decision_by=staff,decided_at=now() where id=e2;
 exception when check_violation then blocked:=true; end;
 insert into demo_check_results values('Last available seat cannot be assigned twice',blocked);
 insert into demo_check_results values('Confirmation does not create attendance',not exists(select 1 from public.attendances where session_id=s));
 blocked:=false;
 begin insert into public.activity_sessions(activity_id,space_id,starts_at,ends_at,capacity,status,authorization_reference)
 values(a,sp,now()+interval '2 days 30 minutes',now()+interval '2 days 2 hours',1,'scheduled','TEST');
 exception when check_violation then blocked:=true; end;
 insert into demo_check_results values('Overlapping room allocation rejected',blocked);
 blocked:=false;
 begin insert into public.library_credentials(user_id,credential_number,issued_on,expires_on)
 values(u1,'TEST-1',current_date,current_date+1);
 exception when check_violation then blocked:=true; end;
 insert into demo_check_results values('Credential must have two-year validity',blocked);
 insert into public.attendances(session_id,user_id,status,recorded_by) values(s,u1,'present',staff);
 blocked:=false;
 begin insert into public.attendances(session_id,user_id,status,recorded_by) values(s,u1,'present',staff);
 exception when unique_violation then blocked:=true; end;
 insert into demo_check_results values('Duplicate attendance rejected',blocked);
 blocked:=false;
 begin update public.attendances set status='absent' where session_id=s and user_id=u1;
 exception when check_violation then blocked:=true; end;
 insert into demo_check_results values('Attendance correction requires reason',blocked);

 perform set_config('request.jwt.claims',json_build_object('sub',u1,'role','authenticated')::text,true);
 set local role authenticated;
 select count(*) into n from public.enrollments where session_id=s;
 reset role;
 insert into demo_check_results values('Reader sees only own enrollment',n=1);
 set local role authenticated;
 select count(*) into n from public.profiles where id in(u1,u2,staff);
 reset role;
 insert into demo_check_results values('Reader cannot read other profiles',n=1);
 blocked:=false;
 set local role authenticated;
 begin update public.enrollments set status='confirmed' where id=e2;
 exception when insufficient_privilege then blocked:=true; end;
 reset role;
 insert into demo_check_results values('Browser user cannot confirm or mutate enrollment',blocked);
 perform set_config('request.jwt.claims',json_build_object('sub',staff,'role','authenticated')::text,true);
 set local role authenticated;
 select count(*) into n from public.enrollments where session_id=s;
 reset role;
 insert into demo_check_results values('Assigned activity manager reads session enrollments',n=2);
 delete from public.session_staff where session_id=s and user_id=staff;
 set local role authenticated;
 select count(*) into n from public.enrollments where session_id=s;
 reset role;
 insert into demo_check_results values('Unassigned manager cannot read session enrollments',n=0);
 set local role anon;
 select count(*) into n from public.activities where id=a;
 reset role;
 insert into demo_check_results values('Visitor can read published activity',n=1);
 update public.activities set publication_status='draft' where id=a;
 set local role anon;
 select count(*) into n from public.activities where id=a;
 reset role;
 insert into demo_check_results values('Visitor cannot read draft activity',n=0);
 update public.enrollments set status='cancelled',decision_reason='Cancelación de prueba',decision_by=u1 where id=e1;
 insert into demo_check_results values('Enrollment history preserves pending, confirmed and cancelled',
 (select count(*)=3 from public.enrollment_history where enrollment_id=e1));
end $$;
select * from demo_check_results order by test;
rollback;
