   ;; tutorial: https://sites.google.com/site/manualnetlogo/ejercicio-17-operaciones-sobre-listas
;; diccionario comandos: http://ccl.northwestern.edu/netlogo/docs/index2.html
;; Extensiones
extensions [
  gis
  ;; https://github.com/colinsheppard/time/
  time
  ;; https://github.com/NetLogo/Rnd-Extension#readme
  rnd
  ;; http://ccl.northwestern.edu/netlogo/docs/arraystables.html
  table
  ;; https://github.com/NetLogo/CSV-Extension#from-file
  csv
  ;; https://github.com/NetLogo/Custom-Logging-Extension/#readme
  ;; custom-logging
]

;; Variables globales
globals [
  ayer ;; guarda el día de ayer
  dia ;; es hoy
  area ;; extensión del bounding box del area de trabajo

  ;; variable que contiene la lista de los patches que conforman el escenario
  mi_paisaje

  ;; lista de orientaciones
  orientaciones ;; list de los ángulos de cada orientación
  orientaciones-idoneidad ;; list de la idoneidad de las posiciones, mayor valor, peor idoneidad
  orientaciones-posiciones ;; list de nombres de las posiciones

  ;; pinos
  pinos-dataset
  max-ideoneidad-mariposas

  ;; Variables Globales según UI
  ;; estratos-altura-hospedador ;; nos valdrá para saber cuanta carga de procesionaria puede tener
  ;; porc-inicial-mariposas-fecundadas

  ;; variables de estado del paisaje
  stat_tmin
  stat_tmax
  stat_precipitacion
  stat_radiacion
  stat_tmedia

  ;; variables de estado de la plaga
  stat_huevo
  stat_l1
  stat_l2
  stat_crisalida

  stat_l1_altitud
  stat_l2_altitud
  stat_crisalida_altitud

  ;; variables de estado de los hospedadores
  stat_hospedadores

  ;; ficheros de salida
  tabla_huevos

  ;; fecha primeros sucesos
  fecha_huevos
  fecha_l1
  fecha_l2
  fecha_crisalida
  fecha_mariposas

]

;; Entidades
breed [hospedadores hospedador]
breed [bolsones bolson]
breed [mariposas mariposa]
breed [crisalidas crisalida]

;; Propiedades Paisaje
patches-own [
  elevacion
  tmedia
  tmax
  tmin
  radiacion
  precipitacion

  ;; 8 - Encinar, 7 - Encinar+pinar, 6 - Pinar, 5 - Matorral+pinos+encinas, 4 - Matorral+encinar, 3 - Matorral+pinar, 2 - Matorral, 1 - Suelo desnudo
  cobertura_suelo

  ;; variables de salida en ASC
  asc_huevos
  asc_l1
  asc_l2
  asc_crisalidas
  asc_exergia_hospedador

  paisaje
]

;; Propiedades Hospedador
hospedadores-own [
  especie
  exergia
  altura
  vecinos
  idoneidad-mariposa
]

;; Propiedades Bolson
bolsones-own [
  fase
  exergia
  altura
  orientacion_hospedador
  numero_individuos ;; número real de individuos vivos
  numero_individuos_puesta ;; valor inicial de individuos
  numero_individuos_parasitados ;; para estadísticas
  numero_individuos_no_nacidos ;; para estadísticas
  dias_en_esta_fase
]

;; Propiedades Crisálida
crisalidas-own [
 exergia
 numero_individuos
 dias_en_esta_fase
]

;; Propiedades mariposa
mariposas-own [
  exergia
  sexo
  fecundada
]

;; INICIALIZACIÓN
to setup
  ca ; limpiamos todo

  ;; establecemos la semilla
  random-seed 137

  ;; Inicializamos las variables globales
  ;; ====================================
  set dia time:create "2001-06-25"
  ;; orientacion posicion 0 - N, NE, E, SE, S, SO, O, NO
  set orientaciones (list 22.5 67.5 112.5 157.5 202.5 247.5 292.5 337.5)
  ;; "X" tipo de orientacion
  ;; X peso de la orientacion, se usará para ponderar las cosas
  set orientaciones-posiciones [["N" 0.4] ["NE" 0.9] ["E" 0.9] ["SE" 0.9] ["S" 0.6] ["SO" 0.3] ["O" 0.3] ["NO" 0.3]]
  set orientaciones-idoneidad (list 20 10 20 20 90 100 100 90)
  set max-ideoneidad-mariposas 0

  ;; establecemos las dimensiones del mundo en función de la capa
  set area gis:load-dataset "../sig/elevacion.asc"
  gis:set-world-envelope gis:envelope-of area

  ;; inicializamos el paisaje
  inicializar_paisaje

  ;; pintamos el paisaje
  pintar_paisaje

  ;; leemos la distribución de los pinos
  set pinos-dataset gis:load-dataset "../sig/pinos.shp"
  ;; inicializamos los pinos
  set-default-shape hospedadores "tree"
  inicializar_pinos

  ;; inicializamos los bolsones
  inicializar_huevos

  ;; inicializamos las crisálidas
  set-default-shape crisalidas "bug"

  ;; inicializamos la forma de las mariposas
  set-default-shape mariposas "butterfly"

  ;; inicializamos las tablas de salida
  set tabla_huevos lput (list "id" "numero_individuos" "nacidos" "no_nacidos" "parasitados" "altitud" "especie" "id_hospedador" "ano" "orientacion" "altura_hospedador") []

  ;; reset reloj
  reset-ticks
end

to go
  ;; qué dia fue ayer
  set ayer dia

  ;; incrementamos el día
  set dia time:plus dia 1 "days"

;  if (time:show dia "yyyy-MM-dd") = "2001-12-31" [
;    set dia time:create "2001-01-26"
    ;;stop
;  ]

  ;; leemos las variables del día
  leer_paisaje

  ;; actualizamos los bolsones
  actualizar_bolsones

  ;; actualizamos las crisálidas
  actualizar_crisalidas

  ;; actualizamos las mariposas
  actualizar_mariposas

  ;; actualizamos los hospedadores
  actualizar_hospedadores

  ;; si cambiamos de año, escribimos los resultados

  ;; stop
;  if (time:show dia "yyyy-MM-dd") = "2001-12-31" [
;    set dia time:create "2000-12-31"
    ;;stop
;  ]
  if (ticks = 10)
  [ pintar_paisaje_cobertura ]

  ;; avanzamos el tick
  tick
end

;; procedimiento para la puesta de un huevo en un hospedador
;; lo usamos en la inicialización y en el procedimiento de la puesta de huevos
;; por las mariposas
to poner_huevos_en_hospedador
      ;; marcamos los pinos infectados
      set color blue

      ;; creamos un bolson a una altura determinada 0-5 donde 0 es más bajo, y 5 es más alto.
      ;; con el comando hatch se heredan los atributos de su "padre", en este caso hospedador (xcor, ycor).
      hatch-bolsones 1 [
        ;; empezamos por la fase de HUEVO
        set fase "huevo"
        ;; establecemos su exergía como aleatorio entre 0-100
        set exergia random 100
        ;; altura dentro del hospedador (z)
        ;; TODO: parámetros
        set altura ceiling (min list (max list (random-normal 1 5) 0) 5)
        set hidden? true;; no queremos pintarlo
        ;; establecemos su posición en el hospedador
        ;;set orientacion_hospedador item 0 rnd:weighted-one-of orientaciones-posiciones [ item 1 ? ]
        set orientacion_hospedador rnd:weighted-one-of orientaciones-posiciones [ item 1 ? ]

        ;; establecemos el número inicial de individuos
        ;; según datos de estudios
        ;; TODO: parámetros
        set numero_individuos_puesta round random-normal 193.2 4.5
        set numero_individuos numero_individuos_puesta

        ;; dias máximo para esta fase
        ;; TODO: parámetros
        set dias_en_esta_fase 45

        ;; creamos un link entre el hospedador y el bolsón
        create-link-with myself ;; myself = hospedador

      ]  ;; fin crear bolsón

end

;; inicializamos los huevos
to inicializar_huevos

  ;; cantidad de mariposas
  let num_inicial_mariposas round(porc-inicial-mariposas-fecundadas * (count hospedadores) / 100.0 )

  ;; seleccionamos de entre los pinos existentes
  let pinos_infectados rnd:weighted-n-of-with-repeats num_inicial_mariposas hospedadores [ [ (1 - (idoneidad-mariposa / max-ideoneidad-mariposas)) ] of ? ]

  ;; generamos un bolsón con un número de individuos en función de los parámetros iniciales
  foreach pinos_infectados [
    ask ? [
      ;; usamos el procedimiento de poner huevos
      poner_huevos_en_hospedador
    ] ;; fin del ask-hospedador
  ] ;; fin del bucle

  set stat_huevo sum [numero_individuos] of bolsones
  set stat_l1 0
  set stat_l2 0
  set stat_crisalida 0

  set stat_l1_altitud 0
  set stat_l2_altitud 0
  set stat_crisalida_altitud 0

end

;; procedimiento que devuelve la lista ordenada
;; según la preferencia de la crisálida por los parches
;; a los que tiene acceso desde su posicion en el pino.
;; primero ordena por tipo de cobertura, y a dos coberturas iguales, la de menor distancia
to-report comparar_paisaje_crisalida [a b]
  ifelse ([cobertura_suelo] of a > [cobertura_suelo] of b)
   [ifelse (distance a < distance b) [report true] [report false]]
   [report true]
end

;; convertimos los datos del dataset en agentes pino
to inicializar_pinos

  foreach gis:feature-list-of pinos-dataset [
    let location gis:location-of (first (first (gis:vertex-lists-of ?)))
    create-hospedadores 1 [
      set color green
      set altura round random-normal 4 1
      set xcor item 0 location
      set ycor item 1 location

      set especie "Pinus Silvestre"       ;; TODO: establecer especie según SHP

      ;; establecemos una exergía inicial aleatoria máxima 100 en distribución normal con media 100 y desviación 10,
      set exergia min list (random-normal 100 10) 100
    ]
  ]

  ;; establecemos la lista de vecinos según la orientacion
  ask hospedadores [
    set vecinos map mis_vecinos orientaciones
    set idoneidad-mariposa sum (map [?1 * ?2] vecinos orientaciones-idoneidad)
    set max-ideoneidad-mariposas max list idoneidad-mariposa max-ideoneidad-mariposas
  ]

  ask hospedadores [
   set color scale-color green idoneidad-mariposa 0 max-ideoneidad-mariposas
  ]

  set stat_hospedadores mean [exergia] of hospedadores

end

;; devuelve el número de vecinos para un head determinado,
to-report mis_vecinos [orientacion]
  set heading orientacion
  report (count hospedadores in-cone-nowrap 1 45) - 1 ;; restamos uno para que no se cuente a si mismo.
end

;; esta función actualiza las variables de la entidad hospedador
;; con el paso del tiempo
to actualizar_hospedadores
  ask hospedadores [
    let numero_bolsones_l1 count link-neighbors with [breed = bolsones and fase = "l1"]
    let numero_bolsones_l2 count link-neighbors with [breed = bolsones and fase = "l2"]
    ;;let numero_comilones sum [numero_individuos] of link-neighbors

    ;; TODO: fórmula --> Exergía (t-1) + Producción primaria árbol(clima) – consumo_bolson(n_bolsones_y_exergía_bolson)
    ;; la actual supone que un bolsón en L1 consume el 0.8% de la exergía del pino
    ;; por el click del día se le suma el .5%
    set exergia min (list (exergia - numero_bolsones_l1 * 0.1)  100)
    set exergia min (list (exergia - numero_bolsones_l2 * 0.3)  100)
    set exergia min (list (exergia + 0.2) 100) ;; le sumamos la energia vital capaz de recuperar en un día

    ;; si no tengo bolsones encima, me pinto de mi color natural
    if count link-neighbors with [breed = bolsones] = 0
    [
      set color scale-color green idoneidad-mariposa 0 max-ideoneidad-mariposas
    ]

    ;; TODO: revisar esta operación
    ;; si no tengo exergía, mato los bolsones que tenga instalados
    ;; en realidad, deberían de cambiarse de pino, pero ahora los mato
    ;; y me quedo tan agustico ;)
    let bolsones_en_hospedador link-neighbors with [breed = bolsones]
    if ((exergia <= 0) and (count bolsones_en_hospedador > 0))
    [
      ask bolsones_en_hospedador [
        ;; matamos el bolsón
        die
      ]
    ] ;; fin del IF de eliminar los bolsones asociados

  ]

  ;; estadísticas
  let hospedadores_infectados count hospedadores with [count link-neighbors > 0]
  ifelse (hospedadores_infectados > 0) [
    set stat_hospedadores mean [exergia] of hospedadores with [count link-neighbors > 0]
  ][
    set stat_hospedadores mean [exergia] of hospedadores
  ]


end

;; esta función actualiza las variables de la entidad Bolsón
;; con el paso del tiempo
to actualizar_bolsones

  let ano time:get "year" dia

  ask bolsones[
    ;; valores del paisaje
    let mi_dia_temperatura tmedia
    let mi_dia_radiacion radiacion

    ;; qué hacemos con los huevos en cada día
    if (fase = "huevo")[
      ;; TODO: adaptar fórmula
      let max_parasitados (-1.351e+04 + -2.591e-02 * elevacion + 6.764e+00 * ano) / 45
      let parasitos ceiling (abs max_parasitados)
      set numero_individuos_parasitados numero_individuos_parasitados + parasitos
      set numero_individuos numero_individuos - parasitos

      ;; TODO: adaptar fórmula
      set dias_en_esta_fase dias_en_esta_fase - 1 - ifelse-value (tmax > 25) [item 1 orientacion_hospedador] [0]

    ];; fase huevo

    ;; qué hacemos con los L1 en cada día
    if (fase = "l1")[
      ;; ajustamos el número de individuos
      ;; TODO: fórmula --> N_individuos (t)  = N_individuos(t – 1) – calidad_comida(hospedador, t) * FACTOR
      let exergia_hospedador first [exergia] of link-neighbors ;; link-neighbors devuelve una lista de los links, como sólo tendremos uno, usamos el first
      let calidad_comida ((random (100 - exergia_hospedador)) / 100) * 0.01 ;; factor 1% de la importancia de la comida
      set numero_individuos numero_individuos - abs (ceiling (calidad_comida * numero_individuos))

      ;; ajustamos el número de ticks hasta l2
      ;; TODO: fórmula --> N_ticks(t-1) – 1(tick) – condiciones(clima) * orientación – calidad_comida(hospedador, t) * FACTOR
      set dias_en_esta_fase dias_en_esta_fase - 1 - ifelse-value (tmin > 9) [item 1 orientacion_hospedador] [0]

    ]

    ;; qué hacemos con los L2 en cada día
    if (fase = "l2")[
     ;; ajustamos el número de individuos
     ;; TODO: fórmula --> N_individuos (t – 1) – 1/(calidad_comida(hospedador, t)) * FACTOR – parasitismo(t) – condiciones(clima)
      let exergia_hospedador first [exergia] of link-neighbors ;; link-neighbors devuelve una lista de los links, como sólo tendremos uno, usamos el first
      let calidad_comida abs ((random (100 - exergia_hospedador)) / 100) * 0.1 ;; factor 10% de la importancia de la comida
      ;let parasitismo_l2 abs ceiling (random (numero_individuos * 0.05)) ;; un 5% del número de individuos
      let parasitismo_l2 abs (random 1)
      let condiciones_climaticas abs ifelse-value (tmin < 7) [ceiling (0.02 * numero_individuos)] [0] ;; factor 2% si las condiciones climáticas no son buenas
      set numero_individuos ceiling (numero_individuos - calidad_comida - parasitismo_l2 - condiciones_climaticas)

     ;; ajustamos el número de ticks hasta crisalida
     ;; TODO: fórmula --> N_ticks(t-1) – 1(tick) – condiciones(clima) * orientación
      set dias_en_esta_fase dias_en_esta_fase - 1 - ifelse-value (radiacion > 10) [item 1 orientacion_hospedador] [0] - ifelse-value (tmin > 15) [item 1 orientacion_hospedador] [0]
    ]

    ;; qué hacemos con las crisálidas en cada día

    if numero_individuos <= 0 [
        die
    ]

    ;; FIN fase HUEVO
    if (dias_en_esta_fase <= 0) and (fase = "huevo") [
      ;; algunos mueren por NO-Nacidos
      ;; TODO: parametrizar
      set numero_individuos_no_nacidos ceiling (random numero_individuos * 0.02)
      set numero_individuos numero_individuos - numero_individuos_no_nacidos

      ;; guardamos la estadística en una tabla para poder testear los resultados
      set tabla_huevos lput (list who numero_individuos_puesta numero_individuos numero_individuos_no_nacidos numero_individuos_parasitados elevacion (first [especie] of link-neighbors) (first [who] of link-neighbors) (time:get "year" dia) (item 0 orientacion_hospedador) altura) tabla_huevos

      ;; cambiamos de fase --> 30 días, y el mínimo 20; paper de Lucía: ;;TODO: poner referencias bibliográficas
      set dias_en_esta_fase 30
      set fase "l1"
    ]

    ;; FIN fase L1
    if (dias_en_esta_fase <= 0) and (fase = "l1") [
      ;; cambiamos de fase --> no mas de 7 meses (210) para la L2; TODO: testear según bibliografía TODO:
        set dias_en_esta_fase 210
        set fase "l2"
    ]

    ;; FIN fase L2
    if (dias_en_esta_fase <= 0) and (fase = "l2") [
      ;; TODO: parametrizar
      let distancia_maxima 10 ;; 20 x 30m = 600m^2
      let maximos_pinos 3 ;; 3 pinos como mucho en el parche para que sea seleccionado --> DENSIDAD en el parche

      ;; para el bolson seleccionado
      let del_bolson self

      ;; capturamos el hospedador del bolsón, lo necesitaremos para crear el vínculo entre el lugar del enterramiento
      ;; y el hospedador
      let mi_hospedador [other-end] of one-of [my-links] of del_bolson

      ;; buscamos el sitio donde enterrarse, buscamos de entre los parches que tenemos alrededor
      ;; ordenamos según una función que ordena según el tipo de cobertura del suelo, distancia entre el parche y el bolsón
      ;; sólo usamos los parches que tienen menos de maximos_pinos de hospedadores, así aseguramos que buscan el claro, calibrar en función
      ;; del tamaño del parche y del posible espacio por pino
      ;; TODO: ajusta la selección del parche para el enterramiento
      ;; TODO: comprobar que la imagen que se va dibujando concuerda con lo esperado
      ask first sort-by comparar_paisaje_crisalida patches with [distance myself <= distancia_maxima and count hospedadores-here <= maximos_pinos] [
         ;; creamos la crisálida
         sprout-crisalidas 1 [
           set numero_individuos [numero_individuos] of del_bolson
           set exergia [exergia] of del_bolson

           ;; desde marzo-Abril hasta junio-julio que emergen --> 5 meses (150)
           set dias_en_esta_fase 150

           ;; propiedades
           set hidden? false;; no queremos pintarlo

           ;; creamos el link entre la crisálida y el hospedador del que viene
           ;; TODO: valorar si el vínculo lo hacemos a nivel de bolsón o nivel de hospedador --> ahora hospedador
           create-link-with mi_hospedador;; del_bolson
         ]
      ]

      ;; una vez que hemos creado el grupo crisálida, podemos eliminar el agente bolsón
      die
    ]
  ]

  ;; calculamos estadísticas
  set stat_huevo sum [numero_individuos] of bolsones with [fase = "huevo"]
  set stat_l1 sum [numero_individuos] of bolsones with [fase = "l1"]
  set stat_l2 sum [numero_individuos] of bolsones with [fase = "l2"]

  ;; comentamos esta parte, era una prueba para ver la elevación
  ;;if (count bolsones with [fase = "l1"] > 0)[
  ;;  set stat_l1_altitud mean [elevacion] of bolsones with [fase = "l1"]
  ;;]
  ;;if (count bolsones with [fase = "l2"] > 0)[
  ;;  set stat_l2_altitud mean [elevacion] of bolsones with [fase = "l2"]
  ;;]

end

;; procedimiento que actualiza a las crisálidas
to actualizar_crisalidas

  ask crisalidas [

    ;; actualizamos el número de individuos
    ;; TODO: parametrizar
    set numero_individuos ceiling numero_individuos - random 1

    ;; modificamos la exergíá
    let mi_exergia exergia
    let numero_mariposas (min list 20 numero_individuos) ;; ERROR: numero_individuos

    if numero_individuos <= 0 [
        die
    ]

    ;; actualizamos el número de días en esta fase
    ;; TODO: parametrizar según lo que influya en esta fase
    set dias_en_esta_fase dias_en_esta_fase - 1

    ;; vamos a por la parte de mariposa
    if (dias_en_esta_fase <= 0) [

      ;; creamos tantas mariposas como individuos tengamos
      ask patch-here [
        sprout-mariposas numero_mariposas [
          set exergia mi_exergia ;; exergía heredada del bolsón y de la crisálida
          set sexo one-of [ "H" "M" ] ;; H - hembra, M - macho
          set fecundada false
          set hidden? true

          ifelse (sexo = "H")
          [set color red] ;; es H
          [set color brown] ;; es M

        ] ;; fin crear la mariposa
      ]

      ;; la crisálida, muere
      die

    ] ;; fin de crear las mariposas

  ] ;; fin ask crisalidas

  ;; ajustamos las estadísticas
  ifelse count crisalidas > 0
    [set stat_crisalida sum [numero_individuos] of crisalidas]
    [set stat_crisalida 0]

  ;; if (count crisalidas > 0)[
  ;;  set stat_crisalida_altitud mean [elevacion] of crisalidas
    ;; pintamos de nuevo el paisaje
  ;;  pintar_paisaje
  ;; ]

end

;; función que actualiza las mariposas
to actualizar_mariposas

  ;; para las mariposas hembras
  ;; TODO: el acto sexual
  ask mariposas with [sexo = "H"] [
    ;; buscamos pareja para fecundarnos ;)
    ;; TODO: lo hacemos teniendo en cuenta los X patches cercanos --> 4 patches
    let mariposas_machos mariposas with [sexo = "M"] in-radius 3
    ;; si encuentra pareja, aplicamos un % de fertilidad
    if mariposas_machos != nobody and (random 100 < 95)[
      ;; nos movemos a la mitad del camino entre las dos mariposas
      ;; TODO: realmente es necesario? es más que probable, que encuentre pareja de entre las crisálidas desarrolladas en su mismo bolson

      ;; cambiamos sus variables
      set fecundada true
      ;; set color pink
    ]
  ]

  ;; TODO: la puesta de huevos
  ;; pensar si es necesario hacerlo concurrentemente o de forma secuencial, creo que secuencial es suficiente
  ask mariposas with [sexo = "H" and fecundada = true][
    ;; seleccionamos un pino, el más cercano, con mejor medida de idoneidad, y que no tenga más de X huevos ya puestos
    let numero_max_puestas 12
    let maxima_distancia 10 ;; 10 x 30m
    let hospedadores_potenciales hospedadores in-radius maxima_distancia with [ (count link-neighbors with [breed = bolsones] <= numero_max_puestas) and exergia >= exergia-hospedador-seleccion-mariposa ] ;; el hospedador tiene que tener exergia digna de tener huevos
    ifelse (count hospedadores_potenciales > 0) [
      ask first sort-by comparar_hospedadores hospedadores_potenciales [
        ;; ponemos los huevos
        poner_huevos_en_hospedador
      ] ;; fin de seleccionar el hospedador
    ] ;; fin de testear que haya hospedadores cercanos
    [
      print (word "[actualizar_mariposas - " who "] No hay hospedadores cercanos")
    ] ;; si no hay hospedadores, mostramos un mensaje

  ]

  ;; TODO: sólo viven un día, así que las matamos a todas!
  ask mariposas [
    ;; morimos :(
    die
  ]

  ;; TODO: estadísticas

end

;; función que ordena los hospedadores según su idoneidad y cercanía
to-report comparar_hospedadores [ a b ]
  ifelse ([idoneidad-mariposa] of a > [idoneidad-mariposa] of b)
   [ifelse (distance a < distance b) [report true] [report false]]
   [report true]
end

;; función que guarda los resultados recolectados a los distintos ficheros
to escribir_resultados

  ;; escribimos la
  csv:to-file "./outputs/tabla_huevos.csv" tabla_huevos

end

;; Permite leer las variables del paisaje para el día establecido
to leer_paisaje

  ;; variable tipo template que nos servirá para ir generando el nombre de los asc del paisaje
  let path_asc word "../data/Dia_" time:show dia "yyyy-MM-dd"

  ;; actualizamos las variables del día
  gis:apply-raster gis:load-dataset (word path_asc "_T_m.asc") tmedia
  gis:apply-raster gis:load-dataset (word path_asc "_Tmx.asc") tmax
  gis:apply-raster gis:load-dataset (word path_asc "_Tmn.asc") tmin
  gis:apply-raster gis:load-dataset (word path_asc "_Rdr.asc") radiacion
  gis:apply-raster gis:load-dataset (word path_asc "_Pre.asc") precipitacion

  ;; actualizamos los patches que son paisaje
  set mi_paisaje patches with [paisaje = 1]

  ;; calculamos los agregados
  set stat_tmedia mean [tmedia] of mi_paisaje
  set stat_tmax mean [tmax] of mi_paisaje
  set stat_tmin mean [tmin] of mi_paisaje
  set stat_radiacion mean [radiacion] of mi_paisaje
  set stat_precipitacion mean [precipitacion] of mi_paisaje

end


;; Inicializamos el paisaje
to inicializar_paisaje

  ;; leemos la elevación
  gis:apply-raster gis:load-dataset "../sig/elevacion.asc" elevacion

  ;; leemos los pixeles que formaran parte del paisaje
  gis:apply-raster gis:load-dataset "../sig/paisaje.asc" paisaje

  ;; leemos el tipo de suelo
  gis:apply-raster gis:load-dataset "../sig/cobertura_suelo.asc" cobertura_suelo

end

;; Pintamos el paisahe
to pintar_paisaje

  ; This is the preferred way of copying values from a raster dataset
  ; into a patch variable: in one step, using gis:apply-raster.
  gis:apply-raster gis:load-dataset "../sig/elevacion.asc" elevacion

  ; Now, just to make sure it worked, we'll color each patch by its
  ; elevation value.
  let min-elevation gis:minimum-of area
  let max-elevation gis:maximum-of area

  ask patches
  [ ; note the use of the "<= 0 or >= 0" technique to filter out
    ; "not a number" values, as discussed in the documentation.
    ;; adaptamos la visualización, para cuando haya crisálidas, poder identificar qué parches son los preferidos.
    ifelse (stat_crisalida > 0)
    [
      set pcolor scale-color orange cobertura_suelo 1 8 ;; 1 - suelo desnuedo, 8 - Encinar
    ] ;; fin if de existencia de crisálidas
    [
      if (elevacion <= 0) or (elevacion >= 0)
      [ set pcolor scale-color red elevacion min-elevation max-elevation ]
    ] ;; fin de paisaje normal, sin crisálidas

  ]

end

to pintar_paisaje_cobertura
  ask patches [
    ;; pintamos según cobertura
    set pcolor scale-color orange cobertura_suelo 1 8 ;; 1 - suelo desnuedo, 8 - Encinar
  ]
end

;; función que guarda la densidad en formato asc para una fecha dada
to guardar_asc_paisaje
  ask patches [
    set asc_huevos sum [numero_individuos] of bolsones-here with [fase = "huevo"]
    set asc_l1 sum [numero_individuos] of bolsones-here with [fase = "l1"]
    set asc_l2 sum [numero_individuos] of bolsones-here with [fase = "l2"]
    set asc_crisalidas sum [numero_individuos] of crisalidas-here
    ifelse (count hospedadores-here > 0) [set asc_exergia_hospedador mean [exergia] of hospedadores-here] [set asc_exergia_hospedador -1]
  ]

  ;; variables raster
  gis:store-dataset gis:patch-dataset asc_huevos (word "outputs/" time:show dia "yyyy-MM-dd" "_huevos.asc")
  gis:store-dataset gis:patch-dataset asc_l1 (word "outputs/" time:show dia "yyyy-MM-dd" "_l1.asc")
  gis:store-dataset gis:patch-dataset asc_l2 (word "outputs/" time:show dia "yyyy-MM-dd" "_l2.asc")
  gis:store-dataset gis:patch-dataset asc_crisalidas (word "outputs/" time:show dia "yyyy-MM-dd" "_crisalidas.asc")

  ;; variables hospedador
  gis:store-dataset gis:patch-dataset asc_exergia_hospedador (word "outputs/" time:show dia "yyyy-MM-dd" "_exergia_hospedador.asc")

end






@#$#@#$#@
GRAPHICS-WINDOW
2
394
715
778
-1
-1
3.842
1
10
1
1
1
0
1
1
1
0
182
-91
0
0
0
1
ticks
30.0

BUTTON
3
10
98
43
Inicializar
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
101
10
196
43
Comenzar
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
268
10
677
207
Evolución diaria paisaje
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"tmax" 1.0 0 -5825686 true "" "plot stat_tmax"
"tmin" 1.0 0 -2382653 true "" "plot stat_tmin"
"tmedia" 1.0 0 -3508570 true "" "plot stat_tmedia"

MONITOR
714
440
804
485
Día
time:show dia \"yyyy-MM-dd\"
17
1
11

MONITOR
806
440
896
485
Hospedadores
count hospedadores
17
1
11

BUTTON
4
44
99
77
Comenzar
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
4
81
266
114
porc-inicial-mariposas-fecundadas
porc-inicial-mariposas-fecundadas
1
300
31
5
1
NIL
HORIZONTAL

MONITOR
714
394
804
439
Bolsones
count bolsones
17
1
11

PLOT
3
207
543
392
Evolución de la plaga
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"huevo" 1.0 0 -12895429 true "" "plot stat_huevo"
"L1" 1.0 0 -8053223 true "" "plot stat_l1"
"L2" 1.0 0 -13403783 true "" "plot stat_l2"
"Crisalida" 1.0 0 -865067 true "" "plot stat_crisalida"

BUTTON
100
44
197
77
CSV & ASC
escribir_resultados\nguardar_asc_paisaje
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
544
208
894
393
Evolución de los hospedadores
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Exergía" 1.0 0 -612749 true "" "plot stat_hospedadores"

MONITOR
805
394
895
439
Media Ind.
round (mean [numero_individuos] of bolsones)
17
1
11

PLOT
678
10
895
207
Radiación
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -1184463 true "" "plot stat_radiacion"

SLIDER
4
116
266
149
exergia-hospedador-seleccion-mariposa
exergia-hospedador-seleccion-mariposa
0
100
50
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
