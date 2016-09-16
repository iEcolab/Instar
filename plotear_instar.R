setwd("C:/Users/iecolab/Google Drive/Instar/implementaciones/instar_baza/scripts/git_Instar_baza/git_Instar_baza")

#install.packages("lubridate")
library(lubridate) # Para las fechas
INSTAR<-read.table("instar_bz008.txt", header=T, sep=",", dec=".")
INSTAR$fecha <-as.Date(INSTAR$fecha, format="%m-%d-%y")
INSTAR$yday <- yday(INSTAR$fecha) # anadimos el dia del anio con el paquete lubridate
INSTAR$year <- year(INSTAR$fecha) # anadimos el anio con el paquete lubridate
INSTAR$biociclo <- NULL
#write.csv(INSTAR, file = "datos_instar_bz008.csv", row.names=FALSE, na="")

COPLAS<-read.csv("zona_baza.csv", header=TRUE, sep=",")
names(COPLAS)[1] <- "RODAL"
rodal<-subset(COPLAS, RODAL == "GR023008")

rodal<-rodal[-c(1,2, 23),]

# Grafico datos INSTAR

```{r}
# Crear vectores de datos (ahora esta con los 29-feb, decidir si mostrarlos o no y modificar codigo)

huevos <- INSTAR$huevo[5748:7573]
l1 <- INSTAR$L1[5748:7573]
l2 <- INSTAR$L2[5748:7573]
crisalidas <- INSTAR$crisalida[5748:7573]
exergia <- INSTAR$exergia[5748:7573]
fecha <- INSTAR$fecha[5748:7573]

# Para seleccionar solo un trozo de los datos se especifican las filas que se quieren mostrar:
# l1 <- INSTAR_bz2$l1[5748:7573] (4 ciclos completos)
```

```{r}
par(mar=c(5, 4, 4, 5) + 0.1) # Ampliar margenes

plot(fecha, huevos, type="l", col="red",xlab="Fecha", ylab="Numero de individuos", ylim=c(0,max(huevos))) # primera serie, es la que define el eje Y

par(new=TRUE) # permite anadir graficos encima
plot(fecha, l1, type="l", col="blue",xlab="", ylab="", ylim=c(0,max(huevos)), yaxt="n", xaxt="n") # segunda serie

par(new=TRUE)
plot(fecha, l2, type="l", col="green",xlab="", ylab="", ylim=c(0,max(huevos)), yaxt="n", xaxt="n") # tercera serie

par(new=TRUE)
plot(fecha, crisalidas, type="l", col="orange",xlab="", ylab="", ylim=c(0,max(huevos)), yaxt="n", xaxt="n") # cuarta serie

par(new=TRUE)
plot(fecha, exergia, type="l", col="black",xaxt="n",yaxt="n",xlab="",ylab="", lty="dotted") # quinta serie

axis(4) # configuracion del eje Y derecho
mtext("Vigor (%)",side=4,line=3)

legend("topleft",col=c("red","blue","green","orange", "black"),lty=1,legend=c("Huevos","L1", "L2","Crisalida", "Vigor"))

#install.packages("Hmisc")
#library(Hmisc)
#minor.tick(nx=10,ny=1) #para anadir minor ticks (instalar paquete "Hmisc" primero)
