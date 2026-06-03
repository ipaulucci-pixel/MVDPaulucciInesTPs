# Trabajos prácticos- Manejo y Visualización de Datos

Universidad de San Andrés (UdeSA), 2026
Profesor: Juan Octavio Castro
Autora: Inés Paulucci

## Trabajo práctico 1— Acceso a internet en el mundo (2013–2023)

Analizo la evolución del uso de internet entre 2013 y 2023 con datos del Banco Mundial. La hipótesis plantea que los grupos de ingresos bajos y medios-bajos crecieron porcentualmente más en el acceso a internet que los grupos de ingresos altos, aunque mantuvieron niveles absolutos más bajos durante todo el período. Los resultados muestran un crecimiento importante en todos los grupos, pero también que las brechas de acceso siguen siendo marcadas.

Archivos principales:

- `TP1/data/`: bases originales del Banco Mundial.
- `TP1/notebooks/uso_de_internet_mundial.qmd`: notebook con el análisis.
- `TP1/output/resultado_hipotesis.csv`: archivo final exportado.


## Trabajo práctico 2— Comunicados de prensa de la OEA: análisis de frecuencia léxica

Se aplica web scraping sobre el sitio oficial de la Organización de los Estados Americanos (OEA) para descargar los **67 comunicados de prensa** publicados entre enero y abril de 2026. Sobre el corpus se aplica limpieza de texto, lematización con `udpipe`, filtrado de sustantivos, verbos y adjetivos y remoción de stopwords. Se construye la Matriz de Frecuencia de Términos (DTM) y se analiza la frecuencia de cinco términos seleccionados por su relevancia institucional. Los términos más frecuentes son **misión** (212), **derecho** (101) y **elección** (94), seguidos por **seguridad** (36) y **democracia** (32). Los resultados muestran que la actividad de la OEA durante el primer cuatrimestre de 2026 estuvo dominada por el despliegue de **misiones electorales** en la región (Guatemala y Bolivia), enmarcadas en una narrativa institucional centrada en democracia, derecho y seguridad hemisférica.

Archivos principales:
- `TP2/scripts/scraping_oea.R`: descarga los comunicados respetando el `robots.txt`.
- `TP2/scripts/processing.R`: limpieza, lematización y filtrado gramatical.
- `TP2/scripts/metrics_figures.R`: construcción de la DTM y figura final.
- `TP2/notebooks/informe_oea.qmd`: notebook con el análisis.

## Trabajo práctico 3 — Regresión logística: ingresos altos en EE. UU.

Se aplica una **regresión logística binomial** para modelar la probabilidad de que un ciudadano de EE. UU. tenga ingresos superiores a USD 50.000 anuales (`>50K` vs `<=50K`), a partir de variables sociodemográficas y laborales del *Adult Census Income*. El análisis adopta una perspectiva **descriptiva y explicativa**, comparando dos modelos: uno base (sin interacción) y uno interactivo. La **educación**, la **edad**, las **horas trabajadas** y la **ganancia de capital** se asocian fuertemente con mayor probabilidad de altos ingresos: pasar de no terminar el secundario a tener posgrado eleva la probabilidad en +48 puntos porcentuales. El hallazgo central surge de la interacción `sex × marital_simple`: una vez controladas las demás variables, **la prima del matrimonio resulta mucho mayor en mujeres que en hombres** (OR ≈ 23 vs ≈ 7.7), contradiciendo la hipótesis inicial del "modelo del varón proveedor" y sugiriendo un proceso de selección entre las mujeres casadas que permanecen en el mercado laboral *full-time*.

Archivos principales:
- `TP3/data/adult_census_USA.csv`: dataset original.
- `TP3/notebooks/census_income_usa.qmd`: notebook con el análisis completo.
- `TP3/notebooks/census_income_usa.html: render final.
