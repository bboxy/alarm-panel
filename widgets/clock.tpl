<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<META http-equiv="content-type" content="text/html; charset=utf-8">
<meta http-equiv="cache-control" content="no-cache">
<title>Clock</title>
<link rel="STYLESHEET" type="text/css" href="/stylesheet.css">
</head>
<body class="clock">
		<div class="st_clock">
			<iframe class="widget" scrolling="no" src="stationclock.html"></iframe>
		</div>
		<div id="datum" class="st_datum">
		</div>
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
