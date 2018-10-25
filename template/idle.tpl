<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<META http-equiv="content-type" content="text/html; charset=utf-8">
<meta http-equiv="cache-control" content="no-cache">
<title>Alarm</title>
<link rel="STYLESHEET" type="text/css" href="stylesheet.css">
<script src="scripts.js"></script>
</head>
<body onload="reloadWatch(); reloadFMS(); startDate();">

<table>
	<tr>
		<td class="idle_left">
			<iframe class="widget" scrolling="no" src="clock.html"></iframe>
		</td>
		<td class="idle_right">
			<iframe class="widget" scrolling="no" src="weather.html"></iframe>
		</td>
	</tr>
</table>
<div class="idle_status">
%status%
</div>
<!--div class="idle_logo">
	<img class="logo" src="logo.png">
</div-->
</body>
</html>
