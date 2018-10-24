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
    <link rel="stylesheet" href="weather/leaflet.css" />

<script src="weather/leaflet-src.js"></script>
<script type="text/javascript" src="weather/leaflet.ajax.js"></script>
<!--script src="weather/spin.js"></script-->
<!--script src="weather/leaflet.spin.js"></script-->
    </head>
    <body>

<div id="map"></div>
      <script type="text/javascript">

var home_town = "Neu-Ulm";
var gps_lat = %gps_lat%
var gps_long = %gps_long%

var osmUrl='http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
var osmAttrib='Map data © <a href="http://openstreetmap.org">OpenStreetMap</a> contributors';
var osm = new L.TileLayer(osmUrl, {attribution: osmAttrib});

var m = L.map('map', {
	center: [gps_lat, gps_long],
	zoom: 16,
	layers: [osm]
});

var home = L.marker([gps_lat, gps_long]).addTo(m);

</script>
    </body>
</html>
