# metrics_figures.R
# Objetivo: construir DTM, calcular frecuencia de 5 términos relevantes
#           y generar gráfico de barras guardado en TP2/output/
# Paquetes: tidyverse, tidytext, tm, here

library(tidyverse)
library(tidytext)
library(tm)
library(here)


# 1. LEER EL ARCHIVO PROCESADO

ruta_procesado <- here("TP2", "output", "processed_text.rds")
comunicados_lemas <- readRDS(ruta_procesado)

message("Archivo procesado cargado. Tokens: ", nrow(comunicados_lemas))
glimpse(comunicados_lemas)


# 2. CONSTRUIR LA DTM (Document-Term Matrix)
# Primero contamos frecuencias por documento y término (formato tidy)
# Luego usamos cast_dtm() de tidytext para construir la matriz
# Este es exactamente el flujo del tutorial 06 de clase

message("Construyendo DTM...")

# Contamos apariciones de cada lema por documento
frecuencia_tokens <- comunicados_lemas |>
  count(id, lemma, sort = TRUE)

# Construimos la DTM con cast_dtm() de tidytext
# document = id del comunicado, term = lema, value = frecuencia
matriz_dtm <- frecuencia_tokens |>
  cast_dtm(document = id, term = lemma, value = n)

message("DTM construida: ", nrow(matriz_dtm), " documentos x ", 
        ncol(matriz_dtm), " términos")

# 3. SELECCIÓN DE 5 TÉRMINOS RELEVANTES PARA EL CONTEXTO DE LA OEA
#
# Justificación de los 5 términos elegidos:
#
# 1. "democracia" — misión central de la OEA: promover y defender
#    la democracia en el hemisferio americano
#
# 2. "misión" — la OEA despliega misiones electorales, misiones especiales
#    y misiones de observación como herramienta central de acción institucional
#
# 3. "seguridad" — uno de los pilares institucionales: seguridad hemisférica,
#    multidimensional y pública
#
# 4. "derecho" — presente en derechos humanos, derecho internacional
#    y marcos legales interamericanos
#
# 5. "elección" — en 2026 hay varios procesos electorales en la región
#    en los que la OEA despliega misiones de observación electoral
#

terminos_de_interes <- c("democracia", "misión", "seguridad", "derecho", "elección")

message("Términos seleccionados: ", paste(terminos_de_interes, collapse = ", "))

# Filtramos la DTM para quedarnos solo con esos 5 términos
matriz_dtm_filtrada <- matriz_dtm[, colnames(matriz_dtm) %in% terminos_de_interes]

message("Términos encontrados en la DTM: ", 
        paste(colnames(matriz_dtm_filtrada), collapse = ", "))


# 4. CONDENSAR LA INFORMACIÓN: frecuencia total por término
# Convertimos la DTM a data frame, pivoteamos y sumamos por término
# Este es exactamente el flujo del tutorial 06 de clase

dtm_df <- as.data.frame(as.matrix(matriz_dtm_filtrada)) |>
  rownames_to_column(var = "id") |>
  pivot_longer(-id, names_to = "lemma", values_to = "n") |>
  group_by(lemma) |>
  summarise(frecuencia_total = sum(n)) |>
  arrange(desc(frecuencia_total))

message("Frecuencia total por término:")
print(dtm_df)


# 5. GRÁFICO DE BARRAS CON GGPLOT2
# Muestra la frecuencia total de los 5 términos en todos los comunicados

message("Generando gráfico de barras...")

grafico <- ggplot(
  dtm_df,
  aes(x = frecuencia_total, y = reorder(lemma, frecuencia_total))
) +
  geom_col(fill = "steelblue", alpha = 0.8) +
  labs(
    title = "Frecuencia de términos clave en comunicados de prensa de la OEA",
    subtitle = "Enero - Abril 2026 | Corpus lematizado",
    x = "Frecuencia total (apariciones)",
    y = "Término",
    caption = "Fuente: OEA - Centro de Noticias (oas.org)"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    axis.text     = element_text(size = 11),
    panel.grid.major.y = element_blank()
  )


# 6. GUARDAR EL GRÁFICO EN TP2/output/frecuencia_terminos.png


output_dir <- here("TP2", "output")
ruta_figura <- file.path(output_dir, "frecuencia_terminos.png")

ggsave(
  filename = ruta_figura,
  plot     = grafico,
  width    = 8,
  height   = 5,
  dpi      = 300
)

message("Figura guardada en: ", ruta_figura)
message("=== metrics_figures.R finalizado correctamente ===")