#!/bin/bash
# this script creates raster coverages in GeoServer by REST using as input a file with a list of names and use them creating the query for each one

printf "\nFor reading properly the input file, please add a blank line at its end.\n\n"

# import arguments
source ./config.env

debug=false
date=$(date +%F-%H_%M)
dataDir='data/'"$host"'/rater-layers/'"$date"'/'
mkdir -p $dataDir

# Read features in a list and requests layer creation by REST for each one

while IFS=';' read -r workspace datastore dataType filePath fileName layerName layerTitle srs endLine
do
	
	## Workspace creation
	workDir="$dataDir""$workspace"'/'
    mkdir -p $workDir
    if [ "$workspace" ]
    then
        # creates a workspace if doesn't exist
        workspaceUrl="$protocol""$host"':'"$port"'/geoserver/rest/workspaces'
		
		if [ "$defaultWorkspace" == "$workspace" ]
        then
			workspaceUrl="$workspaceUrl"'?default=true'
		fi
        
        if [ "$debug" ]
        then
            curl -v -u $gsUser -XPOST -H "Content-type: text/xml" -d '<workspace><name>'"$workspace"'</name></workspace>' $workspaceUrl
            echo 'Creando workspace '"$workspace"
        fi
    fi

	## Data store creation
	if [ "$datastore" ]
    then
		
		# generate full file path for datastore
		if [ "$dataType" = 'ImageMosaic' ]
		then
			completeFilePath="$filePath"
		else
			completeFilePath="$filePath""$fileName"
		fi
        
		# string with datastore's parameters in XML
        xmlDatastore='<coverageStore><name>'"$datastore"'</name><workspace>'"$workspace"'</workspace><enabled>true</enabled><type>'"$dataType"'</type><url>'"$completeFilePath"'</url></coverageStore>'
        
        # stores the XML in a temporary file
        echo $xmlDatastore > "$workDir""$datastore".xml
        
        # creates a datastore if doesn't exist (with a database connection)
        dataStoreUrl="$protocol""$host"':'"$port"'/geoserver/rest/workspaces/'"$workspace"'/coveragestores?configure=all'
        
        if [ "$debug" ]
        then
            curl -v -u $gsUser -X POST -H "Content-type: text/xml" -T "$workDir""$datastore".xml $dataStoreUrl
            echo 'Creando datastore '"$datastore"
        fi
    fi

	
	## Layers creation
	
	# makes an URL for sending the request with the arguments in config file
    restFeatureUrl="$protocol""$host"':'"$port"'/geoserver/rest/workspaces/'"$workspace"'/coveragestores/'"$datastore"'/coverages'
    
	# string with layer's parameters in XML
	xmlLayer='<coverage><name>'"$layerName"'</name><title>'"$layerTitle"'</title><srs>EPSG:'"$srs"'</srs></coverage>'
	
	# stores the XML in a temporary file
	echo $xmlLayer > "$workDir""$layerName".xml
	
	if [ "$debug" ]
    then
        # send POST request for creating each layer in GeoServer using the XML
        curl -v -u $gsUser -XPOST -H 'Content-type: text/xml' -T "$workDir""$layerName".xml $restFeatureUrl
        echo 'Creando capa '"$layerName"
    fi

done < $rasterLayersList

printf "\nEnd of process.\n\n"
