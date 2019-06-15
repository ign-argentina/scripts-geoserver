#!/bin/bash
# this script creates SQL views in GeoServer by REST using as input a file with a list of names and use them creating the query for each one

printf "\nFor reading properly the input file, please add a blank line at its end.\n\n"

# import arguments
source ./config.env

debug=false
date=$(date +%F-%H_%M)
dataDir='data/'"$host"'/layers/'"$date"'/'
mkdir -p $dataDir

# Read features in a list and requests layer (SQL view) creation by REST for each one

while IFS=';' read -r workspace datastore schema table layerNamePrefix layerName layerTitle keywords srs filterField filterValue fields abstract style endLine
do
    workDir="$dataDir""$workspace"'/'
    mkdir -p $workDir
    if [ "$workspace" ]
    then
        # creates a workspace if doesn't exist
        workspaceUrl="$host"'/geoserver/rest/workspaces'
        
        if [ "$debug" ]
        then
            curl -v -u $gsUser -XPOST -H "Content-type: text/xml" -d '<workspace><name>'"$workspace"'</name></workspace>' $workspaceUrl
            echo 'Creando workspace '"$workspace"
        fi
    fi
    
    if [ "$datastore" ]
    then
        # string with datastore's parameters in XML
        xmlDatastore='<dataStore><name>'"$datastore"'</name><type>PostGIS</type><enabled>true</enabled><workspace><name>'"$workspace"'</name><atom:link xmlns:atom="http://www.w3.org/2005/Atom" rel="alternate" href="'"$host"'/geoserver/rest/workspaces/'"$workspace"'.xml" type="application/xml"/></workspace><connectionParameters><entry key="port">'"$port"'</entry><entry key="user">'"$dbUser"'</entry><entry key="passwd">'"$dbPassword"'</entry><entry key="dbtype">postgis</entry><entry key="host">'"$dbHost"'</entry><entry key="database">'"$database"'</entry><entry key="schema">'"$schema"'</entry></connectionParameters><__default>false</__default></dataStore>'
        
        # stores the XML in a temporary file
        echo $xmlDatastore > "$workDir""$datastore".xml
        
        # creates a datastore if doesn't exist (with a database connection)
        dataStoreUrl="$host"'/geoserver/rest/workspaces/'"$workspace"'/datastores.xml'
        
        if [ "$debug" ]
        then
            curl -v -u $gsUser -X POST -H "Content-type: text/xml" -T "$workDir""$datastore".xml $dataStoreUrl
            echo 'Creando datastore '"$datastore"
        fi
    fi
    
    # makes an URL for sending the request with the arguments in config file
    restFeatureUrl="$host"'/geoserver/rest/workspaces/'"$workspace"'/datastores/'"$datastore"'/featuretypes'
    
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
        xmlKeywordsString='<keywords><string>'"$keywords"'</string></keywords>'
    else
        xmlKeywordsString=''
    fi
    
    if [ -z "$filterValue" ]
    then
        # string with layer's parameters in XML
        xmlLayer='<featureType><name>'"$layerNamePrefix""$layerName"'</name><nativeName>'"$table"'</nativeName><title>'"$layerTitle"'</title>'"$xmlAbstractString""$xmlKeywordsString"'<enabled>true</enabled><srs>EPSG:'"$srs"'</srs></featureType>' # this was deprecated since if is needed to publish a layer (table) with a different name, GeoServer doesn't have a way to determine which table is as it uses the layer name to find the table.
        #xmlLayer="$xmlBeginString"'&#42; from '"$schema"'.'"$table""$xmlEndString"
        # stores the XML in a temporary file
        echo $xmlLayer > "$workDir""$layerName".xml
    else
        xmlBeginString='<featureType><name>'"$layerNamePrefix""$layerName"'</name><nativeName>'"$layerName"'</nativeName><title>'"$layerTitle"'</title>'"$xmlAbstractString""$xmlKeywordsString"'<enabled>true</enabled><srs>EPSG:'"$srs"'</srs><metadata><entry key="cachingEnabled">false</entry><entry key="JDBC_VIRTUAL_TABLE"><virtualTable><name>'"$layerNamePrefix""$layerName"'</name><sql>select '
        
        xmlEndString='</sql><escapeSql>false</escapeSql><geometry><name>geom</name><type>Geometry</type><srid>'"$srs"'</srid></geometry></virtualTable></entry></metadata></featureType>'

        if [ "$filterValue" = "null" ]
        then
            whereString=''
        else
            whereString=' where '"$filterField"'=&apos;'"$filterValue"'&apos;'
        fi

        # string with layer's parameters in XML
        xmlLayer="$xmlBeginString""$fields"' from '"$schema"'.'"$table""$whereString""$xmlEndString"
        # stores the XML in a temporary file
        echo $xmlLayer > "$workDir""$layerName".xml
    fi
    
    if [ "$debug" ]
    then
        # send POST request for creating each layer in GeoServer using the XML
        curl -v -u $gsUser -XPOST -H 'Content-type: text/xml' -T "$workDir""$layerName".xml $restFeatureUrl
        echo 'Creando capa '"$layerName"
    fi
    
done < $layersList

printf "\nEnd of process.\n\n"
