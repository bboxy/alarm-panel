<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<META http-equiv="content-type" content="text/html; charset=utf-8">
<meta http-equiv="cache-control" content="no-cache">
<title>Clock</title>
<link rel="STYLESHEET" type="text/css" href="/clock.css">
</head>
<body>
	<table>
		<tr>
			<td class="clock">

			<canvas id="clock" class="cv_clock" width="800" height="800">
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

			</td>
		</tr>
		<tr>
			<td id="datum" class="datum">
			</td>
		</tr>
	</table>
<script>
startDate();

function startDate() {
    var months = ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"];
    var today = new Date();
    var date = today.getDate() + ". " + months[today.getMonth()] + " " + today.getFullYear();
    document.getElementById('datum').innerHTML = date;
    var d = setTimeout(startDate, 5000);
}

</script>
</body>
</html>
