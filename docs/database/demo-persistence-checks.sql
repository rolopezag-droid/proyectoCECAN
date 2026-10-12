begin;
create temporary table persistence_checks(test text,passed boolean);
do $$
declare u uuid:=gen_random_uuid(); other_user uuid:=gen_random_uuid(); staff uuid:=gen_random_uuid(); sid uuid; eid uuid; n integer; denied boolean; result_status text;
begin
 insert into auth.users(id,aud,role,email,email_confirmed_at,raw_user_meta_data) values
 (u,'authenticated','authenticated','rpc-reader@example.invalid',now(),'{"full_name":"Usuario RPC"}'),
 (other_user,'authenticated','authenticated','rpc-other@example.invalid',now(),'{"full_name":"Otro usuario RPC"}'),
 (staff,'authenticated','authenticated','rpc-staff@example.invalid',now(),'{"full_name":"Personal RPC"}');
 select id into sid from public.activity_sessions where registration_open and starts_at>now() order by starts_at limit 1;
 if sid is null then raise exception 'No test session available'; end if;
 perform set_config('request.jwt.claims',json_build_object('sub',u,'role','authenticated')::text,true);
 set local role authenticated;
 select public.request_enrollment(sid) into eid;
 select status into result_status from public.enrollments where id=eid;
 reset role;
 insert into persistence_checks values('Authenticated RPC persists pending enrollment',result_status='pending');
 denied:=false;
 set local role authenticated;
 begin perform public.request_enrollment(sid); exception when unique_violation then denied:=true; end;
 reset role;insert into persistence_checks values('Duplicate RPC rejected',denied);
 denied:=false;
 set local role authenticated;
 begin perform public.review_enrollment(eid,'confirmed'); exception when insufficient_privilege then denied:=true; end;
 reset role;insert into persistence_checks values('Reader cannot confirm',denied);
 perform set_config('request.jwt.claims',json_build_object('sub',other_user,'role','authenticated')::text,true);
 denied:=false;
 set local role authenticated;
 begin perform public.cancel_enrollment(eid); exception when insufficient_privilege then denied:=true; end;
 reset role;insert into persistence_checks values('Other user cannot cancel',denied);
 insert into public.user_roles(user_id,role_code,assigned_by,assignment_reason) values(staff,'activity_manager',staff,'Prueba RPC');
 insert into public.session_staff(session_id,user_id,assigned_by) values(sid,staff,staff);
 perform set_config('request.jwt.claims',json_build_object('sub',staff,'role','authenticated')::text,true);
 set local role authenticated;
 select count(*) into n from public.staff_requests() where id=eid;
 perform public.review_enrollment(eid,'confirmed');
 reset role;insert into persistence_checks values('Assigned manager reads and confirms',n=1 and (select status='confirmed' from public.enrollments where id=eid));
 perform set_config('request.jwt.claims',json_build_object('sub',u,'role','authenticated')::text,true);
 set local role authenticated;
 perform public.cancel_enrollment(eid);
 reset role;insert into persistence_checks values('Owner cancels before start',(select status='cancelled' from public.enrollments where id=eid));
 insert into persistence_checks values('History persisted across operations',(select count(*)=3 from public.enrollment_history where enrollment_id=eid));
 denied:=false;
 set local role anon;
 begin perform public.request_enrollment(sid); exception when insufficient_privilege then denied:=true; end;
 reset role;insert into persistence_checks values('Anonymous cannot call mutation RPC',denied);
end $$;
select * from persistence_checks order by test;
rollback;
