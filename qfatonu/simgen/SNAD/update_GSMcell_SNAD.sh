#!/bin/sh

# Created by  : qfatonu
# Created in  : 26 August 2009
##
### VERSION HISTORY
# Ver1		  : Karthik Rangasammy script
# Ver2        : Created for WRAN deployment O.10.0 ShipG, SNAD Inconsistencies, req id:1361
# Purpose     : Modifies the attribute bandIndicator for 4000 Instances of ExternalGsmCell. 
#			  : Modifies the attribute MaxTxPowerUl for 500 Instances of ExternalGsmCell. 
# Description : 
# Date        : 26 August 2009 
# Who	      : Fatih ONUR

if [ $# -ne 1 ]; then

cat << HELP

Usage: $0 <rnc name>
Example: $0 RNC33
    
HELP
exit 1
fi

RNC=$1
MMLSCRIPT=$0".mml"

PWD=`pwd`
if [ -f $PWD/$MMLSCRIPT ]
then
  rm -r  $PWD/$MMLSCRIPT
  echo "old "$PWD/$MMLSCRIPT " removed"
fi

SIM=`ls /netsim/netsimdir | grep ${RNC} | grep -v zip`

echo 'Creating MMLScript...'
echo '.open '$SIM 
echo '.open '$SIM >> $MMLSCRIPT
echo '.select '${RNC}
echo '.select '${RNC} >> $MMLSCRIPT

INSTANCES=4000 # for bandIndicator
INSTANCES2=500 # for MaxTxPowerUl
GSMNW=84
GSMCELL=18101

COUNT=1
while [ "$COUNT" -le "$INSTANCES2" ] 
do
#echo 'setmoattribute:mo="ManagedElement=1,RncFunction=1,ExternalGsmNetwork='$GSMNW',ExternalGsmCell='$GSMCELL'",attributes="bandIndicator (long)=1";'
#echo 'setmoattribute:mo="ManagedElement=1,RncFunction=1,ExternalGsmNetwork='$GSMNW',ExternalGsmCell='$GSMCELL'",attributes="bandIndicator (long)=1";' >> $MMLSCRIPT

if [ "$COUNT" -le "$INSTANCES2" ]
then
echo 'setmoattribute:mo="ManagedElement=1,RncFunction=1,ExternalGsmNetwork='$GSMNW',ExternalGsmCell='$GSMCELL'",attributes="maxTxPowerUl (long)=200";'
echo 'setmoattribute:mo="ManagedElement=1,RncFunction=1,ExternalGsmNetwork='$GSMNW',ExternalGsmCell='$GSMCELL'",attributes="maxTxPowerUl (long)=200";' >> $MMLSCRIPT
echo "#########"
fi

REM=`expr $COUNT % 1100` 
if [ "$REM" -eq 0 ]
then
GSMNW=`expr $GSMNW + 1`
fi
GSMCELL=`expr $GSMCELL + 1`

COUNT=`expr $COUNT + 1`
done

echo 'Executing MMLScript...'
/netsim/inst/netsim_shell < $MMLSCRIPT
rm -r  $PWD/$MMLSCRIPT
echo 'Finished'
