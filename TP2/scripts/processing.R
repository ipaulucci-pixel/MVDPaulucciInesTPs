
# processing.R
# Objetivo: limpiar, lematizar y filtrar el texto de los comunicados de la OEA
# Paquetes: tidyverse, udpipe, stopwords, here

library(tidyverse)
library(udpipe)
library(stopwords)
library(here)

# 1. CREAR CARPETA /output

output_dir <- here("TP2", "output")

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  message("Carpeta creada: ", output_dir)
} else {
  message("Carpeta ya existe: ", output_dir)
}

# 2. LEER EL RESULTADO DEL SCRAPING

ruta_rds <- here("TP2", "data", "comunicados_oea.rds")
comunicados_oea <- readRDS(ruta_rds)

message("Comunicados cargados: ", nrow(comunicados_oea))
glimpse(comunicados_oea)

# 3. LIMPIEZA DEL TEXTO
# Quitamos: signos de puntuación, números, caracteres especiales,
#           espacios innecesarios. Todo queda en minúscula.
# Usamos str_remove_all() y str_squish() del tidyverse (stringr)

message("Limpiando texto del cuerpo...")

comunicados_limpio <- comunicados_oea |>
  filter(!is.na(titulo), !is.na(cuerpo)) |>  # eliminamos filas con NA
  mutate(
    # Convertimos a minúscula
    cuerpo_limpio = str_to_lower(cuerpo),
    # Quitamos URLs
    cuerpo_limpio = str_remove_all(cuerpo_limpio, "https?://\\S+"),
    # Quitamos números
    cuerpo_limpio = str_remove_all(cuerpo_limpio, "\\b\\d+(\\.\\d+)?\\b"),
    # Quitamos signos de puntuación y caracteres especiales
    # Conservamos solo letras (incluye acentos y ñ), espacios
    cuerpo_limpio = str_remove_all(cuerpo_limpio, "[^a-záéíóúüñ\\s]"),
    # Quitamos espacios múltiples
    cuerpo_limpio = str_squish(cuerpo_limpio)
  )

message("Limpieza completada. Filas resultantes: ", nrow(comunicados_limpio))

# 4. DESCARGA Y CARGA DEL MODELO DE UDPIPE PARA ESPAÑOL
# udpipe hace lematización + POS-tagging en un solo paso
# Se descarga una sola vez; si ya existe, lo carga directamente

message("Cargando modelo de udpipe para español...")

modelo_path <- here("TP2", "data", "spanish-gsd-ud-2.5-191206.udpipe")

if (!file.exists(modelo_path)) {
  message("Descargando modelo de español (puede tardar unos minutos)...")
  m_es <- udpipe_download_model(language = "spanish", 
                                model_dir = here("TP2", "data"))
  modelo_path <- m_es$file_model
}

modelo_es <- udpipe_load_model(modelo_path)
message("Modelo cargado correctamente.")

# 5. LEMATIZACIÓN Y POS-TAGGING CON UDPIPE
# udpipe_annotate() tokeniza, lematiza y asigna categoría gramatical (upos)
# a cada palabra del texto en un solo paso

message("Lematizando comunicados (puede tardar unos minutos)...")

comunicados_lemas <- udpipe_annotate(
  modelo_es,
  x      = comunicados_limpio$cuerpo_limpio,  # texto limpio
  doc_id = comunicados_limpio$id              # id de cada comunicado
) |>
  as.data.frame() |>
  as_tibble() |>
  mutate(id = as.integer(doc_id)) |>
  select(id, token, lemma, upos)

message("Lematización completada. Tokens totales: ", nrow(comunicados_lemas))


# 6. FILTRO SOLO SUSTANTIVOS, VERBOS Y ADJETIVOS
# upos: NOUN = sustantivo, VERB = verbo, ADJ = adjetivo
# Estos concentran más carga semántica según el tutorial de clase

message("Filtrando sustantivos, verbos y adjetivos...")

comunicados_lemas <- comunicados_lemas |>
  filter(upos %in% c("NOUN", "VERB", "ADJ"))

message("Tokens tras filtro gramatical: ", nrow(comunicados_lemas))

# 7. CONVIERTO LEMAS A MINÚSCULA
# udpipe puede devolver lemas con mayúsculas → normalizamos


comunicados_lemas <- comunicados_lemas |>
  mutate(lemma = str_to_lower(lemma))


# 8. REMUEVO STOPWORDS EN ESPAÑOL
# Usamos el paquete stopwords con la fuente "snowball" (estándar de clase)


message("Removiendo stopwords...")

stop_es <- stopwords::stopwords("es", source = "snowball")
stop_words_df <- tibble(lemma = stop_es)

comunicados_lemas <- comunicados_lemas |>
  anti_join(stop_words_df, by = "lemma") |>
  filter(
    !is.na(lemma),           # sin NA
    str_length(lemma) > 2    # sin tokens de 1-2 caracteres (ruido)
  )

message("Tokens tras remoción de stopwords: ", nrow(comunicados_lemas))


# 9. AGREGAR TÍTULO PARA REFERENCIA


comunicados_lemas <- comunicados_lemas |>
  left_join(
    comunicados_oea |> select(id, titulo),
    by = "id"
  )


# 10. GUARDO EL RESULTADO PROCESADO EN /output


ruta_procesado <- file.path(output_dir, "processed_text.rds")
saveRDS(comunicados_lemas, file = ruta_procesado)

message("Archivo procesado guardado en: ", ruta_procesado)
message("=== processing.R finalizado correctamente ===")