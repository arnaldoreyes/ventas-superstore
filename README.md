# Análisis de ventas — Superstore

Seis preguntas de negocio respondidas con **SQL sobre PostgreSQL** y comunicadas en un tablero
de **Power BI**, sobre el dataset público **Sample - Superstore** (9.994 líneas de pedido,
Estados Unidos, 2014-2017).

El objetivo no es graficar: es responder preguntas de negocio, justificar cada decisión de
limpieza y dejar el análisis reproducible de principio a fin.

## Las 6 preguntas

| # | Pregunta | Estado |
|---|----------|--------|
| 1 | ¿Cómo evolucionan las ventas y la utilidad en el tiempo, y en qué meses se concentra el negocio? | SQL listo · tablero pendiente |
| 2 | ¿Qué categorías y subcategorías venden y cuáles destruyen margen? | Pendiente |
| 3 | ¿En qué punto el descuento deja de convenir? | Pendiente |
| 4 | ¿Quiénes son los clientes más valiosos y cómo se reparte el negocio por segmento? | Pendiente |
| 5 | ¿Cuántos productos y cuántos clientes explican el 80% de las ventas? | Pendiente |
| 6 | ¿Qué regiones y estados rinden, y qué explica a los que no rinden? | Pendiente |

## Respuestas

Cada pregunta cerrada deja acá su hallazgo: la cifra que responde, cómo se lee y la captura de
su página en el tablero. Este README es el único lugar donde vive la respuesta.

Los scripts de `sql/questions/` no la repiten: cada uno lleva, como comentario, **qué responde y
cómo se lee**. Así el script se entiende solo y no hay dos versiones del mismo hallazgo.

## Stack

- **PostgreSQL 18** — modelado, limpieza y análisis. Es donde vive el dato.
- **Power BI Desktop** — el tablero, con su modelo de datos y las medidas DAX.

## Estructura

```
ventas-superstore/
├─ data/
│  ├─ README.md               origen, hash, licencia y controles de integridad
│  └─ raw/superstore.csv      archivo original, sin editar
├─ sql/
│  ├─ 01_schema.sql           esquemas y tabla cruda
│  ├─ 02_load.sql             carga del CSV
│  ├─ 03_clean.sql            limpieza, tipado y validaciones
│  ├─ 04_model.sql            dimensiones, hechos y tabla de fechas
│  └─ questions/              un script numerado por pregunta
├─ powerbi/
│  ├─ ventas_superstore.pbix  modelo y tablero
│  └─ img/                    captura de cada página
└─ docs/
   └─ methodology.md          linaje, decisiones y limitaciones del dato
```

## Cómo reproducirlo

1. Descargar el CSV y verificar su hash: instrucciones y valores en [`data/README.md`](data/README.md).
2. Crear la base de datos:

   ```sql
   CREATE DATABASE ventas_superstore;
   ```

3. Crear los esquemas y la tabla, cargar los datos y limpiarlos, siempre desde la raíz
   del repositorio y con `psql` (los scripts usan `\copy`, que es un meta-comando de `psql`):

   ```
   psql -U <usuario> -d ventas_superstore -f sql/01_schema.sql
   psql -U <usuario> -d ventas_superstore -f sql/02_load.sql
   psql -U <usuario> -d ventas_superstore -f sql/03_clean.sql
   ```

   La carga debe terminar reportando **9.994 filas** y **2.297.200,86** de ventas. Si esos
   números no coinciden, la fuente está alterada y el análisis no vale.

4. Abrir `powerbi/ventas_superstore.pbix` y refrescar; apunta a la base local.

## Origen de los datos

`Sample - Superstore` es una muestra ficticia que Tableau distribuye con su producto. Fuente
exacta, hash SHA-256, licencia y salvedades en [`data/README.md`](data/README.md).

## Estado

**Cerrado.** La base tiene la capa cruda `raw.superstore` y la vista limpia
`analytics.superstore`, con sus comprobaciones de aceptación pasando. El registro técnico de
qué se encontró en el dato, qué se decidió y qué quedó sin limpiar está en
[`docs/methodology.md`](docs/methodology.md).

**En construcción.** `sql/04_model.sql` (dimensiones, hechos y tabla de fechas) y el tablero
`powerbi/ventas_superstore.pbix`. De las seis preguntas, la Q1 tiene su consulta terminada;
le faltan la respuesta en este README y su página en el tablero.
