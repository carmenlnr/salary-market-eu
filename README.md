# Salary Market EU 

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

## Objetivo
Construir un dashboard interactivo en Tableau que responda, con datos, cuánto se paga por sector y país en Europa, dónde están las mayores diferencias y cómo evolucionan los salarios.

## Datos
- **Fuente:** API de Adzuna (https://developer.adzuna.com)

**Adzuna** es un **buscador de empleo** que agrega ofertas de trabajo de múltiples fuentes en varios países. Ofrece una **API pública y gratuita** que permite consultar ofertas reales con información de salario, sector, ubicación y empresa, además de un histórico de salarios medios. Esto la convierte en una fuente ideal para analizar el mercado salarial europeo con datos actuales y reales.

- **Tamaño:**
  - `ofertas_adzuna_data_raw.csv` → 6.101 ofertas de empleo actuales
  - `historico_salarios_data_raw.csv` → 192 registros de salario medio mensual (12 meses)
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

## Estructura del repositorio
- `Notebooks/` → notebooks de trabajo (recogida, limpieza, análisis)
- `Scripts/` → funciones reutilizables (.py)
- `Data/` → datos crudos en CSV
- `README.md` → documentación del proyecto

## Proceso (pipeline)
*(Aquí irá el esquema gráfico del pipeline para la presentación)*

1. **Carga y exploración de datos**
   - Notebook `01_recogida.ipynb`
   - Exploración de la estructura de la API y selección de variables
   - Funciones de recogida en `Scripts/recogida.py`
   - Exportación de los datos crudos a CSV
2. **Limpieza** *(pendiente)*
3. **Creación de tablas / esquema** *(pendiente)*
4. **Análisis SQL** *(pendiente)*
5. **Dashboard en Tableau** *(pendiente)*
6. *(se completará)*

## KPIs y métricas clave
*(pendiente — se completará en la fase de análisis)*

## Resultados e insights
*(pendiente)*

## Conclusiones
*(pendiente)*

## Solución al problema de negocio
*(pendiente)*

## Cómo reproducir el proyecto
*(pendiente — incluirá:  configurar claves de la API en `.env`, ejecutar los notebooks en orden)*

## Limitaciones
- **Datos de ofertas, no de nóminas reales:** lo ideal sería usar salarios reales de empleados, pero en Europa esa información apenas se publica por privacidad y normativa (RGPD), a diferencia de EE. UU. Por eso se usan los salarios de las ofertas de empleo.
- Los salarios son en su mayoría **estimados** por Adzuna, no exactos.
- `salary_min` y `salary_max` coinciden en los salarios estimados.
- La clasificación por **sector** de Adzuna es amplia (no todas las ofertas de "IT Jobs" son tech puro).
- Los datos son ofertas **vivas**: el volumen exacto puede variar según el día de recogida.

## Próximos pasos
*(pendiente/incompleto)*
- **Aprovechar la nueva normativa de transparencia salarial:** la Directiva UE 2023/970, en vigor desde junio de 2026, obliga a incluir rangos salariales en todas las ofertas de empleo de la UE. Repetir el análisis más adelante permitiría trabajar con datos más fiables y completos.
- Ampliar a **más países** europeos para una comparativa más amplia.
- Incorporar **más sectores** y analizar la evolución temporal con más histórico.
- (Se completará con los aprendizajes del proyecto.)

## Presentación
*(enlace pendiente)*