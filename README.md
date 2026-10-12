# Demo del portal de la Biblioteca Solón Argüello

Proyecto académico del portal de la **Biblioteca Pública Central Estatal Solón Argüello (CECAN), colección 165**, en Tepic, Nayarit. Este repositorio contiene una demo pequeña para mostrar el diseño y un recorrido funcional de registro e inscripción. No es el portal completo ni una versión lista para producción.

## Qué llevamos

| Área | Estado actual |
| --- | --- |
| Repositorio | Git inicializado y vinculado a `rolopezag-droid/proyectoCECAN` en GitHub. Los cambios locales requieren commit y push para que el equipo pueda descargarlos. |
| Diseño | Inicio, agenda, detalle de actividad, registro, acceso, Mi cuenta y panel del responsable; adaptable a celular. |
| Registro y acceso | Conectados a Supabase Auth: registro por correo, confirmación, inicio y cierre de sesión. |
| Agenda | Lee actividades, sesiones y espacios desde Supabase. |
| Inscripciones | Se guardan como Pendiente y se recuperan al recargar o iniciar sesión otra vez. |
| Mi cuenta | Consulta las inscripciones propias y permite cancelarlas antes del inicio. |
| Panel del responsable | Requiere rol y sesiones asignadas; permite confirmar o rechazar solicitudes con registro de la decisión. |
| Base de datos | 11 tablas con relaciones, restricciones y políticas de acceso RLS. |
| Datos de ejemplo | Tres actividades, tres sesiones y tres espacios marcados como datos de demo. |
| Backend FastAPI | Pendiente. La demo actual utiliza Supabase y funciones PostgreSQL mediante RPC. |
| Docker y Nginx | Previstos en D3; todavía no incorporados a esta demo. |

**Lo capturado desde los formularios conectados ya se guarda en Supabase.** Las actividades y aforos cargados son ficticios; no representan programación ni autorizaciones oficiales de la biblioteca.

## Qué demostramos ante la maestra

La evaluación solicita:

- **D2:** Ficha de Usuario, Matriz de Contexto de Uso, Historias de Usuario, Criterios de Aceptación y Usabilidad, y Diagrama de Flujo de Usuarios.
- **D3:** Especificaciones Técnicas y una demostración de viabilidad de las herramientas propuestas.
- **D4:** Cronograma de Actividades y tablero en Notion con estados, integrantes, sprints y fechas; explicación del primer sprint por integrante.

Esta aplicación apoya la demo técnica. No sustituye los documentos ni el tablero de Notion. Todos los integrantes deben poder explicar el recorrido, las herramientas y sus pendientes. No presentar FastAPI, Docker o Nginx como herramientas ya demostradas por esta aplicación.

## Tecnologías que ya utiliza la demo

- **React + TypeScript:** pantallas, navegación y comportamiento de la interfaz.
- **Vite:** servidor local y compilación del frontend.
- **CSS + lucide-react:** diseño adaptable e iconos.
- **Supabase Auth:** cuentas y sesiones; las contraseñas no se guardan en tablas propias.
- **PostgreSQL en Supabase:** perfiles, actividades e inscripciones persistentes.
- **RLS:** reglas sobre qué registros puede consultar cada cuenta.
- **RPC:** operaciones en la base para solicitar, cancelar y revisar inscripciones, con comprobación de identidad y permisos.

El stack completo previsto en los documentos incluye Python/FastAPI, Docker y Nginx. Su implementación sigue pendiente y deberá explicarse como tal en la evaluación.

## Organización del repositorio

```text
frontend/
  src/
    App.tsx                         Pantallas y acciones del usuario
    styles.css                      Diseño visual y adaptación a móvil
    lib/
      supabase.ts                   Cliente y comprobación de conexión
      useLibrary.ts                 Carga de datos y seguimiento de sesión
      database.types.ts             Tipos generados desde Supabase
    components/
      SupabaseConnection.tsx        Comprobación de acceso desde el panel
  .env.example                      Plantilla de configuración
  package.json                      Dependencias y comandos
  package-lock.json                 Versiones instaladas
backend/                            Reservado para FastAPI; sin implementación
docs/
  PRUEBA-PERSISTENCIA.md             Guía detallada del recorrido
  database/                         Estructura SQL y pruebas de la base
```

## Ejecutar en otra computadora

Se necesita Git, Node.js y npm. El entorno donde se verificó la demo utiliza Node.js 24.13.0 y npm 11.6.2. También se necesita Internet para instalar dependencias y acceder a Supabase.

### 1. Obtener el proyecto

Si todavía no se tiene el repositorio:

```powershell
git clone https://github.com/rolopezag-droid/proyectoCECAN.git
cd proyectoCECAN
cd frontend
npm ci
```

Si ya se tiene, actualizar desde GitHub antes de trabajar, revisando primero si hay cambios locales con `git status`. Instalar dependencias con `npm ci` desde `frontend` después de descargar cambios en el archivo de dependencias.

### 2. Configurar Supabase

Desde `frontend`, copiar la plantilla:

```powershell
Copy-Item .env.example .env.local
```

Completar `frontend/.env.local` con:

```dotenv
VITE_SUPABASE_URL=https://rampjtejiwhbmqahldkz.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=sb_publishable_REEMPLAZAR_CON_LA_CLAVE_DEL_PROYECTO
```

La clave publicable se obtiene desde el diálogo **Connect** o la sección **API Keys** de Supabase. No utilizar una clave secreta, `service_role` ni la contraseña de PostgreSQL. `.env.local` está excluido de Git; por eso cada computadora necesita su propia configuración. Si ya existe, no sobrescribirlo con la plantilla.

Proyecto compartido:

- **Nombre:** `proyectoCECAN`.
- **Project ID:** `rampjtejiwhbmqahldkz`.
- **URL:** `https://rampjtejiwhbmqahldkz.supabase.co`.

### 3. Iniciar

```powershell
npm run dev
```

Abrir la dirección que imprime Vite. El puerto habitual es 5173, pero puede cambiar si ya está ocupado. Mantener esa terminal abierta y utilizar `Ctrl+C` para detener el servidor. Reiniciar después de modificar `.env.local`.

Para comprobar TypeScript y generar la compilación:

```powershell
npm run build
```

## Crear y probar una cuenta

1. Abrir **Mi cuenta → Crea tu cuenta**.
2. Puede usarse un nombre ficticio, pero el **correo debe ser real y accesible** para confirmar el registro.
3. Elegir una contraseña exclusiva para la demo: al menos ocho caracteres, con letras y números.
4. Abrir el correo de confirmación, confirmar la cuenta y volver al portal para iniciar sesión.
5. Abrir una actividad disponible y seleccionar **Solicitar inscripción**.
6. Consultar **Mi cuenta**: debe aparecer Pendiente.
7. Recargar la página y volver a Mi cuenta: la solicitud debe permanecer guardada.
8. Probar la cancelación antes del inicio. La solicitud cambia a Cancelada y conserva su historial.

El registro crea automáticamente un perfil y el rol básico `user`. No crea una credencial bibliotecaria ni asigna permisos del personal. No se exige credencial para inscribirse.

### Configuración de confirmación de correo

En **Supabase → Authentication → URL Configuration**, la persona administradora del proyecto debe configurar la dirección local utilizada por el equipo como **Site URL** y agregar las direcciones necesarias a **Redirect URLs**; por ejemplo `http://localhost:5173` y `http://127.0.0.1:5173`. Si Vite utiliza otro puerto, agregar la dirección correspondiente.

Esta configuración del panel no se modificó desde el plugin. La confirmación de correo sigue activada. El proveedor de correo puede limitar destinatarios o envíos: revisar el mensaje de error y la configuración del proveedor/SMTP si no llega el correo. Más detalles en [la guía de persistencia](docs/PRUEBA-PERSISTENCIA.md).

## Roles: cómo acceder como usuario, editor o administrador

Todos entran desde **Mi cuenta**, con su propio correo y contraseña. Una persona puede reunir varios roles en la misma cuenta, aunque para mostrar dos perfiles distintos se pueden registrar dos cuentas.

| Rol en la base | Uso | Qué hay construido |
| --- | --- | --- |
| `user` | Usuario registrado | Mi cuenta, solicitud y cancelación de inscripción propia. Se asigna al registrarse. |
| `editor` | Preparación de contenido institucional | Rol disponible; todavía no hay pantallas para editar o publicar contenido. |
| `activity_manager` | Responsable de actividades | Panel para revisar inscripciones de sus sesiones asignadas. |
| `administrator` | Administración de cuentas y permisos | Rol disponible; todavía no hay pantallas para administrar cuentas o asignar roles. |

Para preparar una cuenta de editor o administrador:

1. Registrar y confirmar la cuenta.
2. Informar a quien administra la base qué cuenta corresponde a cada rol, utilizando el correo o UUID del usuario.
3. La persona autorizada asigna el rol en `user_roles` desde Supabase, registrando motivo y responsable cuando corresponda.
4. Volver a iniciar sesión o actualizar la página.

**Nunca es necesario compartir la contraseña para asignar un rol.** Ser editor o administrador no habilita automáticamente el panel de actividades. Ese panel requiere `activity_manager` y asignaciones en `session_staff`.

## Demostrar el panel del responsable

Se necesitan dos cuentas: un participante y un responsable. El responsable debe tener `activity_manager` y estar asignado a las sesiones de prueba.

1. El participante solicita una inscripción.
2. El responsable inicia sesión y abre **Vista del personal**.
3. Solo aparecen solicitudes de las sesiones que tiene asignadas.
4. Confirma una solicitud o la rechaza indicando el motivo.
5. El participante vuelve a su ventana o recarga y consulta el nuevo estado en Mi cuenta.

Los cambios se guardan en Supabase y generan historial. El responsable no puede resolver su propia inscripción. Todavía no hay actualización en tiempo real: volver a la ventana o recargar actualiza la información.

No se creó una cuenta de personal con contraseña compartida ni se asignaron privilegios permanentes a una persona sin identificarla. Los colaboradores del **dashboard de Supabase** y los roles de **nuestra aplicación** son permisos diferentes: una invitación al equipo de Supabase no asigna roles en el portal.

## Tablas disponibles

| Grupo | Tablas |
| --- | --- |
| Identidad y permisos | `profiles`, `roles`, `user_roles` |
| Agenda | `spaces`, `activities`, `activity_sessions`, `session_staff` |
| Participación | `enrollments`, `enrollment_history`, `attendances` |
| Credenciales | `library_credentials` |

Datos iniciales: **Entre páginas y café**, **Historias que cobran vida** y **Escribir para encontrarnos**, con sesiones de ejemplo en octubre de 2026. Las fechas y los aforos son de prueba; si las fechas ya pasaron, se deben preparar nuevas sesiones futuras para demostrar inscripciones.

- Una solicitud empieza en Pendiente; la confirmación es manual.
- Una persona no puede duplicar inscripción en la misma sesión.
- El cupo se comprueba antes de confirmar.
- Una inscripción no acredita asistencia automáticamente.
- La credencial tiene validación humana y vigencia de dos años; no está integrada a los formularios actuales.
- Koha permanece externo: no se desarrollan préstamos, migraciones ni sincronización con su base.

La [documentación de la base](docs/database/README.md) contiene relaciones, trazabilidad con los requisitos, SQL y límites del esquema. Los archivos del esquema y de RPC son copias de cambios ya aplicados: no volver a ejecutarlos sobre las tablas existentes. Los scripts de comprobación usan transacciones que revierten sus datos de prueba.

## Verificación realizada y límites

- Compilación de TypeScript y Vite satisfactoria.
- Lectura de agenda desde Supabase y pantallas públicas revisadas en navegador.
- 18 comprobaciones del esquema y ocho de las operaciones persistentes satisfactorias.
- Políticas RLS habilitadas en las 11 tablas; asesor de seguridad sin hallazgos en la revisión realizada.
- Las cuentas temporales de las comprobaciones se revirtieron.

**Todavía falta comprobar el correo de confirmación con un buzón del equipo y hacer el recorrido completo con cuentas confirmadas del participante y del responsable.** Las pruebas SQL no sustituyen esa prueba. Tampoco se realizó la prueba de carga concurrente requerida para la versión final.

## Lo que sigue pendiente

- Elegir y asignar las cuentas del personal para la demo.
- Probar la confirmación de correo y el recorrido completo desde el navegador.
- Pantallas de edición de contenido y administración de cuentas.
- Backend FastAPI, Docker, Nginx y despliegue de producción.
- Solicitudes de espacios y credenciales, asistencia desde la interfaz, foro, progreso, recompensas, evidencias, avisos y RAG.
- Recuperación de contraseña y alta asistida sin correo.
- Completar/revisar los entregables D2, D3 y D4 según la consigna.
- Validaciones institucionales de identidad visual, contenidos, procedimientos y operación.

## Guía para trabajar en equipo

- Revisar este README y el estado de Git antes de comenzar.
- Usar una rama para cada cambio y revisar el resultado antes de integrarlo.
- Al cambiar lógica o pantallas, ejecutar `npm run build` y probar el recorrido afectado.
- Conservar `package-lock.json` junto con los cambios de dependencias.
- Coordinar cambios de tablas con el equipo: todos usan la misma base de prueba.
- No subir `.env.local`, contraseñas, tokens de sesión o claves secretas a GitHub.
- Utilizar información ficticia para actividades y nombres de prueba; el correo de registro sí debe poder verificarse.
- Documentar qué se implementó y qué sigue pendiente, sin presentar ejemplos como información oficial.

Para que los demás vean los cambios, hay que subirlos a GitHub. Editar archivos localmente no los publica automáticamente.
