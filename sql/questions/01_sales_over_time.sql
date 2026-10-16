-- =====================================================================
-- Q1. ¿Cómo evolucionan las ventas y la utilidad en el tiempo,
--     y en qué meses se concentra el negocio?
--
-- Fuente: analytics.superstore (vista limpia; se crea en sql/03_clean.sql).
--
-- La respuesta está en el README.md del repositorio, sección Q1. Acá no se
-- repite: este archivo dice qué responde cada consulta y cómo se lee el
-- resultado.
--
-- Dos consultas, una por cada mitad de la pregunta:
--   1) por año            -> cómo evoluciona
--   2) por mes calendario -> dónde se concentra
--
-- CÓMO SE LEE EL RESULTADO
--
--   total_sales / total_profit
--       Dólares del año o del mes de esa fila: la suma de sus líneas de pedido.
--
--   margin_pct
--       Margen del grupo, en escala de porcentaje (10,23 se lee 10,23 %).
--       Se calcula como sum(profit) / sum(sales), NUNCA promediando el margen
--       fila por fila: el promedio le da el mismo peso a una línea de 10 dólares
--       que a una de 5.000, y da 12,47 % en lugar de 12,03 % sobre el total.
--
--   sales_var_pct / profit_var_pct
--       Variación contra el año anterior, calculada con LAG. En 2014 salen NULL
--       a propósito: no hay año previo con el que comparar. NULL no es cero.
--
--   sales_share_pct
--       Participación de ese mes en las ventas de los cuatro años. Los doce
--       valores suman 100.
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
