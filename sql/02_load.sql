-- =====================================================================
-- 02_load.sql
-- Carga data/raw/superstore.csv en raw.superstore.
--
-- Ejecutar SIEMPRE con psql y desde la raíz del repositorio:
--   psql -U <usuario> -d ventas_superstore -f sql/02_load.sql
--
-- Por qué \copy y no COPY:
--   COPY lee el archivo desde el servidor de base de datos; \copy lo lee desde
--   el cliente, que es donde está el repositorio. Además \copy es un
--   meta-comando de psql: no existe en otros clientes SQL.
--   La ruta del archivo es relativa al directorio desde el que se ejecuta psql.
-- =====================================================================

-- Las fechas del archivo vienen como M/D/YYYY (mes primero). Sin fijar esto, la
-- misma fecha puede leerse como 8 de noviembre o como 11 de agosto según la
-- configuración de la sesión, y el error es silencioso.
SET DateStyle = 'MDY';

TRUNCATE raw.superstore;

-- ENCODING 'WIN1252': el archivo no es UTF-8 válido. Tiene 624 caracteres no ASCII
-- (espacio duro, comillas tipográficas, vocales acentuadas). Sin esta opción la
-- carga falla o deforma los nombres de producto y de cliente.
--
-- NULL '': un campo vacío se interpreta como NULL y no como cadena vacía. Se evita
-- así el clásico '' que rompe los conteos y los promedios más adelante.
\copy raw.superstore (row_id, order_id, order_date, ship_date, ship_mode, customer_id, customer_name, segment, country, city, state, postal_code, region, product_id, category, sub_category, product_name, sales, quantity, discount, profit) FROM 'data/raw/superstore.csv' WITH (FORMAT csv, HEADER true, ENCODING 'WIN1252', NULL '')

-- =====================================================================
-- Verificación de la carga.
-- Contraste contra los valores canónicos del dataset documentados en data/README.md.
-- Si estos números no salen, la carga está mal y no tiene sentido seguir.
-- =====================================================================
SELECT count(*)                 AS filas,            -- esperado: 9994
       sum(sales)               AS ventas_totales,   -- esperado: 2297200.8603
       sum(profit)              AS utilidad_total,   -- esperado: 286397.0217
       count(DISTINCT order_id) AS pedidos,          -- esperado: 5009
       count(DISTINCT customer_id) AS clientes,      -- esperado: 793
       min(order_date)          AS primer_pedido,    -- esperado: 2014-01-03
       max(order_date)          AS ultimo_pedido     -- esperado: 2017-12-30
FROM raw.superstore;
