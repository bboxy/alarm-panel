function leaflet_map_create(home_town, gps_lat, gps_long, osmUrl, osmAttrib) {
    var osm = new L.TileLayer(osmUrl, {attribution: osmAttrib});
    var m = L.map('map', {
        center: [gps_lat, gps_long],
        zoom: 17,
        layers: [osm]
    });

    //Hydranten
    var hydrantOmnivoreStyleHelper = L.geoJSON(null, {
        pointToLayer: function (feature, latlng) {
            return L.marker(latlng, {icon: L.icon({
                iconUrl: 'hydranten/marker_h.png',
                iconSize:     [32, 38],
                iconAnchor:   [16, 38],
                popupAnchor:  [-3, -76]
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

    omnivore.kml('hydranten/hydranten.kml', null, hydrantOmnivoreStyleHelper).addTo(m);
    omnivore.kml('rettungspunkte/rp_nu_ul_gz.kml', null, rettungspunktOmnivoreStyleHelper).addTo(m);

    //Ziel
    var home = L.marker([gps_lat, gps_long], {icon: L.icon({
        iconUrl: 'flame.png',
        iconSize:     [50, 63],
        iconAnchor:   [25, 63],
        popupAnchor:  [-3, -76]
    })}).addTo(m);
}