    var timestamp = null;
    var map;
    var geocoder;
    function initMap(addr) {
        //var addr;
        geocoder = new google.maps.Geocoder();
        var latlng = new google.maps.LatLng(48.41523, 10.14069);
        var mapDiv = document.getElementById('map');
        map = new google.maps.Map(mapDiv, {
            center: latlng,
            zoom: 16
        });
        //addr = document.getElementById('query').innerHTML;
        codeAddress(addr);
    }
    function codeAddress(address) {
        // ACHTUNG: Adresse muss UTF-8-codiert von PHP übergeben werden!!!! Sonst Umlaute kaputt.
        geocoder.geocode( { 'address': address}, function(results, status) {
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
        zoom();
    }
    function zoom() {
        // Feststellen, ob wir noch in unserem Ortsgebiet sind
//	var ortaufkarte = document.getElementById("ortaufkarte").value;
//	var ergebnis = ortaufkarte.search(25i);
	var zoomlevel = 16;
//	if (ergebnis != -1)
//	{
//		// Wir sind im Ortsgebiet
//		zoomlevel = 5;
//	} else {
//		// Wir sind auf dem Land
//		zoomlevel = 2;
//	}
        map.setZoom(zoomlevel);
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
        document.getElementById('penalty').style.color = "#ffffff";
    } else {
        document.getElementById('penalty').style.color = "#ff4040";
    }
    var t = setTimeout(startTime, 500);
}
function checkTime(i) {
    if (i < 10) {i = "0" + i};  // add zero in front of numbers < 10
    return i;
}

function startDate() {
    var months = ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Ockober", "November", "Dezember"];
    var today = new Date();
    var date = today.getDate() + ". " + months[today.getMonth()] + " " + today.getFullYear();
    document.getElementById('datum').innerHTML = date;
    var d = setTimeout(startDate, 5000);
}

function reloadWatch() {
    if (!document.getElementById('penalty')) {
    } else {
        var penalty = document.getElementById('penalty').innerHTML;
        var ph = penalty.substring(0, 2);
        var pm = penalty.substring(3, 5);
        var ps = penalty.substring(6, 8);

        var time_penalty = ph * 3600 + pm * 60 + ps * 1;
        if (time_penalty > 60 * 60) {
            //window.location.replace('idle.html');
        }
    }

    var ajax = null;
    if(window.XMLHttpRequest) { //Google Chrome, Mozilla Firefox, Opera, Safari, IE 7
        ajax = new XMLHttpRequest();
    }

    if (ajax != null) {
        ajax.open("GET","timestamp.txt",true);
        ajax.setRequestHeader("timestamp","timestamp");
        ajax.onreadystatechange = function(){
            if(this.readyState == 4){
                if(this.status == 200){
                    if (timestamp == null) timestamp = this.responseText;
    		else if (timestamp != this.responseText) {
                        timestamp = this.responseText;
                        //window.location.reload(false);
                        window.location.replace('index.html');
                    }
                    //console.log(timestamp);
                }
            }
        }
        ajax.send(null);
    }

    // fuhrpark.xml parsen und Status der Fahrzeuge anzeigen
    // TODO place in own function so others don't fail if this fails
    var x = null;
    if(window.XMLHttpRequest) { //Google Chrome, Mozilla Firefox, Opera, Safari, IE 7
        x = new XMLHttpRequest();
    }

    if (x != null) {
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
                    html += "<span class=\"status" + stat + "\">" + kennung + "<br>" + stat + "</span>";
                }
                document.getElementById('status').innerHTML = html;
            }
        }
        x.send();
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
                    html += "<span class=\"status" + stat + "\">" + kennung + "<br>" + stat + "</span>";
                }
                document.getElementById('status').innerHTML = html;
            }
        }
        x.send();
    }
    var t = setTimeout(reloadFMS, 2000);
}
