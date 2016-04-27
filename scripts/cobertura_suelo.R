## script que nos ayuda a pasar el SHP al ascii en consonancia con el ascii de elevaciones

library(raster)
library(rgdal)
library(rgeos)

## path shp
path_vege_cortijuela <- "/Users/iecolab/Desktop/shp_vege_corti"

## mapa de elevación
elevacion <- raster(file.path("..", "sig", "elevacion.asc"))

## creamos un nuevo raster, con la extensión de elevación
cobertura <- raster(elevacion)

## leemos el shp de la vegetación
shp_vege_corti <- readOGR(path_vege_cortijuela, "vege_cortijuela")

cobertura <- rasterize(shp_vege_corti, elevacion), field=c("tipo_ege")) ## tipo_ege = field _ 8

## mostramos qué significa cada número
levels(shp_vege_corti$tipo_ege)

## re-ordenamos los valores, para que los valores numérico más bajos, sean la cobertura más deseada por las crisálidas
## 1 - Encinar, 2 - Encinar+pinar, 8 - Pinar, 7 - Matorral+pinos+encinas, 4 - Matorral+encinar, 5 - Matorral+pinar, 6 - Matorral+Pinar, , 3 - Matorral, 9 - Suelo desnudo  
cambios_level <- paste("a", cobertura[], sep="_")
## Cambios: a_1 -> 8, a_2 -> 7 , a_8 -> 6 , a_7 -> 5, a_4 -> 4, a_5 y a_6 -> 3, a_3 -> 2, a_9 -> 1  
cambios_level[cambios_level == "a_1"] <- 8
cambios_level[cambios_level == "a_2"] <- 7
cambios_level[cambios_level == "a_8"] <- 6
cambios_level[cambios_level == "a_7"] <- 5
cambios_level[cambios_level == "a_4"] <- 4
cambios_level[cambios_level == "a_5"] <- 3
cambios_level[cambios_level == "a_6"] <- 3
cambios_level[cambios_level == "a_3"] <- 2
cambios_level[cambios_level == "a_9"] <- 1

## sustituimos después del cambio
cobertura[] <- as.numeric(cambios_level)

## guardamos el raster
writeRaster(cobertura, "../sig/cobertura_suelo.asc", overwrite = T)

