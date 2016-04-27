install.packages(c("rgdal", "rgeos"), dep = T, type = "source")
library(raster)
library(rgdal)
library(rgeos)

setwd("~/Desktop/original")

imagenes_jp2 <- list.files(".", full.names = T, pattern = "jp2$")

## convertimos a tif, que las jp2 no les gusta
imagenes_tif <- paste(imagenes_jp2, ".tif", sep = "")
comando <- paste("/usr/local/bin/gdal_translate -of GTIFF", imagenes_jp2, imagenes_tif)
apply(matrix(comando), 1, system)

## las máscara será la elevación
path_mascara <- "/Users/iecolab/Downloads/res/Subcuencas.asc"
mascara <- raster(path_mascara)
plot(mascara)

for (imagen in imagenes_tif){
  mi_imagen <- brick(imagen)
    
  trozo <- crop(mi_imagen, extent(mascara))
  
  writeRaster(trozo, paste("trozo", basename(imagen), sep="_"), overwrite=TRUE)
}

## unimos los trozos
imagenes_trozos <- list.files(".", full.names = T, pattern = "trozo.*.tif$")
input.rasters <- lapply(imagenes_trozos, brick)
rasters1.mosaicargs <- input.rasters
rasters1.mosaicargs$fun <- mean
## generamos el mosaico, un unico raster con todos los valores
mosaico <- do.call(mosaic, rasters1.mosaicargs)
writeRaster(mosaico, "zona.tif", overwrite=TRUE, options=c("COMPRESS=NONE", "TFW=YES"))

## extraemos solo la zona que nos interesan.



## Todo esto creo que sobra, en este script
# ## leemos el mosaico
# mosaico <- brick("zona.tif")
# 
# epoly <- as(extent(mosaico), "SpatialPolygons")
# ## (assuming your extents really are in d's projection)
# proj4string(epoly) <- CRS(proj4string(mosaico))
# cropd <- SpatialPolygonsDataFrame(epoly, data.frame(x = 1), match.ID = FALSE) 
# 
# ## leemos el shape de los usos del suelo, o cualquier otro que tenga info sobre las posibles manchas de pinos.
# usos_ <- readOGR(".", "usos_mapa5605s_pinos")
# usos <- spTransform(usos_, CRS(proj4string(mosaico)))  
# 
# res <- gIntersection(usos, cropd, byid=T)
# 
# ## extraemos la zona del ráster que nos interesa
# zona_uso <- mask(mosaico, res)
# test <- ratify(zona_uso)
# 
# extent(zona_uso)
# extent(mosaic)
# 
# zona_uso[]
# 
# distancia <- dist(zona_uso[], method = "maximum")
# cluster <- kmeans(zona_uso[], 3)
# 
# 
# ## borramos los auxiliares creados
# apply(matrix(paste("rm", imagenes_tif)), 1, system)