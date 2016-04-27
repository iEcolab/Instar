## script para el calculo del mapa de radiación solar

install.packages(c("insol"), dep = T)
library("insol")
library(raster)

lat <- 37.085906
lng <- -3.474475
tmz <- +1 ## madrid
  
## path y variables
path_mde <- "/Users/iecolab/Desktop/mde(1)/mde_snev1.bip"

## leemos el MDE
dem <- raster(path_mde)

writeRaster(dem, "../sig/mde_snev.tif")

aspectdem <- aspect(cgrad(dem),degrees=TRUE)
aspectdem <- raster(aspectdem,crs=projection(dem))
extent(aspectdem) <- extent(dem)
plot(aspectdem,col=grey(1:100/100))

# contour(dem,col='sienna1',lwd=.5,nlevels=30,add=TRUE)

jd2012 <- JD(seq(ISOdate(2012,1,1),ISOdate(2012,12,31),by='day'))
duracion_dia <- daylength(lat,lng,jd2012,tmz)

plot(duracion_dia[,3],xlab='Day of the year',ylab='day length [h]',ylim=c(0,24))
