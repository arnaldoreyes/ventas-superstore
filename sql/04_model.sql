-- =====================================================================
-- 04_model.sql
-- Modelo en estrella: dimensiones, tabla de hechos y tabla de fechas.
--
-- Se ejecuta con psql, desde la raíz del repositorio:
--   psql -U analista -d ventas_superstore -f sql/04_model.sql
--
-- Es lo que importa Power BI. Todo son VISTAS: una vista no duplica el
-- almacenamiento y nunca queda desincronizada con analytics.superstore.
--
-- Tiene cuatro partes:
--   PARTE 1  La tabla de fechas.
--   PARTE 2  Las dimensiones.
--   PARTE 3  La tabla de hechos.
--   PARTE 4  Las comprobaciones de aceptación.
--
-- La forma de la estrella. Cada dimensión se relaciona 1 a muchos con
-- los hechos: la clave vive en la dimensión y se repite en el hecho.
--
--      dim_date -------+
--   dim_product -------+
--  dim_customer -------+----> fact_sales    una fila por línea de
-- dim_geography -------+                    pedido (row_id)
-- dim_ship_mode -------+
--
-- Grano del hecho: una fila por línea de pedido. 9.994 filas.
--
-- Tres cosas que el hecho NO lleva, y por qué:
--   * order_year ni order_month: salen de dim_date por la relación. Si
--     estuvieran en los dos lados habría dos fuentes de verdad para el
--     mismo atributo y tarde o temprano discreparían.
--   * margin: es una medida, sum(profit) / sum(sales), y se define en
--     DAX. Como columna alguien la va a promediar y dará 12,47 % en
--     lugar del 12,03 % correcto.
--   * country: es constante en todo el dataset (United States). Una
--     columna con un solo valor no aporta información.
-- =====================================================================

-- Los DROP avisan con un NOTICE cuando la vista todavía no existe: en la
-- primera corrida son seis avisos que ensucian la salida sin ser errores.
SET client_min_messages = warning;

-- Se borra primero el hecho, que depende de las dimensiones. Al revés,
-- PostgreSQL se niega a borrar una dimensión que tiene algo colgando.
DROP VIEW IF EXISTS analytics.fact_sales;
DROP VIEW IF EXISTS analytics.dim_date;
DROP VIEW IF EXISTS analytics.dim_product;
DROP VIEW IF EXISTS analytics.dim_customer;
DROP VIEW IF EXISTS analytics.dim_geography;
DROP VIEW IF EXISTS analytics.dim_ship_mode;


-- =====================================================================
-- PARTE 1. LA TABLA DE FECHAS
-- =====================================================================
-- Un calendario continuo, un día por fila: del 2014-01-01 al 2018-12-31.
--
-- Por qué existe. Es la que habilita la inteligencia de tiempo en DAX
-- (acumulado del año, comparación contra el mismo período del año
-- anterior, etc.). Sin una tabla de fechas marcada como tal, esas
-- funciones no saben que 2016 es bisiesto ni que enero va antes que
-- febrero.
--
-- Por qué ese rango. Los pedidos van del 2014-01-03 al 2017-12-30 y los
-- envíos llegan hasta el 2018-01-05. Los dos extremos se redondean a año
-- completo: un año partido rompe las comparaciones de año contra año.
-- Son 1.826 días y no ocupa nada, porque es una vista.
--
-- generate_series arma la lista de días: no hay una tabla que cargar ni
-- que mantener.
--
-- El nombre del mes va en español porque es un rótulo que se ve en el eje
-- del tablero, y la presentación del proyecto es en español. No se usa
-- to_char(..., 'TMMonth') porque depende del idioma configurado en el
-- servidor: con un CASE el resultado es siempre el mismo.
--
-- month_num está para ordenar. En Power BI el nombre del mes se ordena
-- por su número ("Ordenar por columna"): alfabéticamente, abril, agosto,
-- diciembre no es el orden del calendario.

CREATE OR REPLACE VIEW analytics.dim_date AS
SELECT
    d::date                       AS date,
    extract(year    from d)::int  AS year,
    extract(quarter from d)::int  AS quarter,
    extract(month   from d)::int  AS month_num,
    CASE extract(month from d)
        WHEN  1 THEN 'enero'
        WHEN  2 THEN 'febrero'
        WHEN  3 THEN 'marzo'
        WHEN  4 THEN 'abril'
        WHEN  5 THEN 'mayo'
        WHEN  6 THEN 'junio'
        WHEN  7 THEN 'julio'
        WHEN  8 THEN 'agosto'
        WHEN  9 THEN 'septiembre'
        WHEN 10 THEN 'octubre'
        WHEN 11 THEN 'noviembre'
        WHEN 12 THEN 'diciembre'
    END                           AS month_name,
    to_char(d, 'YYYY-MM')         AS year_month
FROM generate_series(date '2014-01-01', date '2018-12-31', interval '1 day') AS d;

COMMENT ON VIEW analytics.dim_date IS
    'Calendario continuo, un día por fila, del 2014-01-01 al 2018-12-31. Habilita la inteligencia de tiempo en DAX y cubre pedidos y envíos.';


-- =====================================================================
-- PARTE 2. LAS DIMENSIONES
-- =====================================================================

-- ---------------------------------------------------------------------
-- Producto. Necesita clave propia.
-- ---------------------------------------------------------------------
-- product_id NO identifica un producto: 32 códigos apuntan a dos
-- productos distintos y 16 nombres aparecen bajo varios códigos (337
-- filas). La identidad fiable es el par (product_id, product_name), que
-- da 1.894 combinaciones.
--
-- Por eso la dimensión lleva su propia clave, product_key, generada con
-- row_number sobre el par ya ordenado. Se ordena para que la clave sea
-- siempre la misma en cada corrida: una clave que cambiara de un día para
-- otro rompería las relaciones del tablero.
--
-- No se pierde nada: product_id y product_name siguen en la dimensión,
-- así que siempre se puede ver de qué código salió cada producto.
--
-- El DISTINCT es sobre las cuatro columnas. Si un mismo par tuviera dos
-- categorías distintas, saldrían dos filas y la dimensión tendría más de
-- 1.894. Se comprobó que no pasa: cada par tiene una sola categoría y una
-- sola subcategoría.

CREATE OR REPLACE VIEW analytics.dim_product AS
SELECT
    row_number() OVER (ORDER BY product_id, product_name) AS product_key,
    product_id,
    product_name,
    category,
    sub_category
FROM (
    SELECT DISTINCT product_id, product_name, category, sub_category
    FROM analytics.superstore
) AS p;

COMMENT ON VIEW analytics.dim_product IS
    'Producto con categoría y subcategoría. Clave propia product_key: product_id es ambiguo (32 códigos apuntan a dos productos).';


-- ---------------------------------------------------------------------
-- Cliente. NO necesita clave propia.
-- ---------------------------------------------------------------------
-- Antes de decidir la clave se comprobó la cardinalidad del código:
--   793 customer_id distintos, 793 nombres distintos, 793 pares
--   0 códigos con más de un nombre
--   0 nombres bajo más de un código
--   0 códigos con más de un segmento
-- Es decir: el código, el nombre y el segmento van siempre juntos, uno a
-- uno. El customer_id es clave válida y no hay que inventar ninguna.
--
-- El contraste con producto es el punto: la clave no se decide por
-- costumbre, se decide después de mirar el dato.
--
-- El segmento vive acá porque es un atributo del cliente (cada cliente
-- tiene uno solo). La región, en cambio, no puede vivir acá: 766 clientes
-- compran en más de una región, así que la geografía es un atributo de la
-- línea de pedido.

CREATE OR REPLACE VIEW analytics.dim_customer AS
SELECT DISTINCT
    customer_id,
    customer_name,
    segment
FROM analytics.superstore;

COMMENT ON VIEW analytics.dim_customer IS
    'Cliente con su segmento. customer_id es la clave: se verificó que identifica un solo nombre y un solo segmento.';


-- ---------------------------------------------------------------------
-- Geografía. Necesita clave propia.
-- ---------------------------------------------------------------------
-- El lugar no es una columna sino una combinación: región, estado, ciudad
-- y código postal. Y no se puede relacionar por cuatro columnas a la vez
-- (Power BI relaciona por una sola), así que la dimensión lleva su propia
-- clave, geography_key.
--
-- Por qué entra el código postal: (state, city) da 604 combinaciones
-- únicas, pero (state, city, postal_code) da 632. O sea que 28 lugares
-- distintos se llaman igual dentro del mismo estado y solo el código
-- postal los separa. La ciudad sola tampoco sirve: 57 ciudades aparecen
-- en más de un estado.
--
-- La región queda determinada por el estado (ningún estado está en dos
-- regiones), pero se guarda igual porque es el nivel al que pregunta la
-- Q6. No rompe la clave: no agrega ni una fila.
--
-- country no entra: tiene un solo valor en todo el dataset.

CREATE OR REPLACE VIEW analytics.dim_geography AS
SELECT
    row_number() OVER (ORDER BY region, state, city, postal_code) AS geography_key,
    region,
    state,
    city,
    postal_code
FROM (
    SELECT DISTINCT region, state, city, postal_code
    FROM analytics.superstore
) AS g;

COMMENT ON VIEW analytics.dim_geography IS
    'Región, estado, ciudad y código postal. Clave propia geography_key: el lugar es una combinación de cuatro columnas y Power BI relaciona por una.';


-- ---------------------------------------------------------------------
-- Modo de envío. La dimensión más chica: cuatro filas.
-- ---------------------------------------------------------------------
-- Existe para que el modo de envío sea un atributo descriptivo y no una
-- columna de texto suelta dentro del hecho, y para tener un filtro limpio
-- en el tablero.
--
-- Acá NO va el promedio de días de despacho, aunque la Q6 pregunte por el
-- modo de envío "con sus días de despacho". Los días varían línea a línea
-- (de 0 a 7). Un promedio guardado como columna quedaría congelado: no
-- cambiaría al filtrar por región o por año, y respondería a la pregunta
-- equivocada. Los días crudos van en el hecho (ship_days) y el promedio
-- se calcula como medida en DAX.

CREATE OR REPLACE VIEW analytics.dim_ship_mode AS
SELECT DISTINCT ship_mode
FROM analytics.superstore;

COMMENT ON VIEW analytics.dim_ship_mode IS
    'Modo de envío (4 filas). Sin el promedio de días de despacho: es una medida, no un atributo.';


-- =====================================================================
-- PARTE 3. LA TABLA DE HECHOS
-- =====================================================================
-- Una fila por línea de pedido, una por row_id: 9.994 filas.
--
-- Lleva tres cosas y nada más:
--   1) las claves que la relacionan con cada dimensión;
--   2) los identificadores del pedido (order_id) y de la línea (row_id),
--      que no son entidades y por eso no tienen dimensión propia;
--   3) las medidas: sales, quantity, discount, profit y ship_days.
--
-- Los dos identificadores se quedan por motivos concretos:
--   order_id  para poder contar pedidos (la frecuencia de la Q4);
--   row_id    para poder rastrear cualquier línea hasta el archivo
--             original, incluida la línea duplicada (row_id 3406 y 3407)
--             que se decidió conservar.
--
-- Los JOIN contra dim_product y dim_geography son INNER a propósito: son
-- las dos únicas dimensiones de las que el hecho saca una clave generada.
-- Si un producto o un lugar no apareciera en su dimensión, esa línea
-- desaparecería del hecho y el total dejaría de dar 9.994. La PARTE 4 lo
-- comprueba.
--
-- Contra dim_customer, dim_ship_mode y dim_date no hace falta JOIN: el
-- hecho ya trae la clave natural (customer_id, ship_mode, order_date) y
-- esas dimensiones se construyen con un DISTINCT del mismo origen, así
-- que la correspondencia está garantizada por construcción. La PARTE 4 la
-- verifica igual.
--
-- ship_date viaja a los hechos, todavía sin relación: la tabla de fechas
-- llega hasta el 2018-12-31 justamente para que esa relación pueda existir
-- el día que una pregunta necesite analizar los envíos en el tiempo. La
-- inteligencia de tiempo de este proyecto se apoya en order_date, y por
-- eso order_date es la clave que se relaciona con dim_date.

CREATE OR REPLACE VIEW analytics.fact_sales AS
SELECT
    s.row_id,
    s.order_id,
    s.order_date,
    s.ship_date,
    p.product_key,
    s.customer_id,
    g.geography_key,
    s.ship_mode,
    s.sales,
    s.quantity,
    s.discount,
    s.profit,
    s.ship_days
FROM analytics.superstore AS s
JOIN analytics.dim_product   AS p
  ON p.product_id   = s.product_id
 AND p.product_name = s.product_name
JOIN analytics.dim_geography AS g
  ON g.region      = s.region
 AND g.state       = s.state
 AND g.city        = s.city
 AND g.postal_code = s.postal_code;

COMMENT ON VIEW analytics.fact_sales IS
    'Tabla de hechos: una fila por línea de pedido (row_id), 9.994 filas. Claves de las cinco dimensiones más las medidas sales, quantity, discount, profit y ship_days.';


-- =====================================================================
-- PARTE 4. LAS COMPROBACIONES DE ACEPTACIÓN
-- =====================================================================
-- El modelo no está listo si alguna de estas falla.
--
--   1. El hecho tiene 9.994 filas ................ 9994 = 9994
--   2. Los totales no cambiaron .................. 2297200.8603 y 286397.0217
--   3. Cero filas huérfanas ...................... 0 en las cinco columnas
--   4. La tabla de fechas es continua ............ 1826 días, sin huecos
--   5. Cada clave de dimensión es única .......... iguales las dos columnas
--   6. La línea duplicada sigue ahí .............. 2 filas (3406 y 3407)

-- 1. Filas del hecho contra filas del origen. Si el JOIN contra producto
--    o contra geografía hubiera dejado alguna línea afuera, la primera
--    columna daría menos que la segunda.
SELECT
    (SELECT count(*) FROM analytics.fact_sales)  AS fact_rows,
    (SELECT count(*) FROM analytics.superstore)  AS source_rows;

-- 2. Los totales del hecho, que tienen que ser los verificados del
--    dataset. Es la comprobación de que el modelo no sumó ni perdió nada.
SELECT
    sum(sales)  AS total_sales,
    sum(profit) AS total_profit
FROM analytics.fact_sales;

-- 3. Cero filas huérfanas: ninguna línea del origen se queda sin
--    correspondencia en alguna de las cinco dimensiones. Se parte del
--    origen (no del hecho) y se busca con LEFT JOIN: donde no hay
--    correspondencia, la clave de la dimensión queda en NULL.
--    La última columna repite el conteo del origen: si un JOIN hubiera
--    duplicado filas, subiría por encima de 9.994.
SELECT
    count(*) FILTER (WHERE p.product_key   IS NULL) AS sin_producto,
    count(*) FILTER (WHERE c.customer_id   IS NULL) AS sin_cliente,
    count(*) FILTER (WHERE g.geography_key IS NULL) AS sin_geografia,
    count(*) FILTER (WHERE m.ship_mode     IS NULL) AS sin_modo_envio,
    count(*) FILTER (WHERE d.date          IS NULL) AS sin_fecha,
    count(*)                                        AS filas_del_origen
FROM analytics.superstore AS s
LEFT JOIN analytics.dim_product   AS p
       ON p.product_id   = s.product_id
      AND p.product_name = s.product_name
LEFT JOIN analytics.dim_customer  AS c ON c.customer_id = s.customer_id
LEFT JOIN analytics.dim_geography AS g
       ON g.region      = s.region
      AND g.state       = s.state
      AND g.city        = s.city
      AND g.postal_code = s.postal_code
LEFT JOIN analytics.dim_ship_mode AS m ON m.ship_mode = s.ship_mode
LEFT JOIN analytics.dim_date      AS d ON d.date = s.order_date;

-- 4. La tabla de fechas es continua y cubre todo el rango del dato.
--    days y days_without_gaps tienen que coincidir: si days fuera menor,
--    habría días faltantes en el medio. first_day tiene que alcanzar al
--    primer pedido y last_day al último envío.
SELECT
    min(date)                   AS first_day,
    max(date)                   AS last_day,
    count(*)                    AS days,
    (max(date) - min(date) + 1) AS days_without_gaps,
    (SELECT min(order_date) FROM analytics.superstore) AS first_order,
    (SELECT max(order_date) FROM analytics.superstore) AS last_order,
    (SELECT max(ship_date)  FROM analytics.superstore) AS last_ship
FROM analytics.dim_date;

-- 5. Cada dimensión tiene tantas filas como claves distintas: la clave
--    identifica una fila y solo una. Es lo que garantiza que los JOIN no
--    puedan multiplicar filas, y en el hecho confirma que el grano es una
--    línea por row_id.
SELECT 'dim_date'     AS dimension, count(*) AS rows, count(DISTINCT date)          AS keys FROM analytics.dim_date
UNION ALL SELECT 'dim_product',   count(*), count(DISTINCT product_key)   FROM analytics.dim_product
UNION ALL SELECT 'dim_customer',  count(*), count(DISTINCT customer_id)   FROM analytics.dim_customer
UNION ALL SELECT 'dim_geography', count(*), count(DISTINCT geography_key) FROM analytics.dim_geography
UNION ALL SELECT 'dim_ship_mode', count(*), count(DISTINCT ship_mode)     FROM analytics.dim_ship_mode
UNION ALL SELECT 'fact_sales',    count(*), count(DISTINCT row_id)        FROM analytics.fact_sales;

-- 6. La línea duplicada se conserva. row_id 3406 y 3407 son la misma
--    línea de negocio (pedido US-2014-150119). No se filtró: si el modelo
--    la eliminara, los totales dejarían de coincidir con los verificados.
SELECT row_id, order_id, sales, quantity, discount, profit
FROM analytics.fact_sales
WHERE row_id IN (3406, 3407)
ORDER BY row_id;
