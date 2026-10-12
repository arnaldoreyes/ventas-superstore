# Preguntas del proyecto

Seis preguntas principales. Cada una se responde con una escalera de máximo 5 escalones,
todos al servicio de esa pregunta y nada más. Cada escalón se materializa como una vista en
el esquema `analytics`, de modo que la respuesta se pueda seguir paso a paso y no como un
bloque de SQL imposible de auditar.

Regla de cierre: cada pregunta termina con (a) su script en `sql/questions/`, (b) su página
en `powerbi/ventas_superstore.pbix`, (c) su tabla dinámica en `excel/`, y (d) su
interpretación escrita en `docs/respuestas/`.

---

## Q1. ¿Cómo evolucionan las ventas y la utilidad en el tiempo, y en qué meses se concentra el negocio?

1. Ventas por mes.
2. Utilidad y margen porcentual por mes.
3. Comparación año contra año.
4. Variación porcentual mes a mes.
5. Estacionalidad por mes calendario, agregando los cuatro años.

Conceptos: `GROUP BY`, `date_trunc`, CTE, `LAG`.

---

## Q2. ¿Qué categorías y subcategorías venden y cuáles destruyen margen?

1. Ventas por categoría.
2. Ventas por subcategoría.
3. Margen porcentual por subcategoría.
4. Ranking de subcategorías dentro de cada categoría.
5. Subcategorías con utilidad negativa.

Conceptos: `GROUP BY` múltiple, `HAVING`, `RANK() OVER`.

---

## Q3. ¿En qué punto el descuento deja de convenir?

1. Pedidos por banda de descuento.
2. Ticket promedio y ventas por banda.
3. Margen porcentual por banda.
4. Primera banda con margen negativo.
5. Subcategorías donde el descuento es más destructivo.

Conceptos: `CASE`, agregación condicional, subconsultas.
Es la pregunta más fuerte del proyecto: cruza política comercial con resultado económico.

---

## Q4. ¿Quiénes son los clientes más valiosos y cómo se reparte el negocio por segmento?

1. Ventas y margen por segmento.
2. Recencia, frecuencia y monto por cliente.
3. Quintiles con `NTILE`.
4. Conteo y valor por combinación RFM.
5. Los 10 clientes de mayor valor con su perfil.

Conceptos: `NTILE`, CTE encadenadas, agregación por entidad.

---

## Q5. ¿Cuántos productos y cuántos clientes explican el 80% de las ventas?

1. Ventas por producto, ordenadas de mayor a menor.
2. Ventas acumuladas.
3. Porcentaje acumulado sobre el total.
4. Cuántos productos cruzan el 80%.
5. Lo mismo para clientes, y comparación entre ambos.

Conceptos: `SUM() OVER (ORDER BY ...)`, `NULLIF`, proporciones.

---

## Q6. ¿Qué regiones y estados rinden, y qué explica a los que no rinden?

1. Ventas y margen por región.
2. Los 10 mejores y los 10 peores estados.
3. Margen porcentual por estado.
4. Días de despacho promedio por modo de envío y por región.
5. Cruce de descuento promedio y demora, para ver cuál explica el mal margen.

Conceptos: diferencia de fechas, cruce de vistas, diagnóstico.
Es la pregunta de cierre porque usa todo lo anterior.
