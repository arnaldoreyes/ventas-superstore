# Contexto del proyecto

> Archivo vivo. Se actualiza al cerrar cada fase. Existe para poder abrir una sesión
> nueva por pregunta principal sin repetir contexto. Si algo no está aquí, no existe.

## Objetivo

Portafolio de análisis de datos para postular a cargos junior. Este es el proyecto 1 de 3:
**ventas**. Los otros dos serán salud/farmacia y marketing. Siempre SQL + Power BI + Excel.
Sin Python ni ningún otro lenguaje de programación.

## Autor

Arnaldo Reyes, Ingeniero Industrial, base front-end (HTML, CSS, JavaScript, PHP, Laravel).
Formado como analista de datos con cursos de Power BI, SQL y Excel. Nivel objetivo: junior.

## Dataset

`Sample - Superstore` (Tableau): 9.994 líneas de pedido, Estados Unidos, 2014-2017.
Origen, hash, licencia y controles de integridad en `data/README.md`.

## Stack y entorno

- PostgreSQL 18. Servicio `postgresql-x64-18`, puerto 5432.
  `psql` **no** está en el PATH: `C:\Program Files\PostgreSQL\18\bin\psql.exe`
- Power BI Desktop
- Excel

## Modelo de datos

- Esquema `raw`: tabla `raw.superstore`, copia fiel del CSV. No se modifica.
- Esquema `analytics`: capa derivada. Aquí viven las vistas de limpieza y una vista por
  escalón, para que cada respuesta sea trazable paso a paso.

## Las 6 preguntas principales

En `docs/preguntas.md`. Estado: ninguna respondida todavía.

## Decisiones tomadas

1. Stack: PostgreSQL + Power BI en los proyectos 1 y 2; MySQL en el proyecto 3 (marketing).
2. Un repositorio por proyecto.
3. Cada escalón se materializa como una vista encadenada en `analytics`.
4. El CSV original se commitea (2,3 MB) para que el repositorio sea autorreproducible.
5. `docs/` en español; nombres de archivos, ramas y columnas en inglés.
6. `_apuntes/` está gitignored: cuaderno personal, no se publica.
7. Modo de trabajo acordado: **guiado**. El autor escribe primero, la IA corrige, y solo
   después de su intento aparece la solución de referencia.
8. La capa `raw` no impone reglas de negocio (nada de `NOT NULL` ni `CHECK`): solo tipos.
   Las reglas y las validaciones van en la capa `analytics`.

## Convenciones

- Ramas: `feat/`, `fix/`, `docs/`, `chore/`. `main` no se toca directamente.
- Commits en español con Conventional Commits.
- Cada cambio entra por pull request usando `.github/pull_request_template.md`.

## Estado actual

Fase 1 (preparación) en curso. Repositorio creado, dataset descargado y verificado contra
los totales canónicos, esquema y carga escritos. Falta ejecutar la carga en PostgreSQL.

## Hallazgos de calidad del dato (verificados)

- Codificación **Windows-1252**, no UTF-8: 624 caracteres no ASCII de 10 tipos distintos
  (espacio duro `U+00A0`, comillas tipográficas `“ ”`, `¾`, vocales `à ä é ö ü`) en nombres
  de producto y de cliente. La carga necesita `ENCODING 'WIN1252'` y el espacio duro
  sobrevive a un `TRIM` normal.
- Fechas en formato `M/D/YYYY`: dependen del `DateStyle` de la sesión.
- `Postal Code` es un identificador, no una cantidad: va como `text` para no perder ceros.
- Sin valores vacíos en `Postal Code`.
- Totales de control: ventas 2.297.200,86 y utilidad 286.397,02.

## Pendientes abiertos

- Definir cómo se conecta `psql`: rol dedicado y archivo de credenciales local.
- Crear el repositorio remoto en GitHub y definir quién ejecuta el `push`.
