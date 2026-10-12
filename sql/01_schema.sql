-- =====================================================================
-- 01_schema.sql
-- Crea los esquemas y la tabla cruda donde se carga el CSV sin transformar.
--
-- Ejecutar con psql, desde la raíz del repositorio:
--   psql -U <usuario> -d ventas_superstore -f sql/01_schema.sql
--
-- Capas:
--   raw       -> copia fiel del archivo original. No se modifica.
--   analytics -> todo lo derivado: limpieza, validaciones y respuestas.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS analytics;

DROP TABLE IF EXISTS raw.superstore;

-- Sobre los tipos:
--   * postal_code es text y no integer: es un identificador. Como número perdería
--     los ceros a la izquierda de algunos códigos postales de EE.UU.
--   * sales y profit son numeric(12,4) y no float: con dinero no se usa punto
--     flotante, porque acumula error de redondeo al sumar miles de filas.
--     Los cuatro decimales vienen del propio archivo.
--   * discount es numeric(4,2): es una fracción entre 0 y 1, no un porcentaje.
--
-- Sobre las restricciones: esta capa NO impone reglas de negocio (nada de NOT NULL
-- ni CHECK). Solo tipos. La idea es que la carga refleje el archivo tal como es y que
-- las reglas se apliquen y se documenten más arriba, en analytics. Si la tabla cruda
-- rechazara filas, se perdería la evidencia de que el archivo venía mal.
CREATE TABLE raw.superstore (
    row_id        integer       PRIMARY KEY,
    order_id      text          NOT NULL,
    order_date    date          NOT NULL,
    ship_date     date          NOT NULL,
    ship_mode     text,
    customer_id   text,
    customer_name text,
    segment       text,
    country       text,
    city          text,
    state         text,
    postal_code   text,
    region        text,
    product_id    text,
    category      text,
    sub_category  text,
    product_name  text,
    sales         numeric(12,4),
    quantity      integer,
    discount      numeric(4,2),
    profit        numeric(12,4)
);

COMMENT ON TABLE  raw.superstore IS
    'Copia fiel de data/raw/superstore.csv. No se modifica: la limpieza vive en el esquema analytics.';
COMMENT ON COLUMN raw.superstore.row_id IS
    'Número de fila del archivo original (1..9994). Es la clave primaria porque la clave natural (order_id, product_id) no es única: un pedido puede repetir el mismo producto con descuentos distintos.';
COMMENT ON COLUMN raw.superstore.order_date IS
    'Fecha del pedido. En el archivo viene como M/D/YYYY.';
COMMENT ON COLUMN raw.superstore.ship_date IS
    'Fecha de despacho. Debe ser siempre posterior o igual a order_date.';
COMMENT ON COLUMN raw.superstore.postal_code IS
    'Identificador postal, guardado como texto para no perder ceros a la izquierda.';
COMMENT ON COLUMN raw.superstore.sales IS
    'Importe de la línea, en dólares.';
COMMENT ON COLUMN raw.superstore.quantity IS
    'Unidades vendidas en la línea.';
COMMENT ON COLUMN raw.superstore.discount IS
    'Descuento aplicado, como fracción entre 0 y 1.';
COMMENT ON COLUMN raw.superstore.profit IS
    'Utilidad de la línea, en dólares. Puede ser negativa.';

-- Comprobación de que la estructura quedó como se espera.
SELECT table_schema, table_name,
       (SELECT count(*) FROM information_schema.columns c
         WHERE c.table_schema = t.table_schema AND c.table_name = t.table_name) AS columnas
FROM information_schema.tables t
WHERE table_schema IN ('raw', 'analytics')
ORDER BY 1, 2;
