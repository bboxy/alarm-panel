function leaflet_map_create(home_town, gps_lat, gps_long, osmUrl, osmAttrib) {
    var osm = new L.TileLayer(osmUrl, {attribution: osmAttrib});
    var m = L.map('map', {
        center: [gps_lat, gps_long],
        zoom: 17,
        layers: [osm]
    });

    L.control.scale().addTo(m);

    m.on('zoomend', function(e) {
    //    if (m.getZoom() < 14) {
    //        hydrantenLayer.remove();
    //    } else {
    //        hydrantenLayer.addTo(m);
    //    }
    });

    //Hydranten
    var hydrantOmnivoreStyleHelper = L.geoJSON(null, {
        pointToLayer: function (feature, latlng) {
            return L.marker(latlng, {icon: L.divIcon({
                className: 'hy_icon',
                iconSize:     [32, 38],
                iconAnchor:   [16, 38],
                html: '<img class="hy_image" src="hydranten/marker_h.png"/>'
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
                html: '<img class="rp_image" src="rettungspunkte/marker_r.png"/><div class="rp_div">' + feature.properties["RP_Nr"] + '</div>'
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

}
