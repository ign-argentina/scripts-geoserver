#!/bin/bash
# this script creates layers that use WMS storage in GeoServer by REST using as input a file with a list of names and use them creating the query for each one

printf "\nFor reading properly the input file, please add a blank line at its end.\n\n"

# import arguments
source ./config.env

debug=false
date=$(date +%F-%H_%M)
dataDir='data/'"$host"'/wms-layers/'"$date"'/'
mkdir -p $dataDir

echo $layersWMSList

# Read features in a list and requests layer (SQL view) creation by REST for each one

while IFS=';' read -r workspace datastore capabilitiesURL layerNamePrefix layerName layerTitle keywords advertised srs abstract endLine
do
    
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

    if [ "$datastore" ]
    then
        # string with datastore's parameters in XML
        xmlDatastore='<wmsStore><name>'"$datastore"'</name><type>WMS</type><enabled>true</enabled><workspace><name>'"$workspace"'</name></workspace><capabilitiesURL>'"${capabilitiesURL//&/&amp;}"'</capabilitiesURL></wmsStore>'
        
        # stores the XML in a temporary file
        echo $xmlDatastore > "$workDir""$datastore".xml
        
        # creates a datastore if doesn't exist (with a database connection)
        dataStoreUrl="$protocol""$host"':'"$port"'/geoserver/rest/workspaces/'"$workspace"'/wmsstores.xml'
        
        if [ "$debug" ]
        then
            curl -v -u $gsUser -X POST -H "Content-type: text/xml" -T "$workDir""$datastore".xml $dataStoreUrl
            echo 'Creando datastore '"$datastore"
        fi
    fi

    # makes an URL for sending the request with the arguments in config file
    restFeatureUrl="$protocol""$host"':'"$port"'/geoserver/rest/workspaces/'"$workspace"'/wmsstores/'"$datastore"'/wmslayers'
    

    ## Layers creation, it evaluates if a filter will be applied
    

    # adds abstract xml tag if not empty    
    if [ ! -z "$abstract" ]
    then
        xmlAbstractString='<abstract>'"$abstract"'</abstract>'
    else
        xmlAbstractString=''
    fi
    
    # adds keywords xml tag if not empty
    if [ ! -z "$keywords" ]
    then
        IFS=', ' read -r -a kwArray <<< "$keywords"
        for element in "${kwArray[@]}"
        do
            KEYWORD+='<string>'"$element"'</string>'
        done
        xmlKeywordsString='<keywords>'"$KEYWORD"'</keywords>'
        KEYWORD=''
    else
        xmlKeywordsString=''
    fi

    # indicates if layer is advertised or not
    if [ -z "$advertised" ]
    then
        xmlAdvertised='';
    else
        xmlAdvertised='<advertised>'"$xmlAdvertised"'</advertised>';
    fi
        
    xmlLayer='<wmsLayer><name>'"$layerNamePrefix""$layerName"'</name><nativeName>'"$layerName"'</nativeName><title>'"$layerTitle"'</title>'"$xmlAbstractString""$xmlKeywordsString"'<enabled>true</enabled>'"$xmlAdvertised"'<srs>EPSG:'"$srs"'</srs></wmsLayer>' # this was deprecated since if is needed to publish a layer (table) with a different name, GeoServer doesn't have a way to determine which table is as it uses the layer name to find the table.
    
    # string with layer's parameters in XML
    echo $xmlLayer > "$workDir""$layerName".xml
    
    if [ "$debug" ]
    then
        # send POST request for creating each layer in GeoServer using the XML
        curl -v -u $gsUser -XPOST -H 'Content-type: text/xml' -T "$workDir""$layerName".xml $restFeatureUrl
        echo 'Creando capa '"$layerName"
    fi
    
done < $layersWMSList

printf "\nEnd of process.\n\n"
