# Scripts for automated layers, styles, groups and cache creation

A set of scripts files, written in bash, for automated layers, styles, groups and cache creation in Geoserver using its web API.

## Usage

  - Prepare scripts, data files and directories
  - Edit config file (`config.sh`)
  - Execute the scripts in this order:
  	- `create-layers.sh` to add layers in Geoserver
  	- `create-styles.sh` to add styles in Geoserver
  	- `set-styles.sh` to assign existing style to existing layer
  	- `create-layers-groups.sh` to add groups to Geoserver using layers and styles created

## Scripts, data files and directories preparation

In addition to saving the files corresponding to the scripts, the CSV files must be generated with the necessary data for the scripts to work. In addition you must create a directory called `data`.
These files must be accessible from the directory where the scripts are located.
Each of these files will be explained in the corresponding section with each script.

## Edit config file (`config.sh`)

You must rename the file `config.env.example` file to `config.env` and edit it to load the values corresponding to the parameters necessary for the execution of the scripts.
These parameters are:

- protocol: communication protocol used by Geoserver Web API (e.g. 'http://')
- port: comunication port used by Geoserver Web API  (e.g. '8080')
- host: host name or IP address used by Geoserver Web API (e.g. '127.0.0.1')
- gsUser: Geoserver Web API user and password (e.g. 'admin:geoserver')
- layersList: CSV file that contains the necessary data for the script `create-layers.sh` (e.g. 'data/layers.csv')
- stylesList: CSV file that contains the necessary data for the script `create-styles.sh` (e.g. 'data/styles.csv')
- stylesLayers: CSV file that contains the necessary data for the script `set-styles.sh` (e.g. 'data/layers-styles.csv')
- groupsList: CSV file that contains the necessary data for the script `create-layers-groups.sh` (e.g. 'data/groups.csv')
- cacheList:
- dbHost: host name or IP address used by Database. It is used to create the datastore (e.g. '127.0.0.1')
- dbPort port used by Database. It is used to create the datastore (e.g. '5432')
- dbUser: username used by Database. It is used to create the datastore (e.g. 'postgres')
- dbPassword: password used by Database. It is used to create the datastore (e.g. 'postgres*123')
- database: database name used by Database. It is used to create the datastore (e.g. 'dbdata')
- dbMaxConnections: maximum number of connections configured in the datastore (e.g. '5')
- defaultWorkspace: default workspace name. This workspace must exists in csv data file defined in layersList parameter (e.g. 'default-workspace')

## `create-layers.sh` script

Create workspaces, data stores and layers indicated in the csv data file (in `layersList` configuration parameter) in geoserver.
The layersList csv file indicates the data required for execution separated by semicolons. Its structure is:

```
workspace;datastore;schema;table;layerNamePrefix;layerName;layerTitle;keywords;advertised;srs;keyColumn;filterField;filterValue;fields;abstract;style;

```

### Structure explanation

- workspace: (REQUIERED) workspace name to be created in Geoserver
- datastore: (REQUIERED) datastore name to be created in Geoserver
- schema: (REQUIERED) schema name into existing database, this is used to configure the datastore
- table: (REQUIERED) table name into existing database, this is used to configure the layer
- layerNamePrefix: prefix to be concatenated in the name of the layer
- layerName: (REQUIRED) layer unique name
- layerTitle: (REQUIERED) layer title
- keywords: (OPTIONAL) layer keywords
- advertised: (REQUIERED) announced layer indicator. Allowed values are 0 (not announced) or 1 (announced)
- srs: (REQUIERED) layer coordinate reference system
- keyColumn: (REQUIERED) primary key of the database table used as the layer's data source
- filterField: (OPTIONAL) Field used to filter data in the layer data query
- filterValue: (OPTIONAL) Value used to filter data in the layer data query. filterField and filterValue are concatenated to form the query filter (e.g. if filterField = 'field1' and filterValue = 5 then the filter applied to the query is "field1 = 5")
- fields: (OPTIONAL) List of fields that will be displayed in the layer. Fields must be separated by a comma
- abstract: (OPTIONAL) layer abstract
- style: (OPTIONAL) not using by now

### Example

```
ign;db_ign;public;airport_table;;airport;Airports;;1;4326;gid;type;2;gid,geom,name,location,type;National Airports;;

```

IMPORTANT: Note that CSV files must have a blank line at the end to avoid leaving the last data line without reading it.

The script creates a new directory whose name matches the `host` parameter indicated in the configuration file within the `data` directory. Log files will be created within this directory to visualize the xml files generated in the process.


## `create-styles.sh` script

Create styles indicated in the csv data file (in `stylesList` configuration parameter) in geoserver.
The stylesList csv file indicates the data required for execution separated by semicolons. Its structure is:

```
file;workspace;resources;

```

### Structure explanation

- file: (REQUIERED) layer unique name. This name must match with SLD filename wich contain SLD style code
- workspace: (REQUIERED) workspace name to be created in Geoserver
- resources: (OPTIONAL) comma separated list indicating SVG files which are using by SLD style

### Example

```
airport-style;ign;icon.svg,point.svg;

```

IMPORTANT: Note that CSV files must have a blank line at the end to avoid leaving the last data line without reading it.

the script takes the sld and svg files from the `data/<host>/styles/<workspace>` directory. The `host` parameter is taken from the configuration file and the `workspace` parameter is the one indicated in each line of the csv file.

The script creates a new directory whose name matches the `host` parameter indicated in the configuration file within the `data` directory. Log files will be created within this directory to visualize the xml files generated in the process.


## `set-styles.sh` script

Set the default style in each layer. Use the csv data file indicated in `stylesLayers` configuration parameter.
The stylesLayers csv file indicates the data required for execution separated by semicolons. Its structure is:

```
workspace;layer;style;

```

### Structure explanation

- workspace: (REQUIERED) workspace name to be created in Geoserver
- layer: (REQUIRED) layer unique name
- style: (REQUIRED) style unique name

### Example

```
ign;airport;airport-style;

```

IMPORTANT: Note that CSV files must have a blank line at the end to avoid leaving the last data line without reading it.

The script creates a new directory whose name matches the `host` parameter indicated in the configuration file within the `data` directory. Log files will be created within this directory to visualize the xml files generated in the process.


## `create-layers-groups.sh` script

Create layers groups indicated in the csv data file (in `groupsList` configuration parameter) in geoserver.The groupsList csv file indicates the data required for execution separated by semicolons. Its structure is:

```
name;mode;title;workspace;srs;abstract;layersList;stylesList;

```

### Structure explanation

- name: (REQUIERED) layer group unique name
- mode: (REQUIERED) group mode (e.g. "Single")
- title: (REQUIERED) layer group title
- workspace: (REQUIERED) workspace name to be created in Geoserver
- srs: (REQUIERED) layer group coordinate reference system
- layersList: (REQUIRED) list of layers that make up the group separated by comma
- stylesList: (REQUIRED) list of styles of each layer that make up the group separated by comma
- abstract: (OPTIONAL) layer group abstract


### Example

```
airports;SINGLE;National Airports Group;ign;4326;airport,heliport;airport-style,heliport-style;This is an abstract;

```

IMPORTANT: Note that CSV files must have a blank line at the end to avoid leaving the last data line without reading it.

The script creates a new directory whose name matches the `host` parameter indicated in the configuration file within the `data` directory. Log files will be created within this directory to visualize the xml files generated in the process.
