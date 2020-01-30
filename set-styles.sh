#!/bin/bash
# this script adds a new style entry to the layer definitions by REST

printf "\nFor reading properly the input file, please add a blank line at its end.\n\n"

# import arguments
source ./config.env

debug=false
date=$(date +%F-%H_%M)
dataDir='data/'"$host"'/styles/'"$date"'/'
mkdir -p $dataDir
stylesDir='data/'"$host"'/styles/'

# Reads a list sets styles by REST for each layer

while IFS=';' read -r workspace layer style eol
do
    workDir="$dataDir""$workspace"'/'
    mkdir -p $workDir

	restUrl="$protocol""$host"':'"$port"'/geoserver/rest/layers/'
	
	curl -u $gsUser -X PUT -d '<layer><defaultStyle><name>'"$style"'</name></defaultStyle></layer>' -H "Content-Type: text/xml" "$restUrl"'/'"$workspace"':'"$layer"'.xml'
	
	if [ "$debug" ]
    then
        echo 'Vinculando estilo '"$style"' a la capa '"$workspace"':'"$layer"
    fi

done < $stylesLayers

printf "\nEnd of process.\n\n"
