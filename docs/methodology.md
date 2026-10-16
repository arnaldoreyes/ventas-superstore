# Metodología

Qué se encontró en el dato, qué se decidió con cada cosa y por qué. Todo lo que aparece
acá está verificado y es reproducible con los scripts del repositorio.

## Origen y verificación del archivo

Fuente, hash SHA-256, licencia y controles de integridad en [`../data/README.md`](../data/README.md).
El archivo se contrastó contra los totales conocidos del dataset: 9.994 filas,
2.297.200,8603 en ventas y 286.397,0217 en utilidad.

## Capas de datos

| Capa | Objeto | Regla |
|---|---|---|
| Cruda | `raw.superstore` | Copia fiel del CSV. No se modifica nunca. |
| Limpia | `analytics.superstore` | Vista derivada. Es la base de todo el análisis. |
| Modelo | `analytics.dim_*`, `analytics.fact_sales` | Vistas del modelo en estrella. Es lo que importa Power BI. |

La separación tiene un motivo práctico: si un número del tablero llama la atención, se puede
volver al valor original. Cualquier transformación aplicada sin dejar el original intacto
hace imposible esa verificación.

## Problemas encontrados

### 1. Codificación Windows-1252

El archivo no es UTF-8 válido: contiene 624 caracteres no ASCII, entre ellos espacio duro
(`U+00A0`), comillas tipográficas y vocales acentuadas. La carga lo resuelve declarando
`ENCODING 'WIN1252'`. Los caracteres se conservan: el texto se muestra correctamente porque
la base está en UTF-8.

### 2. Espacio duro dentro de `product_name` — 225 filas

El carácter `chr(160)` aparece en medio de los nombres, siempre a continuación de la marca
(`Konftel`, `Imation`, `Logitech`, `Plantronics`, `Jabra`). Es un carácter tipográfico
legítimo, pero usado donde correspondía un espacio normal.

Su consecuencia no es visual, porque ambos se ven idénticos: es que **rompe las búsquedas**.
Comprobado sobre el propio dato:

```sql
-- 0 filas
WHERE product_name = 'Konftel 250 Conference phone - Charcoal black'
-- 4 filas
WHERE replace(product_name, chr(160), ' ') = 'Konftel 250 Conference phone - Charcoal black'
```

El producto está en la base, pero no se encuentra escribiendo el nombre como se ve. Un
filtro escrito a mano o una relación de Power BI por nombre fallarían en silencio,
devolviendo cero filas en lugar de un error.

### 3. Espacios en los extremos de `product_name` — 16 filas

Tres productos tienen el nombre terminado en un espacio en el 100 % de sus filas. Se recortan
con `btrim`.

### 4. `product_id` no identifica un producto — 337 filas

Hallazgo principal de la revisión:

| Comprobación | Resultado |
|---|---|
| `product_id` que apuntan a dos nombres de producto distintos | 32 |
| `product_name` que aparecen bajo varios `product_id` | 16 |
| `product_id` distintos | 1.862 |
| `product_name` distintos | 1.850 |
| Pares `(product_id, product_name)` distintos | 1.894 |

Ejemplos: `OFF-PA-10001970` corresponde a "Xerox 1881" y a "Xerox 1908";
`TEC-AC-10003832`, a una memoria Imation y a un altavoz Logitech. No son variantes de
escritura: son productos distintos con el mismo código.

**Consecuencia:** agrupar por `product_id` mezcla productos distintos y los etiqueta con un
nombre arbitrario. De los 20 productos de mayor venta, uno tiene este problema. El par
`(product_id, product_name)` elimina la ambigüedad. El análisis por subcategoría no se ve
afectado, porque esa columna es consistente.

### 5. Línea duplicada exacta — 1 fila

`row_id` 3406 y 3407 son idénticas en todos los campos de negocio: mismo pedido
(`US-2014-150119`), mismo producto, mismas ventas (281,3720), misma cantidad, mismo
descuento y misma utilidad (-12,0588).

## Decisiones de limpieza

| # | Decisión | Motivo |
|---|---|---|
| 1 | Reemplazar `chr(160)` por un espacio y luego aplicar `btrim` | El orden importa: `btrim` no elimina el espacio duro |
| 2 | No modificar comillas tipográficas, `¾` ni vocales acentuadas | Son texto legítimo del nombre y la base está en UTF-8. Se corrige lo invisible, no lo que no gusta cómo se ve |
| 3 | Conservar la línea duplicada y documentarla | No puede probarse que sea un error, y eliminarla rompería la coincidencia con los totales verificados del dataset |
| 4 | Identificar productos por `(product_id, product_name)` y no por `product_id` | `product_id` es ambiguo (ver problema 4) |
| 5 | Mantener la limpieza en una vista y no en una tabla | No duplica almacenamiento y nunca queda desincronizada con la capa cruda |
| 6 | No rellenar con ceros los códigos postales de 4 dígitos | No hay evidencia de que el cero se haya perdido antes de llegar al archivo. Inventarlo sería introducir un dato falso |

## Lo que no se limpió, y por qué

- **Los márgenes negativos.** 1.871 líneas (18,7 %) cierran con utilidad negativa. No son un
  error de datos: son el resultado de la política de descuentos y el objeto central del
  análisis. Eliminarlos borraría el hallazgo.
- **Los acentos y las comillas tipográficas.** Son parte del nombre real del producto.
- **La línea duplicada.** Ver decisión 3.

## Comprobaciones de aceptación

Se ejecutan sobre `analytics.superstore` y quedan registradas en `sql/03_clean.sql`:

| Comprobación | Resultado |
|---|---|
| Nombres con espacio duro | 0 |
| Nombres con espacios en los extremos | 0 |
| Envíos anteriores al pedido | 0 |
| Cantidad de filas | 9.994 |
| Suma de `sales` | 2.297.200,8603 |

Las dos últimas confirman que la limpieza no alteró ni la cantidad de registros ni los montos.

## Modelo en estrella

Power BI importa lo que construye [`../sql/04_model.sql`](../sql/04_model.sql): una tabla de fechas,
cinco dimensiones y una tabla de hechos. Cada dimensión se relaciona 1 a muchos con los hechos: la
clave vive en la dimensión y se repite en el hecho.

| Objeto | Filas | Clave | Qué aporta |
|---|---|---|---|
| `dim_date` | 1.826 | `date` | Calendario continuo del 2014-01-01 al 2018-12-31, con año, trimestre, número y nombre de mes |
| `dim_product` | 1.894 | `product_key` | Producto con categoría y subcategoría |
| `dim_customer` | 793 | `customer_id` | Cliente con su segmento |
| `dim_geography` | 632 | `geography_key` | Región, estado, ciudad y código postal |
| `dim_ship_mode` | 4 | `ship_mode` | Modo de envío |
| `fact_sales` | 9.994 | `row_id` | Una fila por línea de pedido, con las medidas del negocio |

### Por qué son vistas y no tablas

Por el mismo motivo que la capa limpia: una vista no duplica almacenamiento y nunca queda
desincronizada con `analytics.superstore`. Con tablas habría que decidir cuándo refrescarlas y
aceptar que durante un rato muestren datos viejos. Power BI importa el resultado de una vista igual
que el de una tabla, así que no se pierde nada.

### Por qué `dim_product` lleva clave propia

Porque `product_id` no identifica un producto: 32 códigos apuntan a dos productos distintos y 16
nombres aparecen bajo varios códigos. La clave de la dimensión es `product_key`, generada sobre el
par `(product_id, product_name)`, que sí es único (1.894 combinaciones). `product_id` y
`product_name` se conservan como columnas: la clave resuelve la ambigüedad, no la esconde.

`dim_geography` lleva clave propia por un motivo distinto: el lugar es una combinación de cuatro
columnas y Power BI relaciona por una sola. `(state, city)` da 604 combinaciones únicas y
`(state, city, postal_code)` da 632, así que el código postal es imprescindible en la clave. La
ciudad sola tampoco alcanza: 57 ciudades aparecen en más de un estado.

### Qué se verificó en cliente

Antes de decidir la clave de `dim_customer` se midió la cardinalidad del código, porque un
`customer_id` ambiguo habría exigido el mismo tratamiento que el producto:

| Comprobación | Resultado |
|---|---|
| `customer_id` con más de un nombre | 0 |
| Nombres de cliente bajo más de un `customer_id` | 0 |
| `customer_id` con más de un segmento | 0 |
| Códigos distintos / nombres distintos / pares | 793 / 793 / 793 |

El código, el nombre y el segmento van siempre juntos, uno a uno: `customer_id` es clave válida y la
dimensión no necesita clave propia. Cliente y producto son casos opuestos, y la diferencia no se
supuso: se midió.

El mismo control mostró que 766 clientes compran en más de una región, y por eso la geografía es un
atributo de la línea de pedido y no del cliente, y que el segmento sí puede colgar del cliente
porque ninguno tiene dos.

### Qué quedó fuera del modelo, a propósito

- **`order_year` y `order_month` en los hechos.** Salen de `dim_date` por la relación. Tenerlos
  también en la tabla de hechos crearía dos fuentes de verdad para el mismo atributo, y con el
  tiempo discreparían.
- **`margin`.** Es una medida, `sum(profit) / sum(sales)`, y se define en DAX. Como columna
  invitaría a promediarla, y ese promedio da 12,47 % en lugar del 12,03 % correcto.
- **`country`.** Tiene un solo valor en todo el dataset: no aporta información.
- **El promedio de `ship_days` dentro de `dim_ship_mode`.** Los días varían línea a línea (de 0 a
  7); un promedio guardado como columna quedaría congelado y no respondería a ningún filtro. Los
  días crudos van en los hechos y el promedio se calcula como medida.

### Comprobaciones de aceptación del modelo

Se ejecutan al final del propio script, sobre las vistas recién creadas:

| Comprobación | Resultado |
|---|---|
| Filas del hecho (contra las del origen) | 9.994 = 9.994 |
| `sum(sales)` | 2.297.200,8603 |
| `sum(profit)` | 286.397,0217 |
| Filas huérfanas en las cinco dimensiones | 0 |
| Días de `dim_date` / días sin huecos | 1.826 / 1.826 |
| Claves distintas por dimensión | iguales al número de filas |
| Línea duplicada (`row_id` 3406 y 3407) | las dos, conservadas |

## Limitaciones conocidas

- El dataset es ficticio y su licencia de redistribución es ambigua. Ver
  [`../data/README.md`](../data/README.md).
- `product_id` no es fiable como identificador de producto.
- La línea duplicada se conserva: si fuera un error del origen, las ventas totales estarían
  sobreestimadas en 281,37, un 0,012 %.
- `postal_code` conserva códigos de 4 dígitos sin rellenar, por decisión explícita.
- El margen de un grupo se calcula siempre como `sum(profit) / sum(sales)`. El promedio de
  los márgenes fila por fila da un resultado distinto, 12,03 % contra 12,47 % sobre el total,
  y es un error frecuente.
- **Los meses no tienen la misma cantidad de días.** Febrero acumula 113 días en los cuatro
  años (2016 fue bisiesto) contra 120 a 124 de los demás meses. Al comparar meses por su
  total, febrero parte en desventaja: una parte de su debilidad en la Q1 es calendario y no
  de negocio.
