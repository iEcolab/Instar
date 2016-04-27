## cambiamos los nombres de los ficheros diarios para ir cargándolos más cómodamente.

install.packages(c("rgdal", "rgeos"), dep = T, type = "source")
library(raster)
library(rgdal)
library(rgeos)

path_mascara <- "/Users/iecolab/dev/procesionaria/sig/Subcuencas.asc"
path_mde_tif <- "/Users/iecolab/dev/procesionaria/sig/mde_snev.tif"
path_mde_jherrero <- "/Users/iecolab/Desktop/mde.asc"

## las máscara será la elevación
mascara <- raster(path_mascara)
plot(mascara)

## para la elevación
elevacion_sn <- raster(path_mde_jherrero)
plot(elevacion_sn)

## clip para obtener sólo la zona que nos interesa
elevacion <- crop(elevacion_sn, mascara)
  
writeRaster(elevacion, "elevacion.asc", overwrite=TRUE)

foto <- brick("../sig/zona.tif")
foto_30 <- aggregate(foto, 30)
plot(foto_30)
writeRaster(foto_30, "zona.bmp", overwrite=T)
