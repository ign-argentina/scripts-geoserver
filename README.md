# Scripts for automated layers, styles and cache creation

## Layers and styles creation
`create-layers.sh` creates in GeoServer a workspace and datastore from a conection to PostGIS using the parameters provided previuosly in the `config` file, also it use another file called `layersList.csv` where is required to define layers parameters as following, separated by semicolons:

```layerName layerTitle srs filterValue filterField queryFields table styleName fillColor fillOpacity strokeColor strokeOpacity strokeWidth size```

### Example

```
layer_a;layer_a_title;EPSG:4326;filter_value_a;fielter_field_tipe;field_1, field_2, geom;table_name;style_a;#0905fc;0.50;#ffffff;0.50;0.1;4

```

This script creates the styles as SLD files that are uploaded to GeoServer and configures a single layer for each layer as default style.

## Cache creation
`seed-layers.sh` makes caches in GeoServer for layers created by the script mentioned above using as input the `config` file and `cacheList.csv` which stores some required parameters separated by semicolons as the following:

```layerName srs minx miny maxx maxy zoomStart zoomStop format type threadCount```

### Example
In this example, the CSV have three different bounding box for different zoom level ranges.
Bounding box can be calculated with http://bboxfinder.com/

```
layer_a;900913;;;;;0;3;image/png;seed;02
layer_a;900913;-14128008.8120;2622095.8183;-7024868.6475;6496535.9080;4;7;image/png;reseed;02
layer_a;900913;-13759888.0838;5900938.5836;-13521404.5555;6271505.2965;12;image/png;reseed;02

```

Note that both CSV files must have a blank line at the end to avoid leaving the last data line without reading it.

## Usage

- Set needed parameters in config and CSV files
- Run `create-layers.sh`
- Check in Geoserver that layers are created and working as expected by layer preview or loading them in a desktop GIS
- Run `seed-layers.sh`
- Check cache creation tasks in `http://<GeoServer Instance>:8080/geoserver/gwc/rest/seed.json`. If it returns `long-array-array	[]` that means that the tasks are done or never started, if returns arrays with numbers means that GeoWebCache is running tasks.

## Misc
If you want to delete all the cache from GeoWebCache, it can be done by executing the following command:

```
curl -v -u "user:password" -XGET -H "Content-type: text/xml" "http://<GeoServer Instance>:8080/geoserver/gwc/rest/masstruncate"
```
