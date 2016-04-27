#!/bin/bash

for f in ./poligono_*.shp;
do 
	/usr/local/bin/ogr2ogr -update -append merge.shp $f -f "ESRI Shapefile" -nln merge
done

