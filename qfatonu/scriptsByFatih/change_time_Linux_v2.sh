#!/bin/sh

# Created by  : qfatonu
# Created in  : 30 April 2009
##
### VERSION HISTORY
# Ver1        : Created for Usharani Marappani, req id:922.
# Purpose     : To synchronize time of servers according to defined target server.
# Description : Due to some permissin denied error, thi script should be
              :  located in target server
# Date        : 30 April 2009
# Who         : Fatih ONUR


TARGETSERVER=atrcus734
SERVERLIST="netsimlin271vm2 netsimlin271nm3 netsimlin271vm4"


#echo "$currentDate $currentTime"
echo ""

for server in $SERVERLIST
do

echo "NOW UPDATING.. >>"$server

systemDate=`date`
currentDate=`date +%Y-%m-%d`
currentTime=`date +%H:%M:%S`
echo "date -s \"$currentDate $currentTime\" > /dev/null" > /tmp/chgdate.sh
/usr/bin/rcp /tmp/chgdate.sh netsim@$server:/tmp/
/usr/bin/rsh -n -l root $server "chmod +x /tmp/chgdate.sh"
/usr/bin/rsh -n -l root $server "/tmp/chgdate.sh"
#/usr/bin/rsh -l root $server "clock -w"
#/usr/bin/rsh -l root $server "setclock"
SYNCDATE=`/usr/bin/rsh -n -l root $server date`
echo $TARGETSERVER" Server Date..>> "$systemDate
echo $server "Server Date..>> "$SYNCDATE

echo "UPDATED.. >>"$server
echo ""

done

