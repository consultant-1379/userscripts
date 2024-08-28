#!/bin/sh

# Created by  : qfatonu
# Created in  : 11 Nov 2009
##
### VERSION HISTORY
# Ver1        : Created for WRAN deployment o.10.0 ShipG, req id:2520
# Purpose     : To check double eNBId
# Description : 
# Date        : 11.11.2009 
# Who	      : Fatih ONUR

if [ "$#" -ne 1  ]
then
cat<<HELP

Usage: $0 <start>

Example: $0 start

CONFIG : Followring variables can be set within scripts

HELP
 exit 1
fi


LOGFILE=$0.log

if [ -f $PWD/$LOGFILE ]
then
rm -r  $PWD/$LOGFILE
echo "old "$PWD/$LOGFILE" removed"
fi

###########################
# 
#########################
# 
#


START=749
END=800
COUNT=$START

while [ "$COUNT" -le "$END" ]
do

     echo "eNBId="$COUNT
     echo '****************************************************' | tee -a $LOGFILE
     echo '/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s Seg_masterservice_CS -ns masterservice lt ENodeBFunction -f '\'$.eNBId==$COUNT\''' | tee -a $LOGFILE
     echo '****************************************************' | tee -a $LOGFILE
     /opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s Seg_masterservice_CS -ns masterservice lt ENodeBFunction -f $.eNBId==${COUNT}  2>&1 | tee -a $LOGFILE


COUNT=`expr $COUNT + 1`

done



