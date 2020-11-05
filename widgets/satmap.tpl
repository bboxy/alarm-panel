<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
    <meta name="viewport" content="width=1024, user-scalable=no">
    <link rel="stylesheet" href="map.css"/>
    <script src="leaflet/leaflet-src.js"></script>
    <script type="text/javascript" src="leaflet/leaflet.ajax.js"></script>
    <script type="text/javascript" src="leaflet/plugins/leaflet-omnivore.min.js"></script>
    <script src="leaflet_map.js"></script>
    </head>
    <body>

<div id="map"></div>
    <script type="text/javascript">

    var home_town = "%landkreis%";
    var gps_lat = %home_lat%;
    var gps_long = %home_long%;
    var osmUrl='https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    var osmAttrib='Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community, © KWF-Rettungspunkte v2.9, <a href="http://www.rettungspunkte-forst.de">www.rettungspunkte-forst.de</a>, CC-BY_ND 3.0';

    leaflet_map_create(home_town, gps_lat, gps_long, osmUrl, osmAttrib);

</script>
    </body>
</html>
