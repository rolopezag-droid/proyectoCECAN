# Probar registro e inscripciones persistentes

El frontend ya lee actividades de Supabase y utiliza Supabase Auth para registrar cuentas, verificar correo, iniciar y cerrar sesión. Las inscripciones y resoluciones se guardan mediante RPC con comprobaciones en servidor. Esta demo no usa todavía FastAPI; esa capa prevista en D3 sigue pendiente.

## Preparación del correo

En Supabase, **Authentication → URL Configuration**, configurar como Site URL la dirección que se usa para abrir Vite (por ejemplo `http://localhost:5173`) y agregar esa misma dirección a Redirect URLs. Si también se utiliza `http://127.0.0.1:5173`, agregarla. Usar el puerto que imprime Vite; no cambiar estas opciones a un dominio ajeno. Esta configuración del panel no fue modificada desde el plugin.

El proyecto mantiene la confirmación de correo activada. Para probarla, usar un correo propio que se pueda verificar y una contraseña exclusiva de la demo. El proveedor de correo de Supabase puede restringir destinatarios o envíos; si aparece ese error, configurar SMTP o usar un destinatario autorizado por el proveedor. No se desactiva la verificación para eludirlo.

## Recorrido

1. Ejecutar `npm run dev` desde `frontend`.
2. Abrir Mi cuenta → Crea tu cuenta. Registrar nombre de prueba, correo y contraseña de al menos ocho caracteres con letras y números.
3. Confirmar el correo y volver al portal para iniciar sesión. El trigger crea un perfil privado y únicamente el rol básico `user`.
4. Abrir una actividad con inscripción abierta y seleccionar Solicitar inscripción. El mensaje confirma el guardado solo cuando Supabase devuelve éxito.
5. Abrir Mi cuenta, recargar y volver a Mi cuenta: la solicitud debe seguir en Pendiente. El acceso permanece mediante la sesión de Supabase.
6. Cancelar antes del inicio; recargar y verificar que permanezca Cancelada. No se elimina el historial ni se permite otra solicitud duplicada para esa sesión.

En Supabase se puede comprobar la cuenta en Authentication → Users y el registro en `profiles`, `user_roles`, `enrollments` y `enrollment_history` desde Table Editor. No se necesitan credenciales bibliotecarias para este recorrido.

## Panel del personal

Se requiere otra cuenta confirmada con rol `activity_manager` y asignación en `session_staff`. El rol se asigna desde SQL confiable por quien administra el proyecto; registrarse o indicar metadatos no concede permisos del personal. Cuando el equipo elija la cuenta responsable, se puede configurar con su UUID sin publicar su contraseña.

La cuenta responsable verá Vista del personal después de iniciar sesión o actualizar la página. Solo verá las solicitudes de sus sesiones asignadas. Puede confirmar o rechazar pendientes; rechazar solicita un motivo. No puede resolver su propia inscripción. El estado y responsable quedan registrados en la base. El participante verá el resultado al volver a la ventana, recargar o iniciar sesión nuevamente; no hay Realtime todavía.

No se entregó una cuenta administrativa predeterminada ni se asignaron privilegios permanentes a una persona sin identificarla.

## Verificación realizada

- TypeScript y compilación de producción satisfactorios.
- Agenda y formulario de acceso revisados en el navegador con lectura real de Supabase.
- Ocho pruebas transaccionales de RPC: guardado pendiente, duplicados, acceso anónimo denegado, revisión por personal asignado, cancelación propia y rechazo de acciones ajenas; historial conservado.
- Las cuentas temporales de las pruebas fueron revertidas. No se envió correo ni se probó el recorrido de confirmación con un buzón del equipo.
- Asesor de seguridad de Supabase sin hallazgos.

SQL aplicado: `demo_persistent_enrollment_api`, copia en `docs/database/demo-persistence-api.sql`. Pruebas reproducibles en `docs/database/demo-persistence-checks.sql`. Las claves privilegiadas permanecen fuera del frontend y no se concedió escritura directa a las tablas desde el navegador.
