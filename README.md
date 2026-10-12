# Análisis de ventas — Superstore

Seis preguntas de negocio respondidas con SQL sobre el dataset público **Sample - Superstore**
(9.994 líneas de pedido, Estados Unidos, 2014-2017) y comunicadas en Power BI y Excel.

El objetivo no es graficar: es responder preguntas, justificar cada decisión de limpieza y
dejar el análisis reproducible de principio a fin.

## Las 6 preguntas

| # | Pregunta | Estado |
|---|----------|--------|
| 1 | ¿Cómo evolucionan las ventas y la utilidad en el tiempo, y en qué meses se concentra el negocio? | Pendiente |
| 2 | ¿Qué categorías y subcategorías venden y cuáles destruyen margen? | Pendiente |
| 3 | ¿En qué punto el descuento deja de convenir? | Pendiente |
| 4 | ¿Quiénes son los clientes más valiosos y cómo se reparte el negocio por segmento? | Pendiente |
| 5 | ¿Cuántos productos y cuántos clientes explican el 80% de las ventas? | Pendiente |
| 6 | ¿Qué regiones y estados rinden, y qué explica a los que no rinden? | Pendiente |

Detalle de escalones y conceptos en [`docs/preguntas.md`](docs/preguntas.md).

## Stack

- **PostgreSQL 18** — modelado, limpieza y análisis
- **Power BI Desktop** — tablero, una página por pregunta
- **Excel** — tabla dinámica y gráfico de apoyo por pregunta

Sin Python ni otros lenguajes: todo el tratamiento de datos vive en SQL.

## Estructura

```
ventas-superstore/
├─ CONTEXT.md                 contexto vivo del proyecto
├─ data/
│  ├─ README.md               origen, hash, licencia y controles de integridad
│  └─ raw/superstore.csv      archivo original, sin editar
├─ sql/
│  ├─ 01_schema.sql           esquemas y tabla cruda
│  ├─ 02_load.sql             carga del CSV
│  ├─ 03_clean.sql            limpieza y validaciones
│  └─ questions/              un script por pregunta
├─ powerbi/                   tablero y medidas DAX documentadas
├─ excel/                     tablas dinámicas por pregunta
├─ docs/
│  ├─ preguntas.md            las 6 preguntas y sus escalones
│  ├─ metodologia.md          linaje, supuestos y limitaciones
│  └─ respuestas/             interpretación escrita de cada respuesta
└─ _apuntes/                  notas personales, no se publica
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

Fase 1 (preparación) en curso. Ver [`CONTEXT.md`](CONTEXT.md) para el detalle y el siguiente paso.
