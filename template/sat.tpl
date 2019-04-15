<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
    <meta name="viewport" content="width=1024, user-scalable=no">
    <style>
	html { height: 100% }
	body { height: 100%; margin: 0; padding: 0;}
	#map{ height: 100% }
	.info { padding: 6px 8px; font: 14px/16px Arial, Helvetica, sans-serif; background: white; background: rgba(255,255,255,0.8); box-shadow: 0 0 15px rgba(0,0,0,0.2); border-radius: 5px; }
	.info h4 { margin: 0 0 5px; color: #777; }
	.legend { text-align: left; line-height: 22px; color: #555; }
	.legend i { width: 18px; height: 18px; float: left; margin-right: 8px; opacity: 0.7; }
    </style>
    <link rel="stylesheet" href="leaflet/leaflet.css" />

<script src="leaflet/leaflet-src.js"></script>
<script type="text/javascript" src="leaflet/leaflet.ajax.js"></script>
<script type="text/javascript" src="leaflet/plugins/leaflet-omnivore.min.js"></script>
<!--script src="leaflet/spin.js"></script-->
<!--script src="leaflet/leaflet.spin.js"></script-->
    </head>
    <body>

<div id="map"></div>
      <script type="text/javascript">

var home_town = "Neu-Ulm";
var gps_lat = %gps_lat%
var gps_long = %gps_long%

var osmUrl='https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
var osmAttrib='Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community';
var osm = new L.TileLayer(osmUrl, {attribution: osmAttrib});

var m = L.map('map', {
	center: [gps_lat, gps_long],
	zoom: 17,
	layers: [osm]
});

var tgtIcon = L.icon({
	iconUrl: 'flame.png',
	iconSize:     [50, 63], // size of the icon
	iconAnchor:   [25, 63], // point of the icon which will correspond to  marker's location
	popupAnchor:  [-3, -76] // point from which the popup should open relative to the iconAnchor
});

var hydIcon = L.icon({
	iconUrl: 'marker_h.png',
	iconSize:     [32, 38], // size of the icon
	iconAnchor:   [16, 38], // point of the icon which will correspond to  marker's location
	popupAnchor:  [-3, -76] // point from which the popup should open relative to the iconAnchor
});

var omnivoreStyleHelper = L.geoJSON(null, {
    pointToLayer: function (feature, latlng) {
        return L.marker(latlng, {icon: hydIcon});
    }
});

omnivore.kml('hydranten.kml', null, omnivoreStyleHelper).addTo(m);

var home = L.marker([gps_lat, gps_long], {icon: tgtIcon}).addTo(m);

</script>
    </body>
</html>
