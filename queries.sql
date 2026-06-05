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

