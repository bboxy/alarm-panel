#!/bin/sh
mount /media/fritzbox/
cd /home/localadm/repo/ffw
./extract.pl
read -n1 -r -p "Press any key to continue..." key
