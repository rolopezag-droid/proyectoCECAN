# Base de datos de prueba · proyectoCECAN

Esquema aplicado al proyecto `rampjtejiwhbmqahldkz`. Es una base acotada para la demo, no el modelo completo del portal.

## Fuentes y decisiones

Se contrastaron `Requerimientos de software (SRS).docx.md` y `Actividad 3.1b Casos de uso e historias de usuario.md`, ubicados en `C:/Semestre 9/documentacion`, con la documentación general revisada en el chat. Se utiliza la definición coincidente del SRS y 3.1b: inscripción sin credencial, confirmación manual, sin espera automática, credenciales con vigencia de dos años y perfiles privados. El documento inicial y el plan de calidad contienen reglas diferentes; no se consideran autorizaciones institucionales. La estructura de columnas es una propuesta técnica para pruebas.

## Tablas y trazabilidad

| Tabla | Función | Referencia |
| --- | --- | --- |
| profiles | Perfil privado con identidad única de Auth, estado y origen del registro | RF-03, RF-06, RF-08; CU-05, 08, 09 |
| roles | Catálogo de usuario, editor, responsable y administrador | RF-07; CU-10 |
| user_roles | Varios roles para una misma cuenta, con motivo de asignación | RF-07; CU-10 |
| spaces | Espacios y aforo de ejemplo | RF-12, RF-13; CU-16 |
| activities | Ficha, requisitos, categoría y publicación separada de autorización | RF-13, RF-18; CU-02, 12, 15 |
| activity_sessions | Fechas, horario, espacio, cupo y apertura por sesión | RF-13, RF-14; CU-15, 19 |
| session_staff | Personal asignado a cada sesión | RF-07, RF-17; CU-19, 20 |
| enrollments | Una inscripción por persona y sesión, pendiente o resuelta | RF-14–16; CU-18, 19 |
| enrollment_history | Historial automático de estados | RF-16; CU-17, 18 |
| attendances | Asistencia distinta de inscripción, con responsable y motivo de corrección | RF-17; CU-20 |
| library_credentials | Cotejo local, responsable, fechas y referencia; sin datos de Koha | RF-09, RF-10; CU-14 |

Relaciones principales: `auth.users → profiles → user_roles`; `activities → activity_sessions → enrollments / attendances`; `spaces → activity_sessions`; `profiles → library_credentials`. Los UUID se generan en la base, sin IDs fijos para los datos de ejemplo.

## Datos cargados

Tres espacios, tres actividades y tres sesiones, todas marcadas `is_demo = true`, con referencias de autorización explícitamente ficticias. Las sesiones corresponden a los ejemplos del frontend en octubre de 2026. La zona utilizada para estos ejemplos es `America/Mazatlan`, pendiente de validación de configuración institucional. Ningún aforo o actividad acredita aprobación real.

No se cargaron cuentas, contraseñas, credenciales o inscripciones permanentes. Las cuentas usadas para verificar el esquema se insertaron en una transacción de prueba sin contraseña y se revirtieron con ROLLBACK. No enviaron correos y no deben copiarse como mecanismo de registro.

## Cómo empezar los registros de prueba

1. Crear una cuenta ficticia mediante Supabase Auth, desde su panel o al conectar después el registro real. No insertar manualmente cuentas en `auth.users` para uso normal.
2. El trigger crea automáticamente su perfil y solo el rol `user`. Metadatos como `role=administrator` no conceden permisos.
3. Asignar los roles del personal y las sesiones desde SQL confiable o el futuro backend, registrando motivo. Las capacidades de préstamos y publicación se concretarán en ese backend; un administrador no adquiere por defecto autoridad de actividades.
4. Insertar una inscripción con `session_id` y `user_id`: su estado inicial es `pending`. Para confirmar, registrar `decision_by` y `decided_at`; rechazar requiere motivo. No se valida credencial para inscribirse.
5. Registrar asistencia aparte; confirmar una inscripción no crea una asistencia. Una corrección de estado requiere motivo. Las actividades con fecha pasada deberán reemplazarse por nuevas sesiones de prueba para probar nuevas inscripciones.

El frontend ya lee los datos y guarda registro e inscripciones mediante Supabase Auth y RPC. Los detalles de prueba están en `../PRUEBA-PERSISTENCIA.md`.

## Acceso y límites actuales

RLS está habilitado en las 11 tablas. Visitantes leen actividades publicadas, sesiones visibles, espacios activos y catálogo de roles. Una cuenta autenticada lee lo propio; responsables con rol y asignación leen inscripciones/asistencias de su sesión. Un administrador puede consultar perfiles y asignaciones de roles, pero ese rol no concede acceso general a expedientes de actividad o credenciales.

El navegador no tiene escritura directa sobre las tablas. Solicitar, cancelar y resolver inscripciones utiliza RPC con validación de actor, cuenta activa y ámbito. El panel del personal requiere rol y asignación de sesiones. Las cancelaciones propias solo se permiten antes del inicio y nadie resuelve su propia inscripción. No colocar `service_role` en el frontend. FastAPI y la delegación de capacidades adicionales siguen pendientes.

Hay restricciones contra inscripciones/asistencias duplicadas, nuevos registros confirmados automáticamente, sobrecupos, reducción de cupo por debajo de confirmados y traslapes de sesiones autorizadas. La confirmación bloquea la fila de la sesión antes de contar lugares. Las modificaciones confiables de agenda deben tomar en cuenta cambios de inscripciones y avisos; no se implementó notificación automática. La cancelación administrativa no elimina automáticamente inscripciones ni historial.

`library_credentials` conserva las emisiones y renovaciones por fecha. La vigencia se evalúa con `expires_on`; no se guarda un estado vencido que pueda quedar desactualizado. La asociación exclusiva de números entre titulares y la resolución de duplicados quedan pendientes del procedimiento de préstamos. No se crean puntos ni recompensas todavía.

Se posponen propuestas de eventos, solicitudes de espacios y citas, contenido editorial general, contacto, foro, evidencias/Storage, estadísticas completas, avisos, progreso, premios y RAG. El historial de asistencia y de asignaciones requerirá ampliación antes de cumplir toda la trazabilidad del sistema completo.

## Archivos y validación

- `demo-core-schema.sql`: copia del SQL aplicado mediante la migración remota `demo_core_schema`. No volver a ejecutarlo sobre las tablas existentes.
- `demo-seed.sql`: carga repetible de ejemplos sin sobrescribir registros existentes.
- `demo-schema-checks.sql`: 18 comprobaciones transaccionales; todos los registros de la prueba se revierten.
- `frontend/src/lib/database.types.ts`: tipos generados desde Supabase y utilizados por el cliente.

Resultado: 18 comprobaciones satisfactorias; lectura REST con clave publicable HTTP 200 y tres actividades; 11 tablas con RLS; asesor de seguridad sin hallazgos. La comprobación del último cupo fue secuencial; todavía no se realizó una prueba de carga concurrente de 10 peticiones como exige RNF-18 para la versión final. El asesor de rendimiento solo señaló índices todavía sin uso, esperado en una base recién creada ([referencia](https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index)).

Guías consultadas: [RLS de Supabase](https://supabase.com/docs/guides/database/postgres/row-level-security) y [pruebas de permisos](https://supabase.com/docs/guides/local-development/testing/pgtap-extended). Estos controles no sustituyen las autorizaciones ni la aceptación institucional.

## Actualización: persistencia habilitada
El registro, acceso e inscripciones ya usan Supabase. Las restricciones anteriores de escritura directa se conservan: las acciones se realizan mediante RPC con validación de identidad y ámbito. Consultar ../PRUEBA-PERSISTENCIA.md para el estado actual y la configuración de correo. Las secciones previas describen la fase inicial del esquema.
