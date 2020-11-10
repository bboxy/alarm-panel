function leaflet_map_create(home_town, gps_lat, gps_long, osm, sat) {
    var osmUrl='http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
    var osmAttrib='Map data © <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, © KWF-Rettungspunkte v2.9, <a href="http://www.rettungspunkte-forst.de">www.rettungspunkte-forst.de</a>, CC-BY_ND 3.0';
    var satUrl='https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    var satAttrib='Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community, © KWF-Rettungspunkte v2.9, <a href="http://www.rettungspunkte-forst.de">www.rettungspunkte-forst.de</a>, CC-BY_ND 3.0';

    if (osm) {
        var osm = new L.TileLayer(osmUrl, {attribution: osmAttrib});
    }

    if (sat) {
        var sat = new L.TileLayer(satUrl, {attribution: satAttrib});
    }


    if (osm && sat) {
        var m = L.map('map', {
            center: [gps_lat, gps_long],
            zoom: 17,
            layers: [sat, osm]
        });

        var baseLayers = {
            "Satellite View": sat,
            "OpenStreetMap View": osm
        };

        L.control.layers(baseLayers).addTo(m);
    } else if (osm) {
        var m = L.map('map', {
            center: [gps_lat, gps_long],
            zoom: 17,
            layers: osm
        });
    } else if (sat) {
        var m = L.map('map', {
            center: [gps_lat, gps_long],
            zoom: 17,
            layers: sat
        });
    }

    L.control.scale().addTo(m);

    //Hydranten
    var hydrantOmnivoreStyleHelper = L.geoJSON(null, {
        pointToLayer: function (feature, latlng) {
            return L.marker(latlng, {icon: L.divIcon({
                className: 'hy_icon',
                iconSize:     [32, 38],
                iconAnchor:   [16, 38],
                html: '<img src="hydranten/marker_h.png"/>'
            })});
        }
    });

    //Waldrettungspunkte
    var rettungspunktOmnivoreStyleHelper = L.geoJSON(null, {
        pointToLayer: function (feature, latlng) {
            return L.marker(latlng, {icon: L.divIcon({
                className: 'rp_icon',
                iconSize:     [38, 50],
                iconAnchor:   [19, 18],
                html: '<img src="rettungspunkte/marker_r.png"/><div class="rp_div">' + feature.properties["RP_Nr"] + '</div>'
            })});
        }
    });

    //Bahnkilometer
    //https://opendata-esri-de.opendata.arcgis.com/datasets/f57a86b0b2134ca2bdd110758b396e68_0/data?geometry=8.867%2C48.262%2C11.488%2C48.581&orderBy=streckennu&where=streckennu%20%3E%3D%205302%20AND%20streckennu%20%3C%3D%205302
    var bahnkilometerOmnivoreStyleHelper = L.geoJSON(null, {
        pointToLayer: function (feature, latlng) {
            return L.marker(latlng, {icon: L.divIcon({
                className: 'db_icon',
                iconSize:     [38, 38],
                iconAnchor:   [19, 19],
                html: '<div class="db_div1">' + feature.properties["km_l"] + '</div><div class="db_div2">0</div>'
            })});
        }
    });

    var hyLayer = omnivore.kml('hydranten/hydranten.kml', null, hydrantOmnivoreStyleHelper);
    var rpLayer = omnivore.kml('rettungspunkte/rp_nu_ul_gz.kml', null, rettungspunktOmnivoreStyleHelper);
    var dbLayer = omnivore.kml('bahn/bahn.kml', null, bahnkilometerOmnivoreStyleHelper);

    hyLayer.addTo(m);
    rpLayer.addTo(m);
    dbLayer.addTo(m);

    //Ziel
    var home = L.marker([gps_lat, gps_long], {icon: L.icon({
        iconUrl: 'flame.png',
        iconSize:     [50, 63],
        iconAnchor:   [25, 63],
       // popupAnchor:  [-3, -76]
    })}).addTo(m);

    m.on('zoomend', function(e) {
        if (m.getZoom() < 14) {
            hyLayer.remove();
        } else {
            hyLayer.addTo(m);
        }
        if (m.getZoom() < 12) {
            rpLayer.remove();
        } else {
            rpLayer.addTo(m);
        }
        if (m.getZoom() < 13) {
            dbLayer.remove();
        } else {
            dbLayer.addTo(m);
        }
    });

}
