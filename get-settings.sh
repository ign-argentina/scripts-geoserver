#!/bin/bash
# this script gets GeoServer settings by REST

# import arguments
source ./config.env

debug=false
date=$(date +%F-%H_%M)
dataDir='data/'"$host"'/settings/'"$date"'/'
mkdir -p $dataDir

restEndpoint='http://'"$host"'/geoserver/rest/'

settings='settings,workspaces,namespaces,styles,layers,layergroups,fonts,templates'

IFS=',' read -r -a array <<< "$settings"
for element in "${array[@]}"; do
    curl -v -u $gsUser -XGET "$restEndpoint""$element"'.xml' -o "$dataDir""$element"'.xml'
done

services='wms,wmts,wfs,wcs'
mkdir -p "$dataDir"'services'

IFS=',' read -r -a array <<< "$services"
for element in "${array[@]}"; do
    curl -v -u $gsUser -XGET "$restEndpoint"'services/'"$element"'/settings.xml' -o "$dataDir"'services/'"$element"'.xml'
done

security='masterpw,catalog,services,rest,layers'
mkdir -p "$dataDir"'security'

IFS=',' read -r -a array <<< "$security"
for element in "${array[@]}"; do
    if [ "$element" = "masterpw" ] 
    then
        curl -v -u $gsUser -XGET "$restEndpoint"'security/'"$element"'.xml' -o "$dataDir"'security/'"$element"'.xml'
    else
        curl -v -u $gsUser -XGET "$restEndpoint"'security/acl/'"$element"'.xml' -o "$dataDir"'security/'"$element"'.xml'
    fi
done

gwc='diskquota,layers'
mkdir -p "$dataDir"'gwc'

IFS=',' read -r -a array <<< "$gwc"
for element in "${array[@]}"; do
    curl -v -u $gsUser -XGET 'http://'"$host"'/geoserver/rest/'"$element"'.xml' -o "$dataDir"'gwc/'"$element"'.xml'
done
