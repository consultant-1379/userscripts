#!/bin/sh

# Created by  : qfatonu
# Created in  : 26 August 2009
##
### VERSION HISTORY
# Ver1		  : Karthik Rangasammy script
# Ver2        : Created for WRAN deployment O.10.0 ShipG, SNAD Inconsistencies, req id:1361
# Purpose     : Modifies the attribute iqRxLevMin for 4000 Instances of ExternalUtranCell. 
#			  : Modifies the attribute UserLabel for 2000 Instances of ExternalUtranCell. 
#			  : Modifies the attribute maxTxPowerUl for 100 Instances of ExternalUtranCell. 
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

INSTANCES1=4000 # iqRxLevMin
INSTANCES2=2000 # userLabel
INSTANCES3=100 # maxTxPowerUl

IURLINK=96
EXUTRANCELL=46901

COUNT=1
while [ "$COUNT" -le "$INSTANCES1" ] 
do

# qRxLevMin
echo 'setmoattribute:mo="ManagedElement=1,RncFunction=1,IurLink='$IURLINK',ExternalUtranCell='$EXUTRANCELL'",attributes="qRxLevMin (long)=200";'
echo 'setmoattribute:mo="ManagedElement=1,RncFunction=1,IurLink='$IURLINK',ExternalUtranCell='$EXUTRANCELL'",attributes="qRxLevMin (long)=200";' >> $MMLSCRIPT

if [ "$COUNT" -le "$INSTANCES2" ]
then
# userLabel
echo 'setmoattribute:mo="ManagedElement=1,RncFunction=1,IurLink='$IURLINK',ExternalUtranCell='$EXUTRANCELL'",attributes="userLabel (str)=ExternalUtranCell-'$EXUTRANCELL'-for SNAD Inconsistency";'
echo 'setmoattribute:mo="ManagedElement=1,RncFunction=1,IurLink='$IURLINK',ExternalUtranCell='$EXUTRANCELL'",attributes="userLabel (str)=ExternalUtranCell-'$EXUTRANCELL'-for SNAD Inconsistency";' >> $MMLSCRIPT
fi

if [ "$COUNT" -le "$INSTANCES3" ]
then
# maxTxPowerUl
echo 'setmoattribute:mo="ManagedElement=1,RncFunction=1,IurLink='$IURLINK',ExternalUtranCell='$EXUTRANCELL'",attributes="maxTxPowerUl (long)=200";'
echo 'setmoattribute:mo="ManagedElement=1,RncFunction=1,IurLink='$IURLINK',ExternalUtranCell='$EXUTRANCELL'",attributes="maxTxPowerUl (long)=200";' >> $MMLSCRIPT
echo "#########"
fi



REM=`expr $COUNT % 1050` 
if [ "$REM" -eq 0 ]
then
IURLINK=`expr $IURLINK + 1`
fi
EXUTRANCELL=`expr $EXUTRANCELL + 1`

COUNT=`expr $COUNT + 1`
done

echo 'Executing MMLScript...'
/netsim/inst/netsim_shell < $MMLSCRIPT
rm -r  $PWD/$MMLSCRIPT
echo 'Finished'
