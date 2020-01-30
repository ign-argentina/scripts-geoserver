#!/bin/bash
# this script creates raster coverages in GeoServer by REST using as input a file with a list of names and use them creating the query for each one

printf "\nFor reading properly the input file, please add a blank line at its end.\n\n"

# import arguments
source ./config-raster.sh

# creates a workspace if doesn't exist
workspaceUrl="$host"'/geoserver/rest/workspaces'
curl -v -u $gsUser -XPOST -H "Content-type: text/xml" -d '<workspace><name>'"$workspace"'</name></workspace>' $workspaceUrl

# Read features in a list and requests layer creation by REST for each one

while IFS=';' read -r datastore dataType filePath fileName layerName layerTitle srs maxx maxy minx miny
do

## Data store creation

    # string with datastore's parameters in XML
    xmlDatastore='<coverageStore><name>'"$datastore"'</name><workspace>'"$workspace"'</workspace><enabled>true</enabled><type>'"$dataType"'</type><url>'"$filePath""$fileName"'</url></coverageStore>'
    # stores the XML in a temporary file
    echo $xmlDatastore > database.xml
    # creates a datastore if doesn't exist (with a database connection)
    dataStoreUrl="$host"'/geoserver/rest/workspaces/'"$workspace"'/coveragestores?configure=all'
    curl -v -u $gsUser -X POST -H "Content-type: text/xml" -T database.xml $dataStoreUrl  

    # makes an URL for sending the request with the arguments in config file
    restFeatureUrl="$host"'/geoserver/rest/workspaces/'"$workspace"'/coveragestores/'"$datastore"'/coverages'

## Layers creation

	if [ -z "$maxx" ]
	then

        # string with layer's parameters in XML
        xmlLayer='<coverage><name>'"$layerName"'</name><title>'"$layerTitle"'</title><srs>'"$srs"'</srs></coverage>'
        # stores the XML in a temporary file
        echo $xmlLayer > rasterLayer.xml
        # send POST request for creating each layer in GeoServer using the XML
        curl -v -u $gsUser -X POST -H 'Content-type: text/xml' -T rasterLayer.xml $restFeatureUrl
    else
        # string with layer's parameters in XML
        xmlLayer='<coverage><name>'"$layerName"'</name><title>'"$layerTitle"'</title><enabled>true</enabled><advertised>true</advertised><srs>'"$srs"'</srs><latLonBoundingBox><minx>'"$minx"'</minx><maxx>'"$maxx"'</maxx><miny>'"$miny"'</miny><maxy>'"$maxy"'</maxy><crs>'"$srs"'</crs></latLonBoundingBox></coverage>'
        # stores the XML in a temporary file
        echo $xmlLayer > rasterLayer.xml
        # send POST request for creating each layer in GeoServer using the XML
        curl -v -u $gsUser -X POST -H 'Content-type: text/xml' -T rasterLayer.xml $restFeatureUrl
    fi

done < $layersList

printf "\nEnd of process.\n\n"
