install.packages(c("rgdal", "rgeos"), dep = T, type = "source")
install.packages(c("classInt"), dep = T)
library(raster)
library(rgdal)
library(rgeos)

library(sp)
library(rgdal)
library(classInt)
library(RColorBrewer)

set.seed(69)

setwd("~/Desktop/original")

## leemos la zona
mosaico <- brick("zona.tif")

epoly <- as(extent(mosaico), "SpatialPolygons")
## (assuming your extents really are in d's projection)
proj4string(epoly) <- CRS(proj4string(mosaico))
cropd <- SpatialPolygonsDataFrame(epoly, data.frame(x = 1), match.ID = FALSE) 

## leemos el shape de los usos del suelo, o cualquier otro que tenga info sobre las posibles manchas de pinos.
usos_ <- readOGR(".", "usos_mapa5605s_pinos")
projection(usos_) <- CRS("+proj=utm +zone=30 +datum=WGS84 +units=m +no_defs")
usos <- spTransform(usos_, CRS(proj4string(mosaico)))  

res <- gIntersection(usos, cropd, byid = T)
writeOGR(res, ".", "usos_mapa5605s_pinos_v2", driver="ESRI Shapefile", overwrite_layer=T)

n_poligono <- 1
for (area in res){
  
  mi_zona <- crop(mosaico, area)
  mi_zona <- mask(mi_zona, area)
  plot(mi_zona)
  plot(area)
  
  ## obtenemos un data.frame con x.y (centroides), y valor de rgb.
  valores <- as.data.frame(mi_zona, xy = TRUE, na.rm = T)
  
  ## convertimos los valores a HSV
  rgb <- sapply(subset(valores, select=c("zona.1", "zona.2", "zona.3")), as.factor)
  rgb <- matrix(sapply(rgb, as.numeric), ncol=3)
  mi_hsv <- t(rgb2hsv(t(rgb)))
  valores$hsv <- mi_hsv
  
  ## hacemos el cluster    
  n_cluster <- 5
  #cluster <- kmeans(valores$hsv, n_cluster, iter.max = 100, nstart = 1)
  cluster <- kmeans(subset(valores, select=c(zona.1, zona.2, zona.3)), n_cluster, iter.max = 100, nstart = 1)
  valores$cluster <- cluster$cluster
  
  ## vamos a calcular las medias
  medias_cluster <- data.frame()
  for (mi_cluster in 1:n_cluster){    
    
    solo_pinos <- valores[valores$cluster == mi_cluster, ]
    
    medias <- apply(valores[valores$cluster == mi_cluster, ], 2, mean)
    medias <- as.data.frame(t(medias))
    medias$cluster <- mi_cluster
    medias_cluster <- rbind(medias_cluster, medias)    
    
    solo_pinos <- subset(solo_pinos, select=-c(hsv))
    coordinates(solo_pinos) =~x+y
    ## definimos el sistema de coordenadas WGS84
    proj4string(solo_pinos)=CRS(proj4string(mi_zona))      
    writeOGR(solo_pinos, ".", paste("cluster", mi_cluster, sep="_"), driver="ESRI Shapefile", overwrite_layer=T)
        
  }
  medias_cluster <- medias_cluster[order(medias_cluster$zona.1), ]
  cluster_pino <- medias_cluster[2,]$cluster
  
  ## obtenemos el último cluster (suele ser el de los pinos)
  solo_pinos <- valores[valores$cluster == cluster_pino, ]
  numero_pinos <- ceiling(nrow(solo_pinos)/10)
  ## seleccionamos el número_pinos aleatorios de la selección de pixeles.
  mis_pinos <- solo_pinos[sample(nrow(solo_pinos), numero_pinos), ]
  mis_pinos <- SpatialPointsDataFrame(coords=subset(mis_pinos, select=c(x, y)), data = subset(mis_pinos, select=-c(hsv)))
  proj4string(mis_pinos)=CRS(proj4string(mi_zona))      
  writeOGR(mis_pinos, ".", paste("mis_pinos", n_poligono, sep="_"), driver="ESRI Shapefile", overwrite_layer=T)
    
  
  n_poligono <- n_poligono + 1
}
