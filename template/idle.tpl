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
			<canvas id="clock" class="cv_clock" width="800px" height="800px">
			  Dieser Browser wird leider nicht unterstützt.
			</canvas>
			<!--[if lt IE 9]>
			  <script type="text/javascript" src="excanvas.js"></script>
			<![endif]-->
			<script type="text/javascript" src="clock/station-clock.js"></script>
			<script type="text/javascript">

			  var clock = new StationClock("clock");
			  clock.body = StationClock.RoundBody;
			  clock.dial = StationClock.GermanStrokeDial;
			  clock.hourHand = StationClock.PointedHourHand;
			  clock.minuteHand = StationClock.PointedMinuteHand;
			  clock.secondHand = StationClock.HoleShapedSecondHand;
			  clock.boss = StationClock.NoBoss;
			  clock.minuteHandBehavoir = StationClock.BouncingMinuteHand;
			  clock.secondHandBehavoir = StationClock.BouncingSecondHand;

			  window.setInterval(function() { clock.draw() }, 5);

			</script>
			<div id="idle_datum" class="idle_datum"></div>
		</td>
		<td class="idle_right">
			<iframe class="weather" scrolling="no" src="weather.html">
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
