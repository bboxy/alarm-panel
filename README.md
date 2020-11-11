# alarm-panel

## Einsatz-Informations-System der Freiwilligen Feuerwehr Straß

### Funktionen

Das System arbeitet die Faxe der Leitstelle digital auf und wertet diese aus und stellt die Informationen entsprechend dar. Bereitstellung der Faxe via SMB-Freigabe (.tif, .pdf, .sff, .txt) oder E-Mail (.tif, .pdf, .sff) möglich.

Die Ruheseite zeigt Datum und Uhrzeit und Wetterwarnungen des DWD im auf einer Karte an, die in regelmässigen Abständen aktualisiert werden.

Auf der Kartenansicht werden Hydranten, Waldrettungspunkte und Bahnkilometer zusätzlich angezeigt, da diese für Einsätze entsprechend interessant sind.

Die Anzeige wird über einen Webserver bereitgestellt, somit können über SmartTVs mit Browser oder Monitore mit kleinen Rechnern (wie etwa auch Raspberry PIs) die Seiten entsprechend angezeigt werden. Hierzu gibt es verschiedene Ansichten.

Über die API von Divera 24/7 kann ein Alarm über Dvera initiiert werden.

Das Einsatzfax, sowie eine Karte der Umgebung der Einsatzstelle mit einigen Zusatzinformationen können gedruckt werden.

### Screenshots

![Idle Display](https://github.com/bboxy/alarm-panel/raw/master/screenshots/idle.png)

![Active Display](https://github.com/bboxy/alarm-panel/raw/master/screenshots/active.png)

![Map View](https://github.com/bboxy/alarm-panel/raw/master/screenshots/map.png)
