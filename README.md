# Salary Market EU 
Análisis de la compensación salarial en Europa por país, sector y nivel, a partir de ofertas de empleo reales

## Motivación
Vengo del mundo de **payroll (nóminas)**, así que la compensación salarial es un área que conozco y me interesa de primera mano. Quise aprovechar ese conocimiento de dominio para un proyecto que, además, fuera **transversal a varios sectores** (tech, finanzas y retail/e-commerce), de modo que sirviera de cara a empresas de distintas industrias.

El análisis de compensación es justo el tipo de problema que toda empresa tiene, independientemente de su sector, lo que hace el proyecto aplicable en muchos contextos. Además, lo enfoqué en SQL y dashboards porque son las habilidades que quería reforzar y las más demandadas en las ofertas de analista de datos.

## Problema de negocio
Las empresas que operan en varios países europeos necesitan saber cuánto pagar por cada puesto para ser competitivas sin disparar costes. Este proyecto analiza la **compensación salarial en Europa** por sector y país, a partir de ofertas de empleo reales, para ayudar a una consultora de compensación / RRHH a decidir **bandas salariales** y **dónde contratar**.

## Hipótesis
- Existen diferencias salariales significativas **entre sectores** (tech, finanzas, retail/e-commerce).
- Existen diferencias salariales significativas **entre países** para un mismo sector.
- Los salarios muestran una **tendencia temporal** (evolución en los últimos meses).
- El sector tech presenta los salarios más altos; retail/e-commerce, los más bajos.

**Resultado:** las cuatro hipótesis se confirman (con matices que se detallan en *Resultados e insights*).

## Objetivo
Construir un dashboard interactivo en Tableau que responda, con datos, cuánto se paga por sector y país en Europa, dónde están las mayores diferencias, cómo de transparente es cada mercado y cómo evolucionan los salarios.

## Datos
- **Fuente:** API de Adzuna (https://developer.adzuna.com)

**Adzuna** es un **buscador de empleo** que agrega ofertas de trabajo de múltiples fuentes en varios países. Ofrece una **API pública y gratuita** que permite consultar ofertas reales con información de salario, sector, ubicación y empresa, además de un histórico de salarios medios. Esto la convierte en una fuente ideal para analizar el mercado salarial europeo con datos actuales y reales.


- **Ámbito:** 6 países (España, Reino Unido, Francia, Alemania, Países Bajos y Estados Unidos) y 4 sectores (IT, Finance, Retail y Logistics). Europa es el foco del análisis; Estados Unidos se incluye como punto de contraste (mercado de referencia fuera de la UE).

- **Tamaño:**
  - `ofertas_adzuna_data_raw.csv` → 9.256 ofertas de empleo actuales
  - `historico_salarios_data_raw.csv` → 288 registros de salario medio mensua (12 meses)

- **Variables del dataset de ofertas (raw):**
  - `title` → puesto
  - `category` → sector
  - `salary_min` / `salary_max` → salario
  - `salary_is_predicted` → salario real (0) o estimado (1)
  - `location` → ubicación
  - `company` → empresa
  - `contract_type` → tipo de contrato
  - `created` → fecha de publicación
  - `pais` → país de la oferta

**Decisión de análisis:** `salary_min`
Para todo el análisis se usa **`salary_min`** (el extremo inferior del rango ofertado). Es una decisión consciente:
- Es la cifra que la empresa **garantiza como mínimo**, así que da una estimación **conservadora** y no infla los salarios.
- Mantiene **coherencia** con la limpieza (el filtrado de outliers se aplicó sobre `salary_min`).

Alternativas válidas serían el punto medio `(min+max)/2` o `salary_max`; cada una cuenta una historia distinta. Se eligió el mínimo por prudencia y consistencia.


## Proceso (pipeline)

**Adzuna API → Python (recogida + limpieza) → MySQL (esquema relacional + análisis SQL) → Tableau (dashboards + story)**

1. **Recogida de datos** — notebook de recogida
   - Conexión a la API de Adzuna y selección de variables.
   - Funciones de recogida reutilizables en `Scripts/`.
   - Recogida de un máximo de 400 ofertas por combinación país+sector (límite de páginas de la API).
   - Exportación de los datos crudos a CSV.

2. **Limpieza** — notebook de limpieza
   - Filtrado de salarios: **suelo de 10.000 €** y **techo de 300.000 €** para descartar valores irreales.
   - Conversión de salarios a euros (tipos del BCE).
   - Detección del **nivel** (Senior / Junior / Not specified) a partir de palabras clave en el título.
   - Normalización de países y sectores.
   - Resultado: tabla de ofertas con salario fiable (`salarios`).

3. **Carga y esquema relacional** — Python + MySQL
   - Las tablas principales (`ofertas`, `salarios`, `historico`) se cargan desde Python con `to_sql`.
   - En SQL se define la **estructura relacional**: tablas catálogo `paises` y `sectores` con **claves primarias**, conectadas a las tablas grandes mediante **foreign keys** (modelo de catálogos: las columnas de texto `pais`/`sector` validan contra los catálogos).

 


| Tabla | Filas | Descripción |
|---|---|---|
| `ofertas` | 9.256 | Todas las ofertas recogidas |
| `salarios` | 4.138 | Ofertas con salario fiable (tras el filtrado) |
| `historico` | 288 | Salario medio mensual por país y sector |
| `paises` | 6 | Catálogo de países (PK `pais`) |
| `sectores` | 4 | Catálogo de sectores (PK `sector`) |

Las foreign keys conectan `ofertas` (y demás tablas) con los catálogos `paises` y `sectores`, garantizando la integridad referencial.


4. **Análisis SQL** 
   - 11 queries que cubren desde agregaciones básicas hasta SQL avanzado (subqueries, CTEs y window functions).
   - 7 vistas (`views`) que encapsulan los cálculos para conectarlos directamente a Tableau.


| Vista | Qué calcula |
|---|---|
| `vista_salario_sector` | Salario medio por sector |
| `vista_media_pais` | Salario medio por país |
| `vista_mediana_pais` | Mediana salarial por país |
| `vista_media_mediana_pais` | Media **y** mediana por país en una sola tabla (CTE con `ROW_NUMBER`) |
| `vista_pais_sector` | Salario medio por país y sector (heatmap) |
| `vista_transparencia` | % de ofertas que publican salario por país |
| `vista_evolucion` | Evolución mensual del salario (con `LAG` para la variación) |
| `vista_ranking_sectores` | Ranking de sectores por país (`RANK`) |

> **Nota sobre técnicas SQL:** la mediana no existe como función nativa en MySQL por lo que se calcula con una window function (`ROW_NUMBER` + `COUNT OVER`) localizando el valor central de cada grupo. 

5. **Visualización** — Tableau Desktop
   - 10 hojas de gráficos → 6 dashboards interactivos → 1 Story narrativa para la presentación.


## KPIs y métricas clave
- **Salario medio global:** 57.349 €
- **Transparencia media:** 48 % de las ofertas publican salario
- **Sector líder:** IT (76.182 € de media)
- **País líder en Europa:** Reino Unido (51.889 €); fuera de la UE, EE. UU. lidera con 74.760 €

## Resultados e insights
**1. El país marca diferencias claras**

Salario medio por país (`salary_min`):

| País | Salario medio | Nº ofertas |
|---|---|---|
| Estados Unidos | 74.760 € | 1.592 |
| Reino Unido | 51.889 € | 1.510 |
| Países Bajos | 41.707 € | 353 |
| España | 40.034 € | 215 |
| Alemania | 38.945 € | 36 |
| Francia | 35.201 € | 432 |

Dentro de Europa, **Reino Unido y Países Bajos lideran**. EE. UU. se sale del rango europeo (es solo referencia). *Alemania tiene una muestra pequeña (36 ofertas con salario), por lo que su dato es orientativo — ver Limitaciones.*

**2. El sector pesa tanto como el país**
| Sector | Salario medio |
|---|---|
| IT | 76.182 € |
| Finance | 65.074 € |
| Logistics | 47.292 € |
| Retail | 37.311 € |

**IT paga más del doble que Retail.** La cualificación técnica es el factor que más empuja el salario.

**3. El cruce país × sector**
La combinación mejor pagada es **EE. UU. – IT (109.025 €)**. El mapa de calor muestra que la brecha entre sectores se dispara en EE. UU. y se mantiene más comprimida en la Europa continental.

**4. La media engaña: media vs mediana**
En todos los países la **media supera a la mediana**, señal de que unos pocos salarios altos tiran del promedio hacia arriba. El caso extremo es EE. UU. (media 74.760 € / mediana 62.531 €). Mirar la distribución completa (box plot) da una imagen más honesta que el promedio solo.

**5. Transparencia salarial (insight estrella)**
% de ofertas que publican salario:

| País | % con salario |
|---|---|
| Reino Unido | 100 % |
| Estados Unidos | 100 % |
| Francia | 39,7 % |
| Países Bajos | 27,8 % |
| España | 18,6 % |
| Alemania | 3,1 % |

Contraste: mientras Reino Unido y EE. UU. publican el salario casi siempre, **Alemania apenas lo hace (3 %)**. Esto conecta directamente con la **Directiva UE 2023/970** de transparencia salarial (en vigor desde junio de 2026), que obligará a publicar rangos: los datos muestran el punto de partida del cambio. *Esto explica además por qué Alemania tiene tan pocos datos de salario en el análisis: no es un error, es el reflejo de su mercado.*


**6. El nivel también cuenta**
| Nivel | Salario medio |
|---|---|
| Senior | 71.683 € |
| Not specified | 50.924 € |
| Junior | 47.235 € |

Un perfil **senior gana ~24.000 € más que uno junior**. El nivel se detecta por palabras clave en el texto de la oferta, así que es aproximado, pero el patrón Senior > Junior es claro.

**7. Evolución temporal**
Las series más estables (Reino Unido) muestran un **crecimiento sostenido de IT**, mientras el resto de sectores se mantienen planos. El histórico de otros países presenta más volatilidad y alguna anomalía puntual, que se trata como limitación de los datos (ver abajo).


## Conclusiones/recomendaciones

**Para candidatos:**
- No te limites a tu país: dentro de Europa hay diferencias claras (Reino Unido y Países Bajos lideran).
- El sector pesa tanto como el país: IT y Finance pagan muy por encima de Retail y Logistics.

**Para RRHH / consultoría de compensación:**
- La **Directiva UE 2023/970** obliga a la transparencia: conviene prepararse (Alemania publica solo el 3 %).
- Usa el **benchmarking por país y sector** para ajustar bandas salariales competitivas sin disparar costes.

## Solución al problema de negocio
El dashboard permite a una consultora de compensación responder, con datos reales, las dos preguntas clave del problema: **cuánto pagar** (bandas por país y sector, con media y mediana) y **dónde contratar** (mapa salarial, ranking de sectores y nivel de transparencia de cada mercado).


## Limitaciones
- **Datos de ofertas, no de nóminas reales:** lo ideal sería usar salarios reales de empleados, pero en Europa esa información apenas se publica por privacidad y normativa (RGPD), a diferencia de EE. UU. Por eso se usan los salarios de las ofertas de empleo.
- Los salarios son en su mayoría **estimados** por Adzuna, no exactos. En los estimados, `salary_min` y `salary_max` coinciden.
- La clasificación por **sector** de Adzuna es amplia (no todas las ofertas de "IT Jobs" son tech puro).
- Los datos son ofertas **vivas**: el volumen exacto puede variar según el día de recogida.
- **Volumen topado:** se recogió un máximo de 400 ofertas por combinación país+sector (límite de páginas de la API), por lo que el volumen **no mide la demanda real** del mercado.
- **Muestra pequeña en Alemania** (36 ofertas con salario): su dato es orientativo.
- **Histórico volátil:** algunas series temporales presentan anomalías puntuales; para las tendencias se usan las series más estables (Reino Unido).

## Próximos pasos
- **Aprovechar la nueva normativa de transparencia salarial:** la Directiva UE 2023/970, en vigor desde junio de 2026, obliga a incluir rangos salariales en todas las ofertas de empleo de la UE. Repetir el análisis más adelante permitiría trabajar con datos más fiables y completos.
- **Contrastar con fuentes oficiales y reales:** comparar con **Eurostat** (ajustando por IPC el desfase 2022→2026) y con **Glassdoor** (salarios reportados por empleados), para ver si las empresas ofrecen por encima o por debajo de lo que la gente realmente cobra.
- **Medir la demanda real:** recoger sin el tope de 400 ofertas por combinación para analizar el volumen de mercado.
- Ampliar a **más países** europeos y **más sectores** para una comparativa más amplia, con más histórico temporal.
- **Analizar la modalidad** (remoto / híbrido / presencial) y las **herramientas y lenguajes de datos** más demandados (Python, SQL, Tableau, Power BI) mediante NLP sobre las descripciones completas de las ofertas.

## Cómo reproducir el proyecto
1. Clonar el repositorio salary_market_eu
2. Crear un archivo `.env` con las credenciales de la API de Adzuna y de MySQL (ver `.env.example`):
   ```
   ADZUNA_APP_ID=...
   ADZUNA_APP_KEY=...
   MYSQL_PASSWORD=...
   ```
   > El archivo `.env` está en `.gitignore` y **no se sube** al repositorio.
3. Ejecutar los notebooks en orden: **recogida → limpieza → carga a MySQL**.
4. En MySQL Workbench, ejecutar `queries.sql` (primero la sección de setup del esquema, luego el análisis).
5. Abrir el workbook de Tableau y conectarlo a la base de datos `salary_dashboard`.


## Presentación
La visualización completa (6 dashboards + Story) está en 
[`salary_dashboard.twbx`](./Tableau/salary_market_eu.twbx). 
Ábrelo con Tableau Desktop o Tableau Reader.