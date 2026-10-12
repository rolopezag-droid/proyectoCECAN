import { useState } from 'react';
import { checkSupabaseConnection } from '../lib/supabase';

export default function SupabaseConnection() {
  const [state, setState] = useState<'idle' | 'checking' | 'connected' | 'error'>('idle');
  const [message, setMessage] = useState('');

  async function check() {
    setState('checking');
    setMessage('');
    try {
      await checkSupabaseConnection();
      setState('connected');
      setMessage('Conexión verificada con proyectoCECAN. Las pantallas siguen usando datos simulados.');
    } catch (error) {
      setState('error');
      setMessage(error instanceof Error ? error.message : 'No se pudo comprobar la conexión.');
    }
  }

  return <section className="connection-check" aria-label="Conexión de Supabase">
    <div><strong>Supabase · proyectoCECAN</strong><p>Cliente configurado. Comprueba el acceso a la API sin modificar datos.</p></div>
    <button className="secondary" disabled={state === 'checking'} onClick={check}>{state === 'checking' ? 'Comprobando…' : state === 'connected' ? 'Volver a comprobar' : 'Comprobar conexión'}</button>
    {message && <p role="status" className={state === 'error' ? 'connection-error' : 'connection-success'}>{message}</p>}
  </section>;
}
