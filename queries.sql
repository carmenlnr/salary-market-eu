-- ------------------------------
-- SETUP: base de datos y esquema
-- ------------------------------

-- 1. Crear base de datos
CREATE DATABASE IF NOT EXISTS salary_market_eu;
USE salary_market_eu;

-- 2. las tablas ofertas, salarios e historico se han cargado desde py con to_sql

-- 3. Crear tablas catalogo de paises
CREATE TABLE paises (
    pais VARCHAR(5) PRIMARY KEY,
    nombre_pais VARCHAR(50)
);

INSERT INTO paises (pais, nombre_pais) VALUES
('es', 'España'),
('gb', 'Reino Unido'),
('fr', 'Francia'),
('de', 'Alemania'),
('nl', 'Paises Bajos'),
('us', 'Estados Unidos');

SELECT * FROM paises;

-- 4. Crear la tabla catalogo de sectores
CREATE TABLE sectores (
    sector VARCHAR(20) PRIMARY KEY,
    descripcion VARCHAR(100)
);

INSERT INTO sectores (sector, descripcion) VALUES
('IT', 'Tecnologia e informatica'),
('Finance', 'Contabilidad y finanzas'),
('Retail', 'Comercio y tiendas'),
('Logistics', 'Logistica y almacen');

SELECT * FROM sectores;

-- 5. Conectamos ofertas con los catalogos paises y sectores
-- Cambiamos pais y sector de TEXT a VARCHAR para poder usarlos en foreign keys
ALTER TABLE ofertas MODIFY pais VARCHAR(5);
ALTER TABLE ofertas MODIFY sector VARCHAR(20);

ALTER TABLE ofertas
ADD FOREIGN KEY (pais) REFERENCES paises(pais);

ALTER TABLE ofertas
ADD FOREIGN KEY (sector) REFERENCES sectores(sector);

-- salarios: cambiamos tipos y añadimos foreign keys
ALTER TABLE salarios MODIFY pais VARCHAR(5);
ALTER TABLE salarios MODIFY sector VARCHAR(20);

ALTER TABLE salarios ADD FOREIGN KEY (pais) REFERENCES paises(pais);
ALTER TABLE salarios ADD FOREIGN KEY (sector) REFERENCES sectores(sector);

-- historico: cambiamos tipos y añadimos foreign keys
ALTER TABLE historico MODIFY pais VARCHAR(5);
ALTER TABLE historico MODIFY sector VARCHAR(20);

ALTER TABLE historico ADD FOREIGN KEY (pais) REFERENCES paises(pais);
ALTER TABLE historico ADD FOREIGN KEY (sector) REFERENCES sectores(sector);

-- ------------------------------
-- ANALISIS
-- ------------------------------

-- 1. Salario medio por pais (en euros)
SELECT
	pais,
    ROUND(AVG(salary_min),0) AS salario_medio
FROM salarios
GROUP BY pais
ORDER BY salario_medio DESC;

-- 1b. Comprobación: número de ofertas y rango salarial por país
SELECT 
    pais,
    COUNT(*) AS num_ofertas,
    ROUND(MIN(salary_min), 0) AS salario_min,
    ROUND(MAX(salary_min), 0) AS salario_max,
    ROUND(AVG(salary_min), 0) AS salario_medio
FROM salarios
GROUP BY pais
ORDER BY salario_medio DESC;

-- 2. Salario medio por sector
SELECT 
    sector,
    COUNT(*) AS num_ofertas,
    ROUND(AVG(salary_min), 0) AS salario_medio
FROM salarios
GROUP BY sector
ORDER BY salario_medio DESC;

-- 3. Salario medio por pais y sector
SELECT 
    pais,
    sector,
    COUNT(*) AS num_ofertas,
    ROUND(AVG(salary_min), 0) AS salario_medio
FROM salarios
GROUP BY pais, sector
ORDER BY pais, salario_medio DESC;

-- 4. Porcentaje de ofertas que publican salario, por pais
SELECT 
    pais,
    COUNT(*) AS total_ofertas,
    COUNT(salary_min) AS con_salario,
    ROUND(COUNT(salary_min) / COUNT(*) * 100, 2) AS porcentaje_con_salario
FROM ofertas
GROUP BY pais
ORDER BY porcentaje_con_salario DESC;

-- 5. Volumen de ofertas (demanda) por pais y sector
SELECT 
    pais,
    sector,
    COUNT(*) AS num_ofertas
FROM ofertas
GROUP BY pais, sector
ORDER BY num_ofertas DESC;

-- NOTA: casi todas las combinaciones tienen 400 ofertas porque en la recogida limitamos a 8 paginas (400 ofertas) por pais y sector. 
-- Por eso este dato NO mide la demanda real del mercado, solo refleja el tope de recogida.
-- El unico dato util es que España tiene menos oferta en Retail (88) y Finance (368). 
-- Medir la demanda real sin limite de paginas queda como proximo paso.

-- Vemos la estructura del historico (un pais y sector concreto, en orden)
SELECT pais, sector, mes, salario_medio
FROM historico
WHERE pais = 'es' AND sector = 'IT'
ORDER BY mes;

-- 6. Evolucion mensual del salario en España IT, con variacion respecto al mes anterior
SELECT 
    mes,
    salario_medio,
    LAG(salario_medio) OVER (ORDER BY mes) AS mes_anterior,
    salario_medio - LAG(salario_medio) OVER (ORDER BY mes) AS variacion
FROM historico
WHERE pais = 'es' AND sector = 'IT'
ORDER BY mes;

-- Usamos la window function LAG para traer el salario del mes anterior en cada fila y calcular la variacion. Ejemplo con España IT.
-- NOTA: se detecta una caida anomala en 2026-03 (de 83.000 a 45.000), probablemente por un cambio en como la fuente (Adzuna)
-- calcula la media ese mes. Se señala como limitacion.

-- 6a. Evolucion mensual de todas las combinaciones pais+sector (para el dashboard)
SELECT 
    pais,
    sector,
    mes,
    salario_medio,
    LAG(salario_medio) OVER (PARTITION BY pais, sector ORDER BY mes) AS mes_anterior,
    salario_medio - LAG(salario_medio) OVER (PARTITION BY pais, sector ORDER BY mes) AS variacion
FROM historico
ORDER BY pais, sector, mes;

-- Evolucion mensual de TODAS las combinaciones pais+sector (LAG con PARTITION BY) Se usa PARTITION BY pais, 
-- sector para que LAG calcule la variacion por separado en cada serie, sin mezclar paises ni sectores. 
-- Esta es la version para el dashboard.
-- NOTA: el historico de Adzuna es inestable y tiene anomalias puntuales (caidas bruscas en marzo 2026 en algunos sectores, 
-- picos poco realistas como USA Logistics llegando a 186k).
-- Son medias de ofertas, no salarios oficiales estables. Para tendencias usaremos las series mas estables (ejemplo: UK IT) y 
-- se menciona esta inestabilidad como limitacion.

-- 7. Mediana de salario
-- Numeramos los salarios de cada pais ordenados de menor a mayor
SELECT 
    pais,
    salary_min,
    ROW_NUMBER() OVER (PARTITION BY pais ORDER BY salary_min) AS posicion,
    COUNT(*) OVER (PARTITION BY pais) AS total
FROM salarios
WHERE pais = 'es'
ORDER BY salary_min;

-- Comentario: paso intermedio para entender la mediana: numeramos los salarios de España, ordenados de menor a mayor (ROW_NUMBER) y 
-- contamos el total de ofertas (COUNT OVER). Asi cada salario tiene una posicion en la lista ordenada. La mediana es el valor que 
-- ocupa la posicion central: con 215 ofertas, la posicion central es la 108, que corresponde a un salario de 35.000 €.
-- Si se compara la media de España es 40.034 € pero la mediana es 35.000 €.
-- La media es mas alta porque los salarios muy altos (90k, 120k, 150k) la inflan.
-- La mediana representa mejor el salario "tipico", por eso conviene mirar las dos

-- 7b. Mediana del salario por pais
-- Primero numeramos los salarios ordenados (subconsulta), luego nos quedamos con el del medio
SELECT 
    pais,
    salary_min AS mediana
FROM (
    SELECT 
        pais,
        salary_min,
        ROW_NUMBER() OVER (PARTITION BY pais ORDER BY salary_min) AS posicion,
        COUNT(*) OVER (PARTITION BY pais) AS total
    FROM salarios
) AS subconsulta
WHERE posicion = ROUND(total / 2)
ORDER BY mediana DESC;


-- 8. Ranking de sectores por salario medio dentro de cada pais
SELECT 
    pais,
    sector,
    ROUND(AVG(salary_min), 0) AS salario_medio,
    RANK() OVER (PARTITION BY pais ORDER BY AVG(salary_min) DESC) AS ranking
FROM salarios
GROUP BY pais, sector
ORDER BY pais, ranking;

-- RANK asigna el puesto (1=mejor pagado) a cada sector dentro de su pais.
-- Insight: el sector mejor pagado varia segun el pais. En UK, USA y Francia lidera IT; en España, Alemania y Paises Bajos lidera Finance.
-- NOTA: Alemania solo muestra 3 sectores porque IT tiene muy pocas ofertas con salario (muestra pequeña).

-- 9. Salario medio y mediano por nivel (senior, junior, no especificado)
SELECT 
    nivel,
    COUNT(*) AS num_ofertas,
    ROUND(AVG(salary_min), 0) AS salario_medio
FROM salarios
GROUP BY nivel
ORDER BY salario_medio DESC;

-- 10. Sectores que pagan por encima de la media de su pais (usando CTE, JOIN y HAVING)
WITH medias_pais AS (
    SELECT 
        pais,
        ROUND(AVG(salary_min), 0) AS media_pais
    FROM salarios
    GROUP BY pais
)
SELECT 
    s.pais,
    s.sector,
    ROUND(AVG(s.salary_min), 0) AS salario_sector,
    m.media_pais
FROM salarios s
JOIN medias_pais m ON s.pais = m.pais
GROUP BY s.pais, s.sector, m.media_pais
HAVING salario_sector > m.media_pais
ORDER BY s.pais, salario_sector DESC;

-- La CTE 'medias_pais' calcula la media general de cada pais (sin desglosar por sector).
-- Luego unimos (JOIN) cada sector con la media de su pais y con HAVING nos quedamos solo con los que la superan.
-- Insight: IT y Finance son los sectores que casi siempre superan la media del pais.alter


-- 11. Mediana del salario por pais y sector (CTE + ROW_NUMBER)
WITH numerados AS (
    SELECT 
        pais,
        sector,
        salary_min,
        ROW_NUMBER() OVER (PARTITION BY pais, sector ORDER BY salary_min) AS posicion,
        COUNT(*) OVER (PARTITION BY pais, sector) AS total
    FROM salarios
)
SELECT 
    pais,
    sector,
    salary_min AS mediana,
    total AS num_ofertas
FROM numerados
WHERE posicion = ROUND(total / 2)
ORDER BY pais, mediana DESC;

-- Misma logica que la mediana por pais (query 7) pero desglosada tambien por sector.
-- Comparando con las medias (query 3) se ve donde hay salarios altos que inflan la media: ejemplo USA Finance tiene media 92.770 pero
-- mediana 86.102 (hay sueldos altos que tiran de la media).
-- Las combinaciones con pocas ofertas (ej. Alemania Retail = 4) dan medianas poco fiables.


-- ------------------------------
-- VIEWS PARA TABLEAU
-- ------------------------------

-- VIEW: salario medio por sector
CREATE VIEW vista_salario_sector AS
SELECT 
    sector,
    COUNT(*) AS num_ofertas,
    ROUND(AVG(salary_min), 0) AS salario_medio
FROM salarios
GROUP BY sector;

SELECT * FROM vista_salario_sector;

-- VIEW: salario medio por pais
CREATE VIEW vista_media_pais AS
SELECT 
    pais,
    COUNT(*) AS num_ofertas,
    ROUND(AVG(salary_min), 0) AS salario_medio
FROM salarios
GROUP BY pais;

SELECT * FROM vista_media_pais;


-- VIEW: mediana del salario por pais
CREATE VIEW vista_mediana_pais AS
SELECT 
    pais,
    salary_min AS salario_mediana
FROM (
    SELECT 
        pais,
        salary_min,
        ROW_NUMBER() OVER (PARTITION BY pais ORDER BY salary_min) AS posicion,
        COUNT(*) OVER (PARTITION BY pais) AS total
    FROM salarios
) AS subconsulta
WHERE posicion = ROUND(total / 2);

SELECT * FROM vista_mediana_pais;

-- VIEW: salario medio por pais y sector
CREATE VIEW vista_pais_sector AS
SELECT 
    pais,
    sector,
    COUNT(*) AS num_ofertas,
    ROUND(AVG(salary_min), 0) AS salario_medio
FROM salarios
GROUP BY pais, sector;

SELECT * FROM vista_pais_sector;

-- VIEW: porcentaje de ofertas que publican salario por pais
CREATE VIEW vista_transparencia AS
SELECT 
    pais,
    COUNT(*) AS total_ofertas,
    COUNT(salary_min) AS con_salario,
    ROUND(COUNT(salary_min) / COUNT(*) * 100, 1) AS porcentaje_con_salario
FROM ofertas
GROUP BY pais;

 SELECT * FROM vista_transparencia;
 
 -- VIEW: evolucion mensual del salario por pais y sector
CREATE VIEW vista_evolucion AS
SELECT 
    pais,
    sector,
    mes,
    salario_medio,
    LAG(salario_medio) OVER (PARTITION BY pais, sector ORDER BY mes) AS mes_anterior,
    salario_medio - LAG(salario_medio) OVER (PARTITION BY pais, sector ORDER BY mes) AS variacion
FROM historico;

SELECT * FROM vista_evolucion; 

-- VIEW: ranking de sectores por salario dentro de cada pais
CREATE VIEW vista_ranking_sectores AS
SELECT 
    pais,
    sector,
    ROUND(AVG(salary_min), 0) AS salario_medio,
    RANK() OVER (PARTITION BY pais ORDER BY AVG(salary_min) DESC) AS ranking
FROM salarios
GROUP BY pais, sector;

SELECT * FROM vista_ranking_sectores;

-- VIEW: media y mediana por pais (juntas, para el grafico comparativo)
CREATE VIEW vista_media_mediana_pais AS
WITH numerados AS (
    SELECT 
        pais,
        salary_min,
        ROW_NUMBER() OVER (PARTITION BY pais ORDER BY salary_min) AS posicion,
        COUNT(*) OVER (PARTITION BY pais) AS total
    FROM salarios
)
SELECT 
    s.pais,
    ROUND(AVG(s.salary_min), 0) AS media,
    MAX(CASE WHEN n.posicion = ROUND(n.total / 2) THEN n.salary_min END) AS mediana
FROM salarios s
JOIN numerados n ON s.pais = n.pais
GROUP BY s.pais;

SELECT * FROM vista_media_mediana_pais;


