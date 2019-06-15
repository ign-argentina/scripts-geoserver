#!/bin/bash
# this script creates cache of all layers in GeoServer by REST using a file with a list of the their names

printf "\nFor reading properly the input file, please add a blank line at its end.\n\n"

# import arguments
source ./config-seed.sh

# makes an URL for sending the request with the arguments in config file
baseSeedUrl="$host"'/geoserver/gwc/rest/seed/'

# Read a list and requests cache operations by REST for certain layers

while IFS=';' read -r layerName srs minx miny maxx maxy zoomStart zoomStop format type threadCount endline
do

## Cache creation

	# seed url
	# EVALUAR SI LA CAPA ESTA O NO EN WORKSPACE
	restSeedUrl="$baseSeedUrl""$workspace""$layerNamePrefix""$layerName"'.xml'

	# creates a string with layer's parameters in XML
	seedXml='<seedRequest><name>'"$workspace"':'"$layerNamePrefix""$layerName"'</name><bounds><coords><double>'"$minx"'</double><double>'"$miny"'</double><double>'"$maxx"'</double><double>'"$maxy"'</double></coords></bounds><srs><number>'"$srs"'</number></srs><zoomStart>'"$zoomStart"'</zoomStart><zoomStop>'"$zoomStop"'</zoomStop><format>'"$format"'</format><type>'"$type"'</type><threadCount>'"$threadCount"'</threadCount></seedRequest>'
	# stores the xml in a temporary file
	echo $seedXml > seed.xml
	# creates cache for current layer
	curl -v -u $gsUser -XPOST -H "Content-type: text/xml" -T seed.xml $restSeedUrl

done < $cacheList

printf "\nEnd of process.\n\n"