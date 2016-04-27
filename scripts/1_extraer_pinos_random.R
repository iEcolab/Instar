#install.packages(c("rgdal", "rgeos"), dep = T, type = "source")
#install.packages(c("classInt"), dep = T)
library(raster)
library(rgdal)
library(rgeos)

library(sp)
library(rgdal)
library(classInt)
library(RColorBrewer)

set.seed(69)

## SALIDA:
## - un fichero shp por cada polígono encontrado, el nombre será poligono_X_clase_Y.shp
##
## ENTRADA:
## - nombre de la imagen tif
## - nombre de la capa shp
## - número de clases a clasificar
##
generar_shp_clases <- function(nombre_imagen_tif, nombre_poligonos_sin_shp, n_clases = 5, numero_pixeles_por_pino = 20){

  ## leemos la zona
  mosaico <- brick(nombre_imagen_tif)
  
  epoly <- as(extent(mosaico), "SpatialPolygons")
  proj4string(epoly) <- CRS(proj4string(mosaico))
  cropd <- SpatialPolygonsDataFrame(epoly, data.frame(x = 1), match.ID = FALSE) 
  
  ## leemos el shape de los usos del suelo, o cualquier otro que tenga info sobre las posibles manchas de pinos.
  usos <- readOGR(".", nombre_poligonos_sin_shp)
  
  ## codigo, si necesitamos cambiar la proyeccion de un shape
  #usos_ <- readOGR(".", "usos_mapa5605s_pinos")
  #projection(usos_) <- CRS("+proj=utm +zone=30 +datum=WGS84 +units=m +no_defs")
  #projection(usos_) <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
  #usos <- spTransform(usos_, CRS(proj4string(mosaico)))  
  #writeOGR(usos, ".", paste("pinares_linaria", sep="_"), driver="ESRI Shapefile", overwrite_layer=T)      
  

  ## seleccionamos solo los polígonos que estan dentro de la imagen
  res <- gIntersection(usos, cropd, byid = T)
  
  n_poligono <- 1
  for (n_area in 1:length(res)){
    puts " Procesando polígono #{n_area}"
    area <- res[n_area]
    mi_zona <- crop(mosaico, area)
    mi_zona <- mask(mi_zona, area)
    
    ## obtenemos un data.frame con x.y (centroides), y valor de rgb.
    valores <- as.data.frame(mi_zona, xy = TRUE, na.rm = T)
    
    ## convertimos los valores a HSV
    rgb <- sapply(subset(valores, select=c("zona.1", "zona.2", "zona.3")), as.factor)
    rgb <- matrix(sapply(rgb, as.numeric), ncol=3)
    mi_hsv <- t(rgb2hsv(t(rgb)))
    valores$hsv <- mi_hsv
    
    ## hacemos el cluster    
    n_cluster <- n_clases
    #cluster <- kmeans(valores$hsv, n_cluster, iter.max = 100, nstart = 1)
    cluster <- kmeans(subset(valores, select=c(zona.1, zona.2, zona.3)), n_cluster, iter.max = 100, nstart = 1)
    valores$cluster <- cluster$cluster
        
    ## hacemos el random para cada clase encontrada, así nos aseguramos de poder seleccionar la deseada
    for (mi_cluster in 1:n_cluster){
      solo_pinos <- valores[valores$cluster == mi_cluster, ]
      numero_pinos <- ceiling(nrow(solo_pinos)/numero_pixeles_por_pino)
      ## seleccionamos el número_pinos aleatorios de la selección de pixeles.
      mis_pinos <- solo_pinos[sample(nrow(solo_pinos), numero_pinos), ]
      mis_pinos <- SpatialPointsDataFrame(coords=subset(mis_pinos, select=c(x, y)), data = subset(mis_pinos, select=-c(hsv)))
      proj4string(mis_pinos)=CRS(proj4string(mi_zona))      
      writeOGR(mis_pinos, ".", paste("poligono", n_poligono, "clase", mi_cluster, sep="_"), driver="ESRI Shapefile", overwrite_layer=T)      
    }
        
    n_poligono <- n_poligono + 1
  }
  
}

generar_shp_clases("zona.tif", "pinares_linaria")

#for %f in (poligono_*.shp) do (ogr2ogr -update -append pinos.shp %f  -f “esri shapefile” -nln merge )
