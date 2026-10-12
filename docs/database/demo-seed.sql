insert into public.spaces(slug,name,capacity,description,is_demo) values
('demo-reading-room','Sala de lectura (demo)',20,'Espacio ficticio para pruebas; aforo no validado por la biblioteca.',true),
('demo-children-room','Sala infantil (demo)',15,'Espacio ficticio para pruebas.',true),
('demo-multipurpose-room','Sala de usos múltiples (demo)',12,'Espacio ficticio para pruebas.',true)
on conflict(slug) do nothing;
insert into public.activities(slug,title,description,category,publication_status,authorization_reference,publication_reference,is_demo)
values
('demo-coffee-reading','Entre páginas y café','Actividad ficticia de club de lectura para la demostración.','reading_club','published','DEMO: autorización ficticia para pruebas','DEMO: publicación ficticia para pruebas',true),
('demo-living-stories','Historias que cobran vida','Actividad ficticia de cuentos para la demostración.','children_workshop','published','DEMO: autorización ficticia para pruebas','DEMO: publicación ficticia para pruebas',true),
('demo-writing','Escribir para encontrarnos','Actividad ficticia de escritura para la demostración.','writing_workshop','published','DEMO: autorización ficticia para pruebas','DEMO: publicación ficticia para pruebas',true)
on conflict(slug) do nothing;
insert into public.activity_sessions(activity_id,space_id,starts_at,ends_at,capacity,status,registration_open,authorization_reference,is_demo)
select a.id,s.id,v.starts::timestamp at time zone 'America/Mazatlan',v.ends::timestamp at time zone 'America/Mazatlan',v.capacity,'scheduled',true,'DEMO: programación ficticia para pruebas',true
from (values
('demo-coffee-reading','demo-reading-room','2026-10-22 17:00','2026-10-22 18:30',20),
('demo-living-stories','demo-children-room','2026-10-24 16:00','2026-10-24 17:00',15),
('demo-writing','demo-multipurpose-room','2026-10-29 17:00','2026-10-29 19:00',12)
) as v(activity_slug,space_slug,starts,ends,capacity)
join public.activities a on a.slug=v.activity_slug join public.spaces s on s.slug=v.space_slug
on conflict(activity_id,starts_at) do nothing;
