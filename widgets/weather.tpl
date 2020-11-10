<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
    <meta name="viewport" content="width=1024, user-scalable=no">
    <link rel="stylesheet" href="map.css"/>
    <script src="leaflet/leaflet-src.js"></script>
    <script type="text/javascript" src="leaflet/plugins/leaflet.ajax.js"></script>
    <script type="text/javascript" src="leaflet_weather.js"></script>
    </head>
    <body>

<div id="map"></div>
    <script type="text/javascript">

    var home_town = "%landkreis%";
    var gps_lat = %home_lat%;
    var gps_long = %home_long%;
    var osmUrl='http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
    var osmAttrib='Map data © <a href="http://openstreetmap.org">OpenStreetMap</a> contributors';

    leaflet_map_create(home_town, gps_lat, gps_long, osmUrl, osmAttrib);

</script>
    </body>
</html>
