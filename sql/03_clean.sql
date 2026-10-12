-- =====================================================================
-- 03_clean.sql
-- Limpieza del texto y capa derivada del proyecto.
--
-- Se ejecuta con psql, desde la raiz del repositorio:
--   psql -U analista -d ventas_superstore -f sql/03_clean.sql
--
-- Tiene tres partes:
--   PARTE 1  Mostrar el problema antes de arreglarlo.
--   PARTE 2  Crear la vista limpia analytics.superstore.
--   PARTE 3  Comprobar que quedo bien.
-- =====================================================================


-- =====================================================================
-- PARTE 1. EL PROBLEMA, ANTES DE ARREGLARLO
-- =====================================================================
-- Pregunta: cuantos nombres de producto traen el espacio invisible?
-- El espacio invisible se escribe chr(160). Se ve igual que un espacio
-- normal en pantalla, asi que la unica forma de detectarlo es preguntarle
-- a la base si el texto lo contiene.
--
-- Respuesta esperada: 225.
--
-- Escribe tu consulta aqui abajo. Tiene que devolver un solo numero.


SELECT COUNT(*)
FROM raw.superstore
WHERE product_name LIKE '%' || chr(160) || '%';


-- =====================================================================
-- PARTE 2. LA VISTA LIMPIA
-- =====================================================================
-- Una vista es una consulta guardada con nombre. No copia los datos ni
-- ocupa espacio: cada vez que la usas, la base la vuelve a calcular.
--
-- Tiene que llamarse analytics.superstore y salir de raw.superstore.
--
-- Columnas que debe entregar:
--   las mismas 21 del original, con product_name ya limpio
--   + order_year   el anio del pedido, como numero
--   + order_month  el mes del pedido, de 1 a 12
--   + order_ym     el anio y el mes juntos, para agrupar por mes
--   + ship_days    cuantos dias demoro el envio
--   + margin       la utilidad dividida por las ventas
--
-- Arreglos de texto, en este orden:
--   1) cambiar el espacio invisible por uno normal
--   2) recien despues, sacar los espacios sobrantes de los extremos
--   El orden importa: sacar espacios NO quita el espacio invisible.


CREATE OR REPLACE VIEW analytics.superstore AS
SELECT
	row_id, 
	order_id, 
	order_date, 
	ship_date, 
	ship_mode, 
	customer_id, 
	customer_name, 
	segment, 
	country, 
	city, 
	state, 
	postal_code, 
	region, 
	product_id,
	category, 
	sub_category, 
	btrim(replace(product_name, chr(160), ' ')) AS product_name, 
	sales, 
	quantity, 
	discount, 
	profit,
    extract(year from order_date)::int   AS order_year, 
    extract(month from order_date)::int  AS order_month, 
    date_trunc('month', order_date)::date AS order_ym, 
    (ship_date - order_date)             AS ship_days,
    profit / nullif(sales, 0)            AS margin
FROM raw.superstore;

-- =====================================================================
-- PARTE 3. LA COMPROBACION
-- =====================================================================
-- Cada consulta de aqui tiene que devolver 0, salvo las dos ultimas.
--
--   nombres con espacio invisible .......... 0
--   nombres con espacios en los extremos ... 0
--   envios antes del pedido ................ 0
--   cantidad de filas ...................... 9994
--   suma de sales .......................... 2297200.8603


-- 1. No quedan espacios invisibles.
SELECT count(*) AS quedan_espacios_invisibles
FROM analytics.superstore
WHERE product_name LIKE '%' || chr(160) || '%';

-- 2. Nombres con espacios en los extremos
SELECT count(*) AS quedan_espacios_extremos
FROM analytics.superstore
WHERE product_name <> btrim(product_name);

-- 3. Numero de filas
SELECT count(*)  AS filas FROM analytics.superstore;

-- 4. Suma de sales

SELECT sum(sales) AS ventas_totales FROM analytics.superstore;

-- 5. No hay envios anteriores al pedido.
SELECT count(*) AS envios_antes_del_pedido
FROM analytics.superstore
WHERE ship_date < order_date;
