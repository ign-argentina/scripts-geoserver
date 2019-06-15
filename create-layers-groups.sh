#!/bin/bash
# this script creates layer groups in GeoServer by REST

printf "\nFor reading properly the input file, please add a blank line at its end.\n\n"

# import arguments
source ./config.env

debug=false
date=$(date +%F-%H_%M)
dataDir='data/'"$host"'/layergroups/'"$date"'/'
mkdir -p $dataDir

# makes an URL for sending requests
restUrl="$host"'/geoserver/rest/layergroups'

# Read features in a list and requests layer (SQL view) creation by REST for each one

while IFS=';' read -r name mode title workspace srs abstractTxt layersList stylesList eol
do

	## Groups creation

	IFS=',' read -r -a array <<< "$layersList"
	for layer in "${array[@]}"; do
		# Creates XML content for publishables node
		singleLayer='<published type="layer"><name>'"$layer"'</name><atom:link rel="alternate" href="'"$host"'/geoserver/rest/workspaces/'"$workspace"'/layers/'"$layer"'.xml" type="application/xml"/></published>'

		# Appends layer to publishables string
		xmlPublishables+=$singleLayer
	done

	IFS=',' read -r -a array <<< "$stylesList"
	for style in "${array[@]}"; do
		# Creates XML content for styles node
		singleStyle='<style><name>'"$style"'</name><atom:link rel="alternate" href="'"$host"'/geoserver/rest/styles/'"$style"'.xml" type="application/xml"/></style>'

		# Appends style to styles string
		xmlStyles+=$singleStyle
	done

		# Creates XML file
		xmlString='<layerGroup><name>'"$name"'</name><mode>'"$mode"'</mode><title>'"$title"'</title><abstractTxt>'"$abstractTxt"'</abstractTxt><publishables>'"$xmlPublishables"'</publishables><styles>'"$xmlStyles"'</styles></layerGroup>'

		# stores the XML in a temporary file
		echo $xmlString > "$dataDir""$name"'.xml'

		# XML uploading
		curl -v -u $gsUser -XPOST -d @"$dataDir""$name"'.xml' -H "Content-type: text/xml" $restUrl

		layersList=''
		singleLayer=''
		xmlPublishables=''
		stylesList=''
		singleStyle=''
		xmlStyles=''

done < $groupsList

printf "\nEnd of process.\n\n"
