<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<META http-equiv="content-type" content="text/html; charset=utf-8">
<meta http-equiv="cache-control" content="no-cache">
<title>Alarm</title>
<link rel="STYLESHEET" type="text/css" href="stylesheet.css">
<script src="scripts.js"></script>
</head>
<body onload="reloadWatch(); startTime();">
<audio autoplay>
    <source src="%play_file%">
</audio>
<div class="header_1">
	<div class="schlagwort">
		%schlagwort%
	</div>
	<div class="info">
		%bemerkung%
	</div>
</div>
<div class="header_2">
	<div class="addr">
		%adresse%
	</div>
</div>
<div class="header_3">
	<div class="logo">
		<img src="logo.png" class="logo">
	</div>
</div>

<div class="main_1">
<div class="mittel">
%mittel%
</div>
</div>
<div class="main_2">
<iframe class="widget" scrolling="no" src="osm.html"></iframe>
</div>

<div class="bottom_1">
<div class="alarm_txt">Alarmierungszeit:</div>
<div id="alarmzeit" class="alarm">%alarmzeit%</div>
</div>
<div class="bottom_2">
<div class="penalty_txt">Zeit seit Alarmierung:</div>
<div id="penalty" class="penalty"></div>
</div>
<div class="bottom_3">
<div class="alarm_txt">aktuelle Zeit:</div>
<div id="clock" class="clock"></div>
</div>
<div class="bottom_4">
</div>
</body>
</html>
