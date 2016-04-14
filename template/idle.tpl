<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<META http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta content="text/html; charset=ISO-8859-1" http-equiv="content-type">
<title>Alarm</title>
<link rel="STYLESHEET" type="text/css" href="stylesheet.css">
</head>
<body onload="reloadWatch(); reloadFMS(); startDate();">
<canvas id="clock" class="cv_clock" width="800px", height="800px">
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
  clock.secondHandBehavoir = StationClock.OverhastySecondHand;

  window.setInterval(function() { clock.draw() }, 50);

</script>
<div id="datum" class="datum"></div>
<div id="status" class="status"></div>
</body>
<script src="scripts.js"></script>
</html>
