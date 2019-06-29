#!/bin/bash
# this script creates cache of all layers in GeoServer by REST using a file with a list of the their names

printf "\nFor reading properly the input file, please add a blank line at its end.\n\n"

# import arguments
source ./config.env

debug=false
date=$(date +%F-%H_%M)
dataDir='data/'"$host"'/cache/'"$date"'/'
mkdir -p $dataDir

# makes an URL for sending the request with the arguments in config file
baseSeedUrl='http://'"$host"'/geoserver/gwc/rest/seed/'

# Read a list and requests cache operations by REST for certain layers

while IFS=';' read -r workspace layerName srs minx miny maxx maxy zoomStart zoomStop format type threads eol
do
	workDir="$dataDir""$layerName"'/'
    mkdir -p $workDir

## Cache creation

	# adds abstract xml tag if not empty    
    if [ ! -z "$workspace" ]
    then
        xmlWorkspace="$workspace"':'
    else
        xmlWorkspace=''
    fi

	# seed url
	# EVALUAR SI LA CAPA ESTA O NO EN WORKSPACE
	restSeedUrl="$baseSeedUrl""$workspace""$layerNamePrefix""$layerName"'.xml'

	# creates a string with layer's parameters in XML
	seedXml='<seedRequest><name>'"$xmlWorkspace""$layerNamePrefix""$layerName"'</name><bounds><coords><double>'"$minx"'</double><double>'"$miny"'</double><double>'"$maxx"'</double><double>'"$maxy"'</double></coords></bounds><srs><number>'"$srs"'</number></srs><zoomStart>'"$zoomStart"'</zoomStart><zoomStop>'"$zoomStop"'</zoomStop><format>'"$format"'</format><type>'"$type"'</type><threadCount>'"$threads"'</threadCount></seedRequest>'
	# stores the xml in a temporary file
	echo $seedXml > "$workDir""$layerName".xml
	# creates cache for current layer
	curl -v -u $gsUser -XPOST -H "Content-type: text/xml" -T "$workDir""$layerName".xml $restSeedUrl

done < $cacheList

printf "\nEnd of process.\n\n"