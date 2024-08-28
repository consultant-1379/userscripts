#!/bin/sh

# Created by  : qfatonu
# Created in  : 11 Nov 2009
##
### VERSION HISTORY
# Ver1        : Created for WRAN deployment o.10.0 ShipG, req id:2520
# Purpose     : To check RXI CrossConection erros are still exist on simulations
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
# CROSSCONNECTED NETWORK
#########################
# start from RNC04 to RNC16
# and start from RNC31 to RNC33


RNCSTART=31
RNCEND=33
RNCCOUNT=$RNCSTART

while [ "$RNCCOUNT" -le "$RNCEND" ]
do


if [ "$RNCCOUNT" -le 9 ]
then
RNCNAME="RNC0"$RNCCOUNT
RNCCOUNT="0"$RNCCOUNT
else
RNCNAME="RNC"$RNCCOUNT
RNCCOUNT=$RNCCOUNT
fi

if [ "$RNCCOUNT" -eq 33 ] || [ "$RNCCOUNT" -eq 34 ]
then
NUMOFRBS=768
echo "NUMOFRBS=768"
else
NUMOFRBS=187
echo "NUMOFRBS=187"
fi
PWD=`pwd`

  echo "RNCNAME:"$RNCNAME
  RXISTART=1
  RXIEND=2
  RXICOUNT=$RXISTART
  while [ "$RXICOUNT" -le "$RXIEND" ]
  do
    
     #echo "RXICOUNT="$RXICOUNT
     echo '****************************************************' | tee -a $LOGFILE
     echo "$RNCNAME RXI0${RXICOUNT}  " | tee -a $LOGFILE
     echo '****************************************************' | tee -a $LOGFILE
     /opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s Seg_masterservice_CS -ns masterservice la SubNetwork=ONRM_RootMo_R,MeContext=${RNCNAME}RXI0${RXICOUNT},ManagedElement=1,TransportNetwork=1,AtmCrossConnection=RBS-96-11 2>&1 | tee -a $LOGFILE

     RXICOUNT=`expr $RXICOUNT + 1`
  done
RNCCOUNT=`expr $RNCCOUNT + 1`

if [ "$RNCCOUNT" -eq 17 ]
then
  echo "IP Network from RNC17 to RNC30 discarded"  2>&1 | tee -a $LOGFILE
  RNCCOUNT=31
fi

done



