#!/bin/bash

printf "\nThis script compares a list of layers against those what exist in GeoServer.\n\n"

# import arguments
source ./config.env

debug=false
date=$(date +%F-%H_%M)
dataDir='data/'"$host"'/layers/'"$date"'/'
mkdir -p $dataDir
OUTFILE=$dataDir'layers-not-found.txt'

# Read features in a list and requests layer (SQL view) creation by REST for each one

while IFS=';' read -r workspace datastore schema table layerNamePrefix layerName layerTitle keywords advertised srs keyColumn filterField filterValue fields abstract style endLine
do
    URL="$protocol""$host"':'"$port"'/geoserver/rest/workspaces/'"$workspace"'/datastores/'"$datastore"'/featuretypes/'$layerName'.xml'
    
    REQUEST_STATUS=$(curl -u $gsUser --write-out '%{http_code}' --silent --output /dev/null $URL)
    
    if [ "$REQUEST_STATUS" != '200' ]
    then
        echo $workspace':'$layerName' not found!'
        echo $workspace':'$layerName >> "${OUTFILE}"
    fi
done < $layersList

printf "\nResults written to "$dataDir"layers-not-found.txt\n\n"
