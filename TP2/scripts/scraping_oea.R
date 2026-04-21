# scraping_oea.R
# Objetivo: scrapear comunicados de prensa de la OEA (enero-abril 2026),
#           guardar los HTML descargados y producir una tabla id/titulo/cuerpo
# Paquetes: rvest, xml2, robotstxt, tidyverse, here


library(rvest)
library(xml2)
library(robotstxt)
library(tidyverse)
library(here)


# 1. CREO CARPETA /data 

data_dir <- here("TP2", "data")

if (!dir.exists(data_dir)) {
  dir.create(data_dir, recursive = TRUE)
  message("Carpeta creada: ", data_dir)
} else {
  message("Carpeta ya existe: ", data_dir)
}


# 2. VERIFIco ROBOTS.TXT
# Abrimos manualmente: https://www.oas.org/robots.txt
# Crawl-delay: 3 → usamos Sys.sleep(3) entre requests
# La ruta /es/centro_noticias/ no figura en Disallow → podemos scrapear

message("Verificando permisos de scraping en oas.org...")

permitido <- paths_allowed(
  paths  = "/es/centro_noticias/comunicados_prensa.asp",
  domain = "www.oas.org",
  bot    = "*"
)

if (!permitido) {
  stop("El robots.txt no permite scrapear esta ruta. Revisar antes de continuar.")
} else {
  message("Scraping permitido según robots.txt. Crawl-delay respetado: 3 segundos.")
}

# 3. FUNCIÓN: extraIGO títulos y links de una página de listado mensual
#
# La página de listado tiene links con el patrón:
#   "comunicado_prensa.asp?sCodigo=C-039/26"
# Cada comunicado aparece duplicado: primero el código, luego el título.
# Me quedo con los índices impares (títulos completos).


scrapear_listado_mes <- function(mes, anio = 2026) {
  
  # Construimos la URL del mes según la estructura indicada en la consigna
  url_mes <- paste0(
    "https://www.oas.org/es/centro_noticias/comunicados_prensa.asp?nMes=",
    mes,
    "&nAnio=",
    anio
  )
  
  message("Scrapeando listado: ", url_mes)
  
  # Pausa para respetar el Crawl-delay: 3 del robots.txt
  Sys.sleep(3)
  
  # Descargamos y parseamos el HTML de la página de listado
  html_mes <- read_html(url_mes)
  
  # Guardamos el HTML con marca temporal en el nombre (registro de descarga)
  fecha_hoy  <- format(Sys.Date(), "%Y%m%d")
  nombre_mes <- paste0("oea_mes", sprintf("%02d", mes), "_", anio, "_", fecha_hoy, ".html")
  ruta_html  <- file.path(data_dir, nombre_mes)
  write_html(html_mes, file = ruta_html)
  message("HTML guardado: ", ruta_html)
  
  # Extraemos todos los nodos <a> de la página
  todos_nodos <- html_mes |> html_elements("a")
  todos_href  <- todos_nodos |> html_attr("href")
  todos_texto <- todos_nodos |> html_text2() |> str_trim()
  
  # Filtramos únicamente los links que corresponden a comunicados individuales
  # El patrón identificado es: href contiene "comunicado_prensa.asp?sCodigo="
  es_comunicado <- str_detect(todos_href, "comunicado_prensa\\.asp\\?sCodigo=")
  
  links_comunicados  <- todos_href[es_comunicado]
  textos_comunicados <- todos_texto[es_comunicado]
  
  # Cada comunicado aparece dos veces: índices impares = título, pares = código
  indices_titulo <- seq(1, length(links_comunicados), by = 2)
  titulos        <- textos_comunicados[indices_titulo]
  links          <- links_comunicados[indices_titulo]
  
  # Construimos URLs absolutas agregando la base de la sección de noticias
  base_url       <- "https://www.oas.org/es/centro_noticias/"
  urls_completas <- paste0(base_url, links)
  
  message("Comunicados encontrados en mes ", mes, ": ", length(titulos))
  
  # Devolvemos un tibble con titulo, url y mes
  tibble(
    titulo = titulos,
    url    = urls_completas,
    mes    = mes
  )
}

# 4. FUNCIÓN: extraifo el cuerpo de un comunicado individual
#
# Selector CSS identificado con SelectorGadget: "#rightmaincol .title, h4, p"
# Concateno todos los párrafos y limpio los espacios y saltos de línea.

extraer_cuerpo <- function(url) {
  
  # Pausa para respetar el Crawl-delay: 3 del robots.txt
  Sys.sleep(3)
  
  # Descargamos el HTML del comunicado individual
  html_comunicado <- read_html(url)
  
  # Extraemos el contenido usando el selector identificado con SelectorGadget
  cuerpo <- html_comunicado |>
    html_elements("#rightmaincol .title, h4, p") |>
    html_text2() |>
    str_trim()
  
  # Concatenamos todos los párrafos en un solo string
  cuerpo <- str_c(cuerpo, collapse = " ")
  
  # Limpieza básica: saltos de línea, tabulaciones y espacios múltiples
  cuerpo <- str_replace_all(cuerpo, "[\\r\\n\\t]+", " ")
  cuerpo <- str_squish(cuerpo)
  
  return(cuerpo)
}

# 5. PRUEBO CON UN SOLO MES (marzo = mes 3, como sugiere la consigna)
# Verifico que la lógica funciona antes de iterar sobre los 4 meses

message("=== PRUEBA CON MES 3 (MARZO) ===")

listado_prueba <- scrapear_listado_mes(mes = 3, anio = 2026)
print(head(listado_prueba, 3))

message("Probando extracción de cuerpo del primer comunicado...")
cuerpo_prueba <- extraer_cuerpo(listado_prueba$url[1])
message("Primeros 200 caracteres: ", str_trunc(cuerpo_prueba, 200))

# 6. ITERACIÓN SOBRE LOS 4 MESES (enero=1, febrero=2, marzo=3, abril=4)
# map() aplica la función a cada mes y bind_rows() combina los resultados

message("=== ITERANDO SOBRE LOS 4 MESES ===")

meses <- 1:4

listado_completo <- map(meses, scrapear_listado_mes) |>
  bind_rows()

message("Total de comunicados encontrados (los 4 meses): ", nrow(listado_completo))

# Filtramos filas con título NA y agregamos id único
listado_completo <- listado_completo |>
  filter(!is.na(titulo)) |>
  mutate(id = row_number()) |>
  select(id, titulo, url, mes)

# 7. EXTRACCIÓN DEL CUERPO DE CADA COMUNICADO
# map_chr() aplica extraer_cuerpo() a cada URL y devuelve un vector de strings

message("Extrayendo cuerpo de cada comunicado (puede tardar varios minutos)...")

cuerpos <- listado_completo |>
  select(id, url) |>
  mutate(cuerpo = map_chr(url, extraer_cuerpo))

message("Cuerpos extraídos: ", nrow(cuerpos))


# 8. TABLA FINAL: 3 variables
#    id, titulo, cuerpo

comunicados_oea <- listado_completo |>
  left_join(cuerpos |> select(id, cuerpo), by = "id") |>
  select(id, titulo, cuerpo)

message("Estructura de la tabla final:")
glimpse(comunicados_oea)

# 9. GUARDO LA TABLA FINAL COMO .rds EN TP2/data/

ruta_rds <- file.path(data_dir, "comunicados_oea.rds")
saveRDS(comunicados_oea, file = ruta_rds)

message("Tabla guardada en: ", ruta_rds)
message("=== scraping_oea.R finalizado correctamente ===")