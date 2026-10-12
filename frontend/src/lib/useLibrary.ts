import { useCallback, useEffect, useRef, useState } from 'react';
import type { Session } from '@supabase/supabase-js';
import { supabase } from './supabase';

export type Status = 'Pendiente' | 'Confirmada' | 'Rechazada' | 'Cancelada';
export type Activity = { id: string; title: string; category: string; day: string; month: string; date: string; time: string; place: string; color: string; description: string; seats: number; open: boolean };
export type Request = { id: string; userId: string; name: string; activity: string; status: Status };
const labels: Record<string, Status> = { pending: 'Pendiente', confirmed: 'Confirmada', rejected: 'Rechazada', cancelled: 'Cancelada' };
const categories: Record<string,string> = { reading_club:'Club de lectura', children_workshop:'Taller infantil', writing_workshop:'Taller de escritura', other:'Encuentro' };
const colors: Record<string,string> = { reading_club:'rose', children_workshop:'sage', writing_workshop:'sand', other:'sage' };
const dateOptions = { timeZone:'America/Mazatlan' };

export function useLibrary() {
  const [session,setSession] = useState<Session|null>(null);
  const [ready,setReady] = useState(false);
  const [activities,setActivities] = useState<Activity[]>([]);
  const [requests,setRequests] = useState<Request[]>([]);
  const [panelRequests,setPanelRequests] = useState<Request[]>([]);
  const [userName,setUserName] = useState('Usuario');
  const [canManage,setCanManage] = useState(false);
  const [loading,setLoading] = useState(true);
  const [error,setError] = useState('');
  const userId=session?.user.id;
  const revision=useRef(0);
  const identity=useRef<string|null>(null);

  useEffect(() => {
    if (!supabase) { setError('Configura Supabase en .env.local.'); setReady(true); return; }
    let active=true;
    const {data:{subscription}}=supabase.auth.onAuthStateChange((event,next)=>{
      if(active){
        const nextId=next?.user.id??null;
        if(identity.current!==nextId||event==='INITIAL_SESSION'||event==='TOKEN_REFRESHED')revision.current++;
        if(identity.current!==nextId){setRequests([]);setPanelRequests([]);setCanManage(false);}
        identity.current=nextId;setSession(next);setReady(true);
      }
    });
    return ()=>{active=false;subscription.unsubscribe();};
  },[]);

  const refresh=useCallback(async()=>{
    if(!supabase) {setLoading(false);return;}
    setLoading(true);setError('');
    const current=++revision.current;
    try {
      const [sessionsResult,activitiesResult,spacesResult]=await Promise.all([
        supabase.from('activity_sessions').select('*').order('starts_at'),
        supabase.from('activities').select('*'),supabase.from('spaces').select('*')
      ]);
      if(sessionsResult.error)throw sessionsResult.error;
      if(activitiesResult.error)throw activitiesResult.error;
      if(spacesResult.error)throw spacesResult.error;
      const mapped=(sessionsResult.data??[]).flatMap(s=>{
        const a=activitiesResult.data?.find(a=>a.id===s.activity_id);
        const space=spacesResult.data?.find(p=>p.id===s.space_id);
        if(!a)return [];
        const start=new Date(s.starts_at),end=new Date(s.ends_at);
        const formatTime=(d:Date)=>d.toLocaleTimeString('es-MX',{...dateOptions,hour:'2-digit',minute:'2-digit',hour12:false});
        return [{id:s.id,title:a.title,category:categories[a.category]??a.category,
          day:start.toLocaleDateString('es-MX',{...dateOptions,day:'2-digit'}),
          month:start.toLocaleDateString('es-MX',{...dateOptions,month:'short'}).replace('.','').toUpperCase(),
          date:start.toLocaleDateString('es-MX',{...dateOptions,day:'numeric',month:'long',year:'numeric'}),
          time:`${formatTime(start)} – ${formatTime(end)}`,place:space?.name??'Espacio no disponible',
          color:colors[a.category]??'sage',description:a.description,seats:s.capacity,
          open:s.registration_open&&s.status==='scheduled'&&start.getTime()>Date.now()}];
      });
      if(current!==revision.current)return;
      setActivities(mapped);
      if(!userId){setRequests([]);setPanelRequests([]);setCanManage(false);return;}
      const profile=await supabase.from('profiles').select('full_name,status').eq('id',userId).single();
      if(profile.error)throw profile.error;
      if(profile.data.status!=='active')throw new Error('Tu cuenta está deshabilitada. Contacta al personal.');
      const roles=await supabase.from('user_roles').select('role_code').eq('user_id',userId);
      if(roles.error)throw roles.error;
      const manager=roles.data.some(r=>r.role_code==='activity_manager');
      const own=await supabase.from('enrollments').select('*').eq('user_id',userId);
      if(own.error)throw own.error;
      const all:Request[]=own.data.map(r=>({id:r.id,userId:r.user_id,name:profile.data.full_name,activity:r.session_id,status:labels[r.status]}));
      let staffRows:Request[]=[];
      if(manager){
        const staff=await supabase.rpc('staff_requests');if(staff.error)throw staff.error;
        staffRows=staff.data.map(r=>({id:r.id,userId:r.user_id,name:r.full_name,activity:r.session_id,status:labels[r.status]}));
      }
      if(current!==revision.current)return;
      setUserName(profile.data.full_name);setCanManage(manager);setRequests(all);setPanelRequests(staffRows);
    }catch(err){if(current===revision.current){setRequests([]);setPanelRequests([]);setCanManage(false);setError(err instanceof Error?err.message:((err as {message?:string}).message??'No se pudieron cargar los datos.'));}}
    finally{if(current===revision.current)setLoading(false);}
  },[userId]);

  useEffect(()=>{if(ready)void refresh();},[ready,refresh,session?.access_token]);
  useEffect(()=>{const focus=()=>{if(ready)void refresh();};window.addEventListener('focus',focus);return()=>window.removeEventListener('focus',focus);},[ready,refresh]);
  return {activities,requests,panelRequests,userName,userId,canManage,loading,error,refresh,signedIn:!!session,ready};
}
