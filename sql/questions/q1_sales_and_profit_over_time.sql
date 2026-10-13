-- =====================================================================
-- Q1. ¿Cómo evolucionan las ventas y la utilidad en el tiempo,
--     y en qué meses se concentra el negocio?
--
-- Fuente: analytics.superstore (vista limpia; se crea en sql/03_clean.sql).
--
-- Dos consultas, una por cada mitad de la pregunta:
--   1) por año            -> cómo evoluciona
--   2) por mes calendario -> dónde se concentra
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Evolución por año
-- ---------------------------------------------------------------------
SELECT
    order_year,
    round(sum(sales), 2)  AS total_sales,
    round(sum(profit), 2) AS total_profit,
    round(sum(profit) / sum(sales) * 100, 2) AS margin_pct,
    round((sum(sales) - lag(sum(sales)) over (order by order_year))
          / lag(sum(sales)) over (order by order_year) * 100, 2) AS sales_var_pct,
    round((sum(profit) - lag(sum(profit)) over (order by order_year))
          / lag(sum(profit)) over (order by order_year) * 100, 2) AS profit_var_pct
FROM analytics.superstore
GROUP BY order_year
ORDER BY order_year;

-- ---------------------------------------------------------------------
-- 2. Concentración por mes calendario (los cuatro años sumados)
-- ---------------------------------------------------------------------
SELECT
    order_month,
    round(sum(sales), 2)  AS total_sales,
    round(sum(profit), 2) AS total_profit,
    round(sum(profit) / sum(sales) * 100, 2) AS margin_pct,
    round(sum(sales) / (SELECT sum(sales) FROM analytics.superstore) * 100, 2) AS sales_share_pct
FROM analytics.superstore
GROUP BY order_month
ORDER BY order_month;

-- =====================================================================
-- RESPUESTA
--
-- EVOLUCIÓN. Las ventas pasan de 484.247,50 (2014) a 733.215,26 (2017), pero no
-- en línea recta: caen 2,83 % en 2015 y se recuperan con fuerza en 2016 (+29,47 %).
-- La utilidad sube los tres años y siempre por encima de las ventas: en 2015 las
-- ventas cayeron y la utilidad creció 24,37 %. El margen pasó de 10,23 % a 13,43 %
-- y cerró en 12,74 %.
--
-- CONCENTRACIÓN. El negocio se concentra en el último tercio del año. Noviembre
-- (15,34 %) y diciembre (14,16 %) solos reúnen el 29,50 % de las ventas del período;
-- sumando septiembre, el 42,89 %. Enero (4,13 %) y febrero (2,60 %) son los meses
-- más flojos: juntos aportan el 6,73 %.
--
-- CRUCE DE LAS DOS LECTURAS. Los meses de mayor venta no son los de mejor margen.
-- Noviembre, el mes que más vende, está entre los cuatro peores márgenes (10,06 %);
-- febrero, el que menos vende, tiene el mejor (17,23 %). La temporada alta concentra
-- el volumen, no la rentabilidad.
-- =====================================================================