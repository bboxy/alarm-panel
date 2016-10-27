<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<META http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta content="text/html; charset=ISO-8859-1" http-equiv="content-type">
<meta http-equiv="cache-control" content="no-cache">
<title>Alarm</title>
<link rel="STYLESHEET" type="text/css" href="stylesheet.css">
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
			 <object class="dwd" data="dwd/WarnModulDWD.swf?HOME=dwd/" type="application/x-shockwave-flash">
			  <param name="movie" value="dwd/WarnModulDWD.swf?HOME=dwd/">
			  <param name="quality" value="high">
			  <param name="menu" value="false">
			  <param name="wmode" value="opaque">
			                <!--h4>Für den Inhalt dieser Seite ist der Adobe Flash Player erforderlich.</h4>
			                <p><a href="http://www.adobe.com/go/getflashplayer"><img src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif" alt="Adobe Flash Player herunterladen" width="112" height="33" /></a></p-->
			 </object>
		</td>
	</tr>
</table>
<div class="idle_status">
%status%
</div>
<div class="idle_logo">
	<img class="logo" src="logo.png">
</div>
<script src="scripts.js"></script>
</body>
</html>
