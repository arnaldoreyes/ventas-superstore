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
filtro escrito a mano, un `BUSCARV` de Excel o una relación de Power BI por nombre fallarían
en silencio, devolviendo cero filas en lugar de un error.

### 3. Espacios en los extremos de `product_name` — 16 filas

Tres productos tienen el nombre terminado en un espacio en el 100% de sus filas. Se recortan
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

- **Los márgenes negativos.** 1.871 líneas (18,7%) cierran con utilidad negativa. No son un
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

## Limitaciones conocidas

- El dataset es ficticio y su licencia de redistribución es ambigua. Ver
  [`../data/README.md`](../data/README.md).
- `product_id` no es fiable como identificador de producto.
- La línea duplicada se conserva: si fuera un error del origen, las ventas totales estarían
  sobreestimadas en 281,37, un 0,012%.
- `postal_code` conserva códigos de 4 dígitos sin rellenar, por decisión explícita.
- El margen de un grupo se calcula siempre como `sum(profit) / sum(sales)`. El promedio de
  los márgenes fila por fila da un resultado distinto, 12,03% contra 12,47% sobre el total,
  y es un error frecuente.
