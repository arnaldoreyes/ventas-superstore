# Contexto del proyecto

> Archivo vivo. Se actualiza al cerrar cada fase o cada pregunta. Existe para poder abrir
> una sesión nueva sin repetir contexto. Si algo no está aquí, no existe.

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
- Sin estancamiento: la IA completa las interpretaciones cortas y redacta el PR.
- Un objetivo a la vez. Sin recorridos completos ni verificaciones de "vamos bien".
- En git se usa `git switch`, no `git checkout`.
- Reparto público/privado: al repositorio va la consulta que responde la pregunta con su
  explicación. El cómo se llegó ahí, las pistas y los intentos van a `_apuntes/`.

## Dataset

`Sample - Superstore` (Tableau): 9.994 líneas de pedido, Estados Unidos, 2014-2017.
Origen, hash, licencia y controles de integridad en `data/README.md`.

## Stack y entorno

- PostgreSQL 18. Base `ventas_superstore`, rol `analista`. Credenciales locales en
  `_apuntes/db.env` (gitignored).
- `psql` no está en el PATH: `C:\Program Files\PostgreSQL\18\bin\psql.exe`
- Power BI Desktop y Excel.
- El shell del agente es **Windows PowerShell 5.1**: no existen `-Encoding utf8NoBOM` ni
  otras novedades de PS7.
- El shell del agente **no tiene red** (TLS bloqueado). Descargas y `push` los hace Arnaldo.

## Modelo de datos

- `raw.superstore`: copia fiel del CSV, 21 columnas, clave primaria `row_id`. No se modifica.
- `analytics.superstore`: vista limpia con columnas derivadas (año, mes, año-mes, `ship_days`,
  `margin`). Pendiente de crear.
- Los escalones de cada pregunta se materializan como vistas encadenadas en `analytics`.

## Las 6 preguntas principales

En `docs/preguntas.md`. Estado: ninguna respondida todavía.

## Decisiones tomadas

1. Stack: PostgreSQL + Power BI en los proyectos 1 y 2; MySQL en el proyecto 3 (marketing).
2. Un repositorio por proyecto.
3. El CSV original se commitea (2.287.806 bytes) para que el repositorio sea autorreproducible.
4. `docs/` en español; nombres de archivos, ramas y columnas en inglés.
5. `_apuntes/` está gitignored: cuaderno personal, no se publica.
6. La capa `raw` no impone reglas de negocio (ni `NOT NULL` ni `CHECK`), solo tipos.
7. El CSV está declarado `-text` en `.gitattributes` y `core.autocrlf=false` en local: sin
   eso git convierte CRLF a LF y el archivo del repositorio deja de coincidir con su hash.
8. El dinero va en `numeric`, nunca en `float`. La suma exacta de `sales` es 2.297.200,8603;
   una verificación previa con punto flotante daba 2.297.200,8604.

## Estado actual

**Fase 1 cerrada y fusionada** (PR #1). `main` limpio, rama borrada. La base tiene
`raw.superstore` con 9.994 filas verificadas. En `analytics` no hay ningún objeto todavía.
Rama en curso: `feat/limpieza-datos`.

## Siguiente paso

Escribir `sql/03_clean.sql` — lo escribe **Arnaldo** — para crear la vista
`analytics.superstore`. Es el único paso que falta antes de arrancar la Q1.

## Perfil del dato (calculado sobre raw.superstore; script en `_apuntes/perfil_datos.sql`)

Lo que está limpio y **no se toca**:

- 0 valores nulos en las 17 columnas verificadas.
- 0 ventas ≤ 0 y 0 unidades ≤ 0.
- 0 envíos anteriores al pedido: confirma que leer las fechas como `M/D/YYYY` fue correcto.
- 438 códigos postales de 4 dígitos: confirma que `postal_code` debía ser `text`.
- 1.871 líneas con utilidad negativa (18,7%) **no son suciedad**: son el insumo de la Q3.
- Codificación **Windows-1252**: 624 caracteres no ASCII (espacio duro `U+00A0`, comillas
  tipográficas, `¾`, vocales `à ä é ö ü`). El espacio duro sobrevive a un `TRIM` normal.

Los 4 problemas reales:

| # | Problema | Alcance |
|---|---|---|
| P1 | Espacio duro `chr(160)` dentro de `product_name` | 225 filas |
| P2 | Espacio normal al final del nombre | 16 filas (3 productos, en todas sus filas) |
| P3 | `product_id` ambiguo: 32 ids con 2 nombres de producto distintos y 16 nombres con varios ids. Clave fiable: el par `(product_id, product_name)` = 1.894 | 337 filas |
| P4 | Línea duplicada exacta (`row_id` 3406 y 3407, pedido `US-2014-150119`) | 1 fila |

## Decisiones de limpieza tomadas

1. Limpiar P1 y P2. Orden obligatorio: primero `replace(product_name, chr(160), ' ')` y
   después `btrim`, porque `btrim` no quita el espacio duro.
2. No tocar comillas tipográficas, `¾` ni vocales acentuadas: son texto legítimo y la base
   está en UTF-8. Se limpia lo invisible, no lo que no gusta cómo se ve.
3. La línea duplicada (P4) se conserva y se documenta: no se puede probar que sea un error y
   eliminarla rompería la coincidencia con los totales canónicos verificados.
4. Identidad de producto en Q2 y Q5: el par `(product_id, product_name)`, o la subcategoría.
   No se inventa una clave nueva.
5. La capa limpia es una **vista**, no una tabla.
6. `postal_code` no se toca ni se rellena con ceros: no sabemos si el cero se perdió antes de
   llegar al archivo, y la Q6 trabaja a nivel de estado.

Criterios de aceptación de la limpieza. Deben dar 0, y el conteo debe seguir siendo 9.994:

| Criterio | Debe dar |
|---|---|
| `product_name LIKE '%' \|\| chr(160) \|\| '%'` | 0 |
| `product_name <> btrim(product_name)` | 0 |
| `ship_date < order_date` | 0 |
| `count(*)` | 9.994 |
| `sum(sales)` | 2.297.200,8603 |

## Pendientes abiertos

- Agregar a la plantilla de PR el borrado de la rama tras el merge y una sección
  "Después del merge". Va en una rama `docs/` corta.
- Silenciar el `NOTICE` del `DROP TABLE IF EXISTS` en `01_schema.sql`.
