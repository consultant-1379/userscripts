#!/bin/sh

# Created by  : Fatih ONUR
# Created in  : 24.02.2010
##
### VERSION HISTORY
# Ver1        : Created for ARNE import 10.2
# Purpose     : Run ARNE import command for all LTEs
# Description : 
# Date        : 25 Feb 2010
# Who         : Fatih ONUR

if [ "$#" -ne 1  ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 <go>

Example: $0 go 

HELP

exit 1
fi


PWD=`pwd`

LOGFILE=$0.log



if [ -f $PWD/$LOGFILE ]
then
 rm $PWD/$LOGFILE 
 echo ${LOGFILE}" log file deleted" 
 echo ""
fi

LTESTART=13
LTEEND=25


LTECOUNT=$LTESTART
while [ "$LTECOUNT" -le "$LTEEND" ]
do

  if [ "$LTECOUNT" -le 9 ]
  then
    LTENAME="LTE0"$LTECOUNT
  else 
    LTENAME="LTE"$LTECOUNT
  fi

  echo "########################################" | tee -a $LOGFILE
  echo "# LTENO="$LTENAME | tee -a $LOGFILE
  echo "########################################" | tee -a $LOGFILE
  date 2>&1 | tee -a $LOGFILE
  echo ""
 
  /opt/ericsson/arne/bin/import.sh -f import_${LTENAME}.xml.atrcus575 -i_nau -import 2>&1 | tee -a $LOGFILE
  
 
  smtool offline Region_CS Seg_masterservice_CS ARNEServer MAF ONRM_CS -reason=other -reasontext=other
  sleep 100
  smtool online Region_CS Seg_masterservice_CS ARNEServer MAF ONRM_CS
  sleep 300
 
  echo ""
  echo ""
  LTECOUNT=`expr $LTECOUNT + 1`


done
