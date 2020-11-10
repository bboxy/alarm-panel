var timestamp = null;

//window.addEventListener("DOMContentLoaded", event => {
//  const audio = document.querySelector("audio");
//  audio.volume = 1.0;
//  audio.play();
//});

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
                    //console.log("watch" + timestamp);
                    if (timestamp == null) {
                        timestamp = this.responseText;
                    } else {
                        if (timestamp != this.responseText) {
                            timestamp = null;
                            //this.responseText;
                            window.location.replace(window.location.href);
                            //window.location.reload(false);
                            console.log("reloading");
                        }
                        //console.log("status " + this.status);
                        //console.log("readyState " + this.readyState);
                        //console.log(timestamp);
                    }
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
