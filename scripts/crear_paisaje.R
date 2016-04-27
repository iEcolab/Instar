library(raster)

path_asc <- "Dia_2001-01-26_ET0.asc"

asc <- raster(path_asc)

paisaje <- asc / asc
paisaje[is.na(paisaje)] <- 0

summary(paisaje)

writeRaster(paisaje, "paisaje.asc")
