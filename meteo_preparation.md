# Data preparation to execute Instar in Baza mountains

## Meteo data

This section describes how to download and process the meteorological information.

* The file *meteo _ stations.xlsx* (located in the folder *anciliary _ data*, out of the git folder) contains a list with the meteo stations to be used in this study. All of them have been obtained from CLIMA information system. 
* The meteo information is stored in a huge database owned by the REDIAM. We can access that database following this [URL](http://gdfa.ugr.es/rediam/clima) (user: iista; pwd:Askfjbonet). Follow these steps:
  + Select the target meteo stations and the widest possible temporal range (from 1900 to present)
  + Select "diarias" variables.
  + Select the following variables: PD1, PD23, 0D1, RD1, TD1, TD2, TD4, UDS1.
  + Export to XML format. Please save the file in *anciliary _ data* folder.
  + Once donwloaded proceed again:
  + Select the target meteo stations and the widest possible temporal range (from 1900 to present)
  + Select "intradiarias" variables
  + Select the variable called PI1
  + Export to XML format. Plase save the file in *anciliary _ data* folder.
* Once we have all the raw data downloaded, we will assess the consistency of the time series. Javier Herrero has created a very nice program to do this task. Click [here](http://gdfa.ugr.es/herrero/20150618MeteoWiMMatlab.rar) to download it. You also need to install the [64 bits Matlab redistributable execution engine](http://gdfa.ugr.es/herrero/MCRInstaller_R2012a_64bits.exe). The software also creates a report showing the gaps in the time series as well as the overlaping parts. This matlab program implement the following workflow:

```
XML -> STATION1_VAR1.TXT, STATION1_VAR2.TXT ->VAR1, VAR2
```


