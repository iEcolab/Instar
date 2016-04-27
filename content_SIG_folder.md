# Content of the folder "sig"

This file describes the content of the folder called *sig*, located out of the git

* *pradosdelrey.png*: screenshot showing the core area where Instar will be executed in Baza. This area is similar to Cortijuela in Sierra Nevada.
* *area _ baza _ grande.shp*: vectorial delineation of the area of interest.
* *raster_grande_30m.asc*: Digital elevation model obtained from *mde_20m_mta* (NAS iecolab *Informacion ambiental*).
  * Clip the ArcInfo grid with *area _ baza _ grande.shp* using ArcMap.
  * Resample the obtained grid to 30 m.
  * Export the ArcInfo grid to .asc format