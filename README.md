# Demo del portal de la Biblioteca Solón Argüello

Repositorio académico para preparar una demostración pequeña de viabilidad técnica del portal de la Biblioteca Pública Central Estatal Solón Argüello (CECAN).

## Alcance actual

Preparar el repositorio y, después, construir únicamente los recorridos necesarios para la evaluación. No representa el sistema completo ni una versión de producción.

La evaluación solicita D2 (cinco documentos de diseño centrado en usuarios), D3 (especificaciones técnicas y demo funcional) y D4 (cronograma y demostración del tablero en Notion).

## Tecnologías previstas

- Frontend: React, TypeScript y Vite.
- Backend: Python y FastAPI.
- Datos, autenticación y archivos: Supabase, según lo necesario para la demo.
- Docker y Nginx: previstos en D3; su incorporación a la demo se decidirá según el recorrido que se presente.

## Estructura

```text
frontend/       Interfaz de la demo
backend/        API de la demo
docs/           Documentación y notas de evaluación
```

## Reglas de trabajo

- Usar datos ficticios para la demostración.
- Mantener contraseñas, tokens y claves fuera del repositorio.
- Guardar la configuración privada en archivos `.env`, excluidos de Git.
- Publicar solo nombres de variables y valores de ejemplo en `.env.example` cuando se incorporen servicios.
- Koha será un enlace externo; no se desarrollarán préstamos ni sincronización de su base.
- Distinguir las funciones demostradas de las que siguen previstas en la documentación.

## Estado

Estructura inicial preparada. Todavía no hay aplicaciones, dependencias instaladas ni comandos de ejecución.
