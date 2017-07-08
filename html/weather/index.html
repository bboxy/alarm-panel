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
    <link rel="stylesheet" href="leaflet.css" />

<script src="leaflet-src.js"></script>
<script type="text/javascript" src="leaflet.ajax.js"></script>
<!--script src="spin.js"></script-->
<!--script src="leaflet.spin.js"></script-->
    </head>
    <body>

<div id="map"></div>
      <script type="text/javascript">

var home_town = "Neu-Ulm";
var home_lat = 48.41523
var home_long = 10.14069

var landkreise = new L.GeoJSON.AJAX('landkreise.json', {
	style: landkreisstyle,
	attribution: 'Unwetterwarnungen © <a href="http://www.dwd.de">DWD</a>',
	onEachFeature: function(feature, layer) {
		layer.on({
			'add': function() {
				layer.bringToBack()
			}
		})
	}
});

var osmUrl='http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
var osmAttrib='Map data © <a href="http://openstreetmap.org">OpenStreetMap</a> contributors';
var osm = new L.TileLayer(osmUrl, {minZoom: 7, maxZoom: 12, attribution: osmAttrib});

var m = L.map('map', {
	center: [48.3, 10.2],
	zoom: 9,
	layers: [osm, landkreise]
});

var home = L.marker([home_lat, home_long]).addTo(m);

var warnings = new L.GeoJSON();

var legend = L.control({position: 'topright'});

legend.onAdd = function (m) {
    var div = L.DomUtil.create('div', 'info legend'),
	grades = [
		"gewitter1",
		"gewitter2",
		"gewitter3",
		"gewitter4",
		"",
		"wind1",
		"wind2",
		"wind3",
		"wind4",
		"wind5",
		"wind6",
		//"",
		//"dauerregen1",
		//"dauerregen2",
		//"dauerregen3",
		//"",
		//"starkregen1",
		//"starkregen2",
		//"starkregen3",
		"",
		"schnee1",
		"schnee2",
		"schnee3",
		"schnee4",
		"",
		"glaette"
	],
        labels = [
		"Gewitter",
		"Starkes Gewitter",
		"Schweres Gewitter",
		"Extremes Gewitter",
		"",
		"Windböen",
		"Sturmböen",
		"Schwere Sturmböen",
		"Orkanartige Böen",
		"Orkanböen",
		"Extreme Orkanböen",
		//"",
		//"Dauerkregen",
		//"Heftiger Dauerregen",
		//"Extremer Dauerregen",
		//"",
		//"Starkregen",
		//"Heftiger Starkregen",
		//"Extremer Starkregen",
		"",
		"Leichter Schneefall",
		"Schneefall",
		"Starker Schneefall",
		"Extremer Schneefall",
		"",
		"Glätte"
	];

	// loop through our density intervals and generate a label with a colored square for each interval
	for (var i = 0; i < grades.length; i++) {
		if(labels[i] != "") {
			div.innerHTML += '<i style="border: solid 1px #c0c0c0; background:' + getColor(grades[i]) + '"></i>' + labels[i] + '<br>';
		} else {
			div.innerHTML += '<i></i>&nbsp;<br>';
		}
	}
	return div;
};

legend.addTo(m);

updateWarnings();

function getColor(x) {
	return x == "gewitter1" ? '#ffbb00':
	       x == "gewitter2" ? '#ff7700':
	       x == "gewitter3" ? '#ff1100':
	       x == "gewitter4" ? '#bb0033':
	       x == "wind1" ? '#ffccff':
	       x == "wind2" ? '#f8aaff':
	       x == "wind3" ? '#f088ff':
	       x == "wind4" ? '#e866ff':
	       x == "wind5" ? '#e044ff':
	       x == "wind6" ? '#d822ff':
	       x == "dauerregen1" ? '#eeeeff':
	       x == "dauerregen2" ? '#ccccff':
	       x == "dauerregen3" ? '#aaaaff':
	       x == "starkregen1" ? '#8888ff':
	       x == "starkregen2" ? '#6666ff':
	       x == "starkregen3" ? '#4444ff':
	       x == "schnee1" ? '#999999':
	       x == "schnee2" ? '#bbbbbb':
	       x == "schnee3" ? '#dddddd':
	       x == "schnee4" ? '#ffffff':
	       x == "glaette" ? '#ccccff':
                    '#ffffff';
}

function warnstyle(feature) {
	switch(feature.properties.EC_II) {
		case "31":		//Gewitter 1
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("gewitter1"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("gewitter1")
		};
		case "33":		//Gewitter 2
		case "34":
		case "36":
		case "38":
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("gewitter2"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("gewitter2")
		};
		case "40":		//Gewitter 3
		case "42":
		case "44":
		case "46":
		case "48":
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("gewitter3"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("gewitter3")
		};
		case "41":		//Gewitter 4 + Orkan
		case "45":
		case "49":
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("gewitter4"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("gewitter4")
		};
		case "95":		//Gewitter 4 + Regen
		case "96":
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("gewitter4"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("gewitter4")
		};
		case "51":		//Wind 1
		case "11":
		case "12":
		case "57":
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("wind1"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("wind1")
		};
		case "13":		//Wind 2
		case "52":
		case "58":
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("wind2"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("wind2")
		};
		case "53":		//Wind 3
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("wind3"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("wind3")
		};
		case "54":		//Wind 4
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("wind4"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("wind4")
		};
		case "55":		//Wind 5
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("wind5"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("wind5")
		};
		case "56":		//Wind 6
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("wind6"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("wind6")
		};
		case "61a":		//Regen 1
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("starkregen1"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("starkregen1")
		};
		case "62a":		//Regen 2
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("starkregen2"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("starkregen2")
		};
		case "66a":		//Regen 3
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("starkregen3"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("starkregen3")
		};
		case "63a":		//Regen 1
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("dauerregen1"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("dauerregen1")
		};
		case "64a":		//Regen 2
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("dauerregen2"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("dauerregen2")
		};
		case "65a":		//Regen 3
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("dauerregen3"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("dauerregen3")
		};
		case "70":		//Schnee 1
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("schnee1"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("schnee1")
		};
		case "71":		//Schnee 2
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("schnee2"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("schnee2")
		};
		case "72":		//Schnee 3
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("schnee3"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("schnee3")
		};
		case "73":		//Schnee 4
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("schnee4"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("schnee4")
		};
		case "83":		//Glätte
		case "84":
		case "85":
		case "86":
		case "87":
		return {
			weight: 1,
			opacity: 0.5,
			color: getColor("glaette"),
			dashArray: '0',
			fillOpacity: 0.5,
			fillColor: getColor("glaette")
		};

		default:
		return {
			weight: 1,
			opacity: 0.0,
			color: getColor(""),
			dashArray: '0',
			fillOpacity: 0.0,
			fillColor: getColor("")
		};
	}
}

function landkreisstyle(feature) {
	if(feature.properties.NAME_3 == home_town) {
		return {
			weight: 1.5,
			opacity: 1,
			color: '#808080',
			dashArray: '0',
			fillOpacity: 0.4,
			fillColor: '#a0a080'
		};
	} else {
		return {
			weight: 1.5,
			opacity: 1,
			color: '#808080',
			dashArray: '0',
			fillOpacity: 0.0,
			fillColor: '#e0e0c0'
		};
	}
}

function clock() {
	a = new Date();
	b = a.getHours(); c = a.getMinutes(); d = a.getSeconds();
	if(b < 10) b = '0'+b;
	if(c < 10) c = '0'+c;
	if(d < 10) d = '0'+d;
	zeit = b+':'+c+':'+d;
	return zeit;
}

function updateWarnings () {
	m.removeLayer(warnings);
	//warnings = new L.GeoJSON.AJAX('https://maps.dwd.de/geoserver/dwd/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=dwd:Warnungen_Gemeinden_vereinigt&bbox=7.6,46,12.6,50&outputFormat=application%2Fjson', {
	warnings = new L.GeoJSON.AJAX('https://maps.dwd.de/geoserver/dwd/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=dwd:Warnungen_Gemeinden_vereinigt&outputFormat=application%2Fjson', {
		attribution: 'Letzte Aktualisierung:' + clock(),
		style: warnstyle,
		onEachFeature: function(feature, layer) {
			layer.on({
				'add': function() {
					layer.bringToFront()
				}
			})
		}
	});
	warnings.addTo(m);
	console.log('update\n');

	var t = setTimeout(updateWarnings, 300000);
}

</script>
    </body>
</html>
