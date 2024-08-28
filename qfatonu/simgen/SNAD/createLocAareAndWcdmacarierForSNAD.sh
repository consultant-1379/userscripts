#!/bin/sh

# Created by  : qfatonu
# Created in  : 26 August 2009
##
### VERSION HISTORY
# Ver1        : Created for WRAN deployment o.10.0 ShipG, req id:1361
# Purpose     : Create LacationArea and WcdmCarries MO for SNAD.
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
PWD=`pwd`


MOSCRIPT=$0".mo"
MMLSCRIPT=$0".mml"

if [ -f $PWD/$MOSCRIPT ]
then
rm -r  $PWD/$MOSCRIPT
echo "old "$PWD/$MOSCRIPT " removed"
fi


if [ -f $PWD/$MMLSCRIPT ]
then
rm -r  $PWD/$MMLSCRIPT
echo "old "$PWD/$MMLSCRIPT " removed"
fi



#########################################
# 
# Make MO Script
#
#########################################

echo ""
echo "MAKING MO SCRIPT"
echo ""


if [ "$RNC" == "RNC33" ]
then
TYPE=1
t3212=10
else
TYPE=2
t3212=25
fi

COUNTER=1
while [ "$COUNTER" -le 1 ]
do

echo 'CREATE' >> $MOSCRIPT
echo '(' >> $MOSCRIPT
echo '  parent "ManagedElement=1,RncFunction=1"' >> $MOSCRIPT
echo '   identity 5' >> $MOSCRIPT
echo '   moType WcdmaCarrier' >> $MOSCRIPT
echo '   exception none' >> $MOSCRIPT
echo '   nrOfAttributes 1' >> $MOSCRIPT
echo '     defaultHoType Integer '$TYPE >> $MOSCRIPT
echo ')' >> $MOSCRIPT


COUNTER=`expr $COUNTER + 1`
done



if [ "$RNC" == "RNC34" ]
then

COUNTER2=506
while [ "$COUNTER2" -le 507 ]
do

echo 'CREATE' >> $MOSCRIPT
echo '(' >> $MOSCRIPT
echo '  parent "ManagedElement=1,RncFunction=1"' >> $MOSCRIPT
echo ' identity '$COUNTER2 >> $MOSCRIPT
echo ' moType LocationArea' >> $MOSCRIPT
echo ' exception none' >> $MOSCRIPT
echo ' nrOfAttributes 3' >> $MOSCRIPT
echo ' lac Integer '$COUNTER2 >> $MOSCRIPT
echo ' t3212 Integer '$t3212 >> $MOSCRIPT
echo ' userLabel String LOCATIONAREA'$COUNTER2 >> $MOSCRIPT
echo ')' >> $MOSCRIPT

COUNTER2=`expr $COUNTER2 + 1`
done

fi

#########################################
#
# Make MML Script
#
#########################################

echo ""
echo "MAKING MML SCRIPT"
echo ""

SIM=`ls /netsim/netsimdir | grep ${RNC} | grep -v zip`

echo '.open '$SIM >> $MMLSCRIPT
echo '.select '$RNC >> $MMLSCRIPT
echo '.start ' >> $MMLSCRIPT
echo 'useattributecharacteristics:switch="off";' >> $MMLSCRIPT
echo 'kertayle:file="'$PWD'/'$MOSCRIPT'";' >> $MMLSCRIPT

/netsim/inst/netsim_shell < $MMLSCRIPT

rm $PWD/$MOSCRIPT
rm $PWD/$MMLSCRIPT
