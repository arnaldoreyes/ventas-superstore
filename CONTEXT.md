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

## Cómo se trabaja (acordado)

- Modo **guiado**: Arnaldo escribe la consulta primero; la IA corrige y recién después
  muestra la solución de referencia.
- Si su consulta funciona, funciona. Si es optimizable, se le dice **dónde** y se le entrega
  la versión mejorada en el mismo mensaje. Nunca "está mal, averigua por qué".
- Sin estancamiento: la IA completa las interpretaciones cortas o flojas y redacta el PR.
- Reparto público/privado: al repositorio va la consulta que responde la pregunta con su
  explicación. El cómo se llegó ahí, las pistas y los intentos van a `_apuntes/`.

## Dataset

`Sample - Superstore` (Tableau): 9.994 líneas de pedido, Estados Unidos, 2014-2017.
Origen, hash, licencia y controles de integridad en `data/README.md`.

## Stack y entorno

- PostgreSQL 18. Servicio `postgresql-x64-18`, puerto 5432. Base `ventas_superstore`,
  rol `analista`. Credenciales locales en `_apuntes/db.env` (gitignored).
- `psql` no está en el PATH: `C:\Program Files\PostgreSQL\18\bin\psql.exe`
- Power BI Desktop y Excel.
- El shell del agente es **Windows PowerShell 5.1**, no PowerShell 7: no existen
  `-Encoding utf8NoBOM` ni otras novedades de PS7.
- El shell del agente **no tiene red** (TLS bloqueado por el sandbox). Las descargas y los
  `push` los ejecuta Arnaldo; el agente trabaja en local.

## Modelo de datos

- `raw.superstore`: copia fiel del CSV, 21 columnas, clave primaria `row_id`. No se modifica.
- `analytics`: capa derivada. Aquí viven las vistas de limpieza y una vista por escalón,
  para que cada respuesta sea trazable paso a paso.

## Las 6 preguntas principales

En `docs/preguntas.md`. Estado: ninguna respondida todavía.

## Decisiones tomadas

1. Stack: PostgreSQL + Power BI en los proyectos 1 y 2; MySQL en el proyecto 3 (marketing).
2. Un repositorio por proyecto.
3. Cada escalón se materializa como una vista encadenada en `analytics`.
4. El CSV original se commitea (2.287.806 bytes) para que el repositorio sea autorreproducible.
5. `docs/` en español; nombres de archivos, ramas y columnas en inglés.
6. `_apuntes/` está gitignored: cuaderno personal, no se publica.
7. La capa `raw` no impone reglas de negocio (ni `NOT NULL` ni `CHECK`), solo tipos. Las
   reglas y las validaciones van en `analytics`.
8. El CSV está declarado `-text` en `.gitattributes` y `core.autocrlf=false` en local. Sin
   eso git convierte CRLF a LF al versionar y el archivo del repositorio deja de coincidir
   con el hash documentado.
9. El dinero va en `numeric`, nunca en `float`. La suma exacta de `sales` es
   2.297.200,8603; una verificación previa con punto flotante daba 2.297.200,8604.

## Convenciones

- Ramas: `feat/`, `fix/`, `docs/`, `chore/`. `main` no se toca directamente.
- Commits en español con Conventional Commits.
- Cada cambio entra por pull request usando `.github/pull_request_template.md`.

## Estado actual

**Fase 1 cerrada.** Repositorio creado, dataset verificado y versionado byte a byte, esquema
y carga ejecutados en PostgreSQL. La carga reporta 9.994 filas, 2.297.200,8603 de ventas y
286.397,0217 de utilidad, y coincide con los controles canónicos.

## Siguiente paso

Escribir `sql/03_clean.sql`. Lo escribe **Arnaldo**. La IA ya entregó el perfil de calidad
calculado y la lista de decisiones que hay que tomar antes de escribirlo.

## Hallazgos de calidad del dato (verificados)

- Codificación **Windows-1252**, no UTF-8: 624 caracteres no ASCII de 10 tipos distintos
  (espacio duro `U+00A0`, comillas tipográficas, `¾`, vocales `à ä é ö ü`) en nombres de
  producto y de cliente. La carga necesita `ENCODING 'WIN1252'`, y el espacio duro
  sobrevive a un `TRIM` normal.
- Fechas en formato `M/D/YYYY`: dependen del `DateStyle` de la sesión.
- `Postal Code` es un identificador, no una cantidad: va como `text` para no perder ceros
  a la izquierda.
- Totales exactos: ventas 2.297.200,8603 y utilidad 286.397,0217.
- Corregido: los dos archivos candidatos de la descarga (`Sample - Superstore.csv` y
  `SampleSuperstore.csv`) resultaron ser **el mismo dataset** con fines de línea distintos
  (CRLF y LF). Una deducción previa basada en el tamaño fue errónea.

## Pendientes abiertos

- `push` de `main` y de la rama `feat/carga-datos-superstore`, y apertura del pull request.
- Silenciar el `NOTICE` del `DROP TABLE IF EXISTS` en `01_schema.sql` para que los scripts
  corran sin ruido.
