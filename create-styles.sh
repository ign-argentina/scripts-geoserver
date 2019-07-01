#!/bin/bash
# this script creates style layer definitions (SLD)in GeoServer by REST using as input a file with a list of names and use them creating the query for each one

printf "\nFor reading properly the input file, please add a blank line at its end.\n\n"

# import arguments
source ./config.env

debug=false
date=$(date +%F-%H_%M)
dataDir='data/'"$host"'/styles/'"$date"'/'
mkdir -p $dataDir
stylesDir='data/'"$host"'/styles/'

# makes an URL for sending requests
restUrl="$protocol""$host"'/geoserver/rest/styles/'
restSourceUrl="$protocol""$host"'/geoserver/rest/source/styles/'

# Read features in a list and requests layer (SQL view) creation by REST for each one

while IFS=';' read -r file workspace resources eol
do
    workDir="$dataDir""$workspace"'/'
    mkdir -p $workDir

	## Styles creation

    # adds workspace xml tag if isn't empty
    if [ ! -z "$workspace" ]
    then
        xmlWorkspace='<workspace><name>'"$workspace"'</name></workspace>'
		restUrl="$protocol""$host"'/geoserver/rest/workspaces/'"$workspace"'/styles/'
		restSourceUrl="$protocol""$host"'/geoserver/rest/resource/workspaces/'"$workspace"'/styles/'
		stylesDir='data/'"$host"'/styles/'"$workspace"'/'
    else
        xmlWorkspace=''
    fi

	# Create style pointer
	xmlStyle='<style><name>'"$file"'</name>'"$xmlWorkspace"'<format>sld</format><languageVersion><version>1.1.0</version></languageVersion><filename>'"$file"'.sld</filename></style>'
	
	# stores the XML in file
	echo $xmlStyle > "$workDir""$file"'.xml'
	
	curl -v -u $gsUser -XPOST -H 'Content-type: text/xml' -d "$xmlStyle" "$restUrl"

	# SLD uploading
	curl -v -u $gsUser -XPUT -H 'Content-type: application/vnd.ogc.se+xml' -d @"$stylesDir""$file"'.sld' "$restUrl""$file"

	IFS=',' read -r -a array <<< "$resources"
	for resource in "${array[@]}"; do
		echo 'Uploading resource '"$resource"' in workspace '"$workspace"'\n'
		# Upload style's resources
		curl -v -u $gsUser -XPUT -H 'Content-type: image/svg+xml' -d @"$stylesDir""$resource" "$restSourceUrl""$resource"
	done

	resources=''
	workspace=''

done < $stylesList

printf "\nEnd of process.\n\n"
