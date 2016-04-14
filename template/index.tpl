<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<META http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta content="text/html; charset=ISO-8859-1" http-equiv="content-type">
<title>Alarm</title>
<link rel="STYLESHEET" type="text/css" href="stylesheet.css">
%map_script
</head>
<body onload="reloadWatch(); reloadFMS(); startTime(); initMap(&quot;%query&quot;);">
<table>
	<tr class="header">
		<td class="schlag">
			%schlagwort
			<div class="info">%bemerkung</div>
		</td>
		<td class="addr">
			<div class="addr">%strasse %nummer</div>
			<div class="addr">%ort</div>
			<div class="addr">%abschnitt</div>
		</td>
		<td class="logo">
			<img src="logo.jpg" width="120px">
		</td>
	</tr>
</table>
<table>
	<tr>
		<td>
			<table>
				<tr>
					<td class="mittel">%mittel</td>
				</tr>
			</table>
			<div class="time">
			<table>
				<tr>
					<td class="time">
						<div class="alarm_txt">Alarmierungszeit:</div>
						<div id="alarmzeit" class="alarm">%alarmzeit</div>
					</td>
					<td class="time">
						<div class="penalty_txt">Zeit seit Alarmierung:</div>
						<div id="penalty" class="penalty"></div>
					</td>
				</tr>
			</table>
			</div>
		</td>
		<td class="gmap">
			%map_tag
		</td>
	</tr>
</table>
<div id="clock" class="clock"></div>
<div id="status" class="status"></div>
</body>
<script src="scripts.js"></script>
</html>
