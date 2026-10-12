import { createClient } from '@supabase/supabase-js';
import type { Database } from './database.types';

const url = import.meta.env.VITE_SUPABASE_URL;
const key = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY;

// Only a publishable key belongs in the browser. Never use a service-role key here.
export const supabase = url && key?.startsWith('sb_publishable_')
  ? createClient<Database>(url, key)
  : null;

/** Read-only check: verifies the public Auth endpoint, without reading user data. */
export async function checkSupabaseConnection(): Promise<void> {
  if (!supabase) throw new Error('Falta configurar la URL o la clave publicable en .env.local.');
  const response = await fetch(`${url}/auth/v1/settings`, {
    headers: { apikey: key! },
    signal: AbortSignal.timeout(10000),
  });
  if (!response.ok) throw new Error(`Supabase respondió con HTTP ${response.status}.`);
  const settings = await response.json();
  if (!settings.external || typeof settings.disable_signup !== 'boolean') throw new Error('La API no devolvió la respuesta esperada.');
}
