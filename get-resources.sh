#!/bin/bash
# this script gets GeoServer style resources by REST

# import arguments
source ./config.env

debug=false
date=$(date +%F-%H_%M)
dataDir='data/'"$host"'/styles/'"$date"'/'
mkdir -p $dataDir

restEndpoint='http://'"$host"'/geoserver/rest/'

while IFS=';' read -r directory workspace resources
do
    workDir="$dataDir""$workspace"'/'
    mkdir -p $workDir

    IFS=',' read -r -a array <<< "$resources"
    for element in "${array[@]}"; do
        curl -v -u $gsUser -XGET "$restEndpoint"'resource/styles/'"$element" -o "$workDir""$element"
    done

done < $stylesList

