    var timestamp = null;
    var map;
    var map_sat;
    var geocoder;
    var geocoder_sat;

    function initMap(addr) {
	var zoomlevel = 16;
        geocoder      = new google.maps.Geocoder();
        var latlng    = new google.maps.LatLng(48.41523, 10.14069);
        var mapDiv    = document.getElementById('map');
        var width     = mapDiv.offsetWidth;
        map = new google.maps.Map(mapDiv, {
            center: latlng,
            zoom: zoomlevel,
            mapTypeId: google.maps.MapTypeId.ROADMAP
        });
        // ACHTUNG: Adresse muss UTF-8-codiert von PHP übergeben werden!!!! Sonst Umlaute kaputt.
        geocoder.geocode( { 'address': addr}, function(results, status) {
            if (status == google.maps.GeocoderStatus.OK) {
                map.setCenter(results[0].geometry.location);
                var marker = new google.maps.Marker({
                    map: map,
                    position: results[0].geometry.location
                });
            } else {
            // alert("Geocode was not successful for the following reason: " + status);
            }
        });
        map.setZoom(zoomlevel);
    }

    function initMapSat(addr) {
	var zoomlevel = 16;
        geocoder_sat  = new google.maps.Geocoder();
        var latlngSat = new google.maps.LatLng(48.41523, 10.14069);
        var mapDivSat = document.getElementById('map_sat');
        map_sat = new google.maps.Map(mapDivSat, {
            center: latlngSat,
            zoom: zoomlevel,
            mapTypeId: google.maps.MapTypeId.HYBRID
        });
        // ACHTUNG: Adresse muss UTF-8-codiert von PHP übergeben werden!!!! Sonst Umlaute kaputt.
        geocoder_sat.geocode( { 'address': addr}, function(results, status) {
            if (status == google.maps.GeocoderStatus.OK) {
                map_sat.setCenter(results[0].geometry.location);
                var marker = new google.maps.Marker({
                    map: map_sat,
                    position: results[0].geometry.location
                });
            } else {
            // alert("Geocode was not successful for the following reason: " + status);
            }
        });
        map_sat.setZoom(zoomlevel);
    }

    function zoom() {
        // Feststellen, ob wir noch in unserem Ortsgebiet sind
//	var ortaufkarte = document.getElementById("ortaufkarte").value;
//	var ergebnis = ortaufkarte.search(25i);
//	if (ergebnis != -1)
//	{
//		// Wir sind im Ortsgebiet
//		zoomlevel = 5;
//	} else {
//		// Wir sind auf dem Land
//		zoomlevel = 2;
//	}
    }

function startTime() {
    var today = new Date();
    var h = today.getHours();
    var m = today.getMinutes();
    var s = today.getSeconds();

    var alarm = document.getElementById('alarmzeit').innerHTML;

    var ph = alarm.substring(0, 2);
    var pm = alarm.substring(3, 5);
    var ps = alarm.substring(6, 8);

    var time_akt = h * 3600 + m * 60 + s;
    var time_alarm = ph * 3600 + pm * 60 + ps * 1;

    var diff = time_akt - time_alarm;

    var dh = Math.floor(diff / 3600);
    var dm = Math.floor((diff - (dh * 3600)) / 60);
    var ds = diff - (dm * 60) - (dh * 3600);

    if (dh < 0) dh += 24;

    h = checkTime(h);
    m = checkTime(m);
    s = checkTime(s);

    dh = checkTime(dh);
    dm = checkTime(dm);
    ds = checkTime(ds);

    var time = h + ":" + m + ":" + s;
    var penalty = dh + ":" + dm + ":" + ds;

    document.getElementById('clock').innerHTML = time;
    document.getElementById('penalty').innerHTML = penalty;

    if (dh == 0 && dm < 5) {
        document.getElementById('penalty').style.color = "#000000";
    } else {
        document.getElementById('penalty').style.color = "#c02020";
    }
    var t = setTimeout(startTime, 500);
}
function checkTime(i) {
    if (i < 10) {i = "0" + i};  // add zero in front of numbers < 10
    return i;
}

function startDate() {
    var months = ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"];
    var today = new Date();
    var date = today.getDate() + ". " + months[today.getMonth()] + " " + today.getFullYear();
    document.getElementById('idle_datum').innerHTML = date;
    var d = setTimeout(startDate, 5000);
}

function reloadWatch() {
    var ajax = null;
    if(window.XMLHttpRequest) { //Google Chrome, Mozilla Firefox, Opera, Safari, IE 7
        ajax = new XMLHttpRequest();
    }

    if (ajax != null) {
        //ajax.open("GET","timestamp.txt?" + new Date().getTime() ,true);
        ajax.open("GET","timestamp.txt",true);
        ajax.setRequestHeader("timestamp","timestamp");
        ajax.onreadystatechange = function(){
            if(this.readyState == 4){
                if(this.status == 200){
                    if (timestamp == null) timestamp = this.responseText;
    		else if (timestamp != this.responseText) {
                        timestamp = this.responseText;
                        //window.location.reload(false);
                        window.location.replace(window.location.href);
                    }
                    //console.log("status " + this.status);
                    //console.log("readyState " + this.readyState);
                    //console.log(timestamp);
                } else {
                    //console.log("status " + this.status);
		}
            } else {
                //console.log("readyState " + this.readyState);
            }
        }
        ajax.send(null);
    }

    var t = setTimeout(reloadWatch, 5000);
}

function reloadFMS() {
    // fuhrpark.xml parsen und Status der Fahrzeuge anzeigen
    var x = null;
    if(window.XMLHttpRequest) { //Google Chrome, Mozilla Firefox, Opera, Safari, IE 7
        x = new XMLHttpRequest();
    }

    if (x != null) {
        //x.open("GET","fuhrpark.xml?" + new Date().getTime() ,true);
        x.open("GET","fuhrpark.xml",true);
        x.onreadystatechange = function(){
            if(this.readyState == 4 && this.status == 200) {
                var html = "";
                var fuhrpark = x.responseXML.getElementsByTagName("fuhrpark")[0].getElementsByTagName("fahrzeug");
                for (i = 0; i < fuhrpark.length; i++) {
                    var id;
                    var name;
                    var kennung;
                    var stat = 0;
                    var timestamp = 0;

                    var nodes;

                    nodes = fuhrpark[i].getElementsByTagName("id");
                    if (nodes.length) {
                        nodes = nodes[0].childNodes;
                        if (nodes.length) id = nodes[0].nodeValue;
                    }
                    nodes = fuhrpark[i].getElementsByTagName("timestamp");
                    if (nodes.length) {
                        nodes = nodes[0].childNodes;
                        if (nodes.length) timestamp = nodes[0].nodeValue;
                    }
                    nodes = fuhrpark[i].getElementsByTagName("status");
                    if (nodes.length) {
                        nodes = nodes[0].childNodes;
                        if (nodes.length) stat = nodes[0].nodeValue;
                    }
                    nodes = fuhrpark[i].getElementsByTagName("name");
                    if (nodes.length) {
                        nodes = nodes[0].childNodes;
                        if (nodes.length) name = nodes[0].nodeValue;
                    }
                    nodes = fuhrpark[i].getElementsByTagName("kennung");
                    if (nodes.length) {
                        nodes = nodes[0].childNodes;
                        if (nodes.length) kennung = nodes[0].nodeValue;
                    }
                    html += "<span class=\"status" + stat + "\"><p class=\"fp_kennung\">" + kennung + "</p><p class=\"fp_status\">" + stat + "</p><p class=\"fp_name\">" + name + "</p></span>";
                }
                if(document.getElementById('status')) {
                    document.getElementById('status').innerHTML = html;
                }
            }
        }
        x.send();
    }
    var t = setTimeout(reloadFMS, 5000);
}
