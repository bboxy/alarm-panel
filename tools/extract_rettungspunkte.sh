#!/bin/sh
echo "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<kml xmlns=\"http://www.opengis.net/kml/2.2\">\n<Document id=\"root_doc\">"
#cat $1 | sed "r/\\r//g" | grep --no-group-separator -A 8 -B 2 -E "name=\"RP_Nr\">(NU|UL|GZ)"
sed -n '/Placemark/!b;:a;/\/Placemark/!{$!{N;ba}};{/name=\"RP_Nr\">NU/p}' $1
sed -n '/Placemark/!b;:a;/\/Placemark/!{$!{N;ba}};{/name=\"RP_Nr\">UL/p}' $1
sed -n '/Placemark/!b;:a;/\/Placemark/!{$!{N;ba}};{/name=\"RP_Nr\">GZ/p}' $1
echo "</Document>\n</kml>"
