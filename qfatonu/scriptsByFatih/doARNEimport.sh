#!/bin/sh

# Created by  : Fatih ONUR
# Created in  : 24.02.2010
##
### VERSION HISTORY
# Ver1        : Created for ARNE import 10.2
# Purpose     : Run ARNE import command for all RNNCS
# Description : 
# Date        : 10 Sep 2009
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

RNCSTART=13
RNCEND=34


RNCCOUNT=$RNCSTART
while [ "$RNCCOUNT" -le "$RNCEND" ]
do

  if [ "$RNCCOUNT" -le 9 ]
  then
    RNCNAME="RNC0"$RNCCOUNT
  else 
    RNCNAME="RNC"$RNCCOUNT
  fi

  echo "########################################" | tee -a $LOGFILE
  echo "# RNCNO="$RNCNAME | tee -a $LOGFILE
  echo "########################################" | tee -a $LOGFILE
  date 2>&1 | tee -a $LOGFILE
  echo ""
 
  /opt/ericsson/arne/bin/import.sh -f import_${RNCNAME}.xml.atrcus734 -import 2>&1 | tee -a $LOGFILE
  
 
  echo ""
  echo ""
  RNCCOUNT=`expr $RNCCOUNT + 1`


done
