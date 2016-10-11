<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<META http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta content="text/html; charset=ISO-8859-1" http-equiv="content-type">
<meta http-equiv="cache-control" content="no-cache">
<title>Alarm</title>
<link rel="STYLESHEET" type="text/css" href="stylesheet.css">
%map_script%
</head>
<body onload="reloadWatch(); reloadFMS(); startTime(); initMap(&quot;%query%&quot;);">
<table>
	<tr>
		<td class="header">
			<table>
				<tr>
					<td class="header_left">
						<div class="schlagwort">
							%schlagwort%
						<div>
						<div class="info">
							%bemerkung%
						</div>
					</td>
					<td class="header_right">
						<table>
							<tr>
								<td>
									<div class="addr">
										%strasse% %nummer%<br>
										%ort%<br>
										%abschnitt%
									</div>
								</td>
								<td>
									<div class="logo">
										<img src="logo.png" class="logo">
									</div>
								</td>
							</tr>
						</table>
					</td>
				</tr>
			</table>
		</td>
	</tr>
	<tr>
		<td class="main">
			<table>
				<tr>
					<td class="main_left">
						%mittel%
					</td>
					<td class="main_right">
						%map_tag%
					</td>
				</tr>
			</table>
		</td>
	</tr>
	<tr>
		<td class="bottom">
			<table>
				<tr>
					<td class="bottom_tile">
						<div class="alarm_txt">Alarmierungszeit:</div>
						<div id="alarmzeit" class="alarm">%alarmzeit%</div>
					</td>
					<td class="bottom_tile">
						<div class="penalty_txt">Zeit seit Alarmierung:</div>
						<div id="penalty" class="penalty"></div>
					</td>
					<td class="bottom_tile">
						<div class="alarm_txt">aktuelle Zeit:</div>
						<div id="clock" class="clock"></div>
					</td>
					<td class="bottom_status">
						%status%
					</td>
				</tr>
			</table>
		</td>
	</tr>
</table>
</body>
<script src="scripts.js"></script>
</html>
