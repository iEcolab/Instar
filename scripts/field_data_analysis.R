library(raster)

path_field_data <- "../field_data"
path_clima <- "../data"

## mapa de elevación
elevacion <- raster(file.path("..", "sig", "elevacion.asc"))
elevacion[] <- round(elevacion[])

## modelo para la parasitación
data <- read.csv(file.path(path_field_data, "fitness_para.csv"), header = T, sep=";", dec = ",")

## para cada año del conjunto de datos
for (year in unique(data$year)){
  ## mapa de temperatura
  tmed <- raster(file.path(path_clima, paste("Ano_", year, "-", year + 1, "_T_m.asc", sep="")))

  ## seleccionamos aquellos puntos que tienen la misma altitud que el conjunto de muestras
  mi_tmed <- (elevacion == unique(data$altitude))*tmed
  
}




## modelo para el parasitismo
modelo <- lm(parasit ~ altitude + year, data = data)
summary(modelo)

## modelo para los no nacidos según altitud
modelo <- lm(NN ~ altitude + year, data = data)
plot(modelo)
