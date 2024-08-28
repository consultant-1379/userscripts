#!/bin/sh

# Created by  : Fatih ONUR
# Created in  : 10.09.09
##
### VERSION HISTORY
# Ver1        : Created for Robert Guinan, req id:1880
# Purpose     : Add IubLink from 188 to 250
# Description : 
# Date        : 10 Sep 2009
# Who         : Fatih ONUR

if [ "$#" -ne 2  ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 <sim name> <rnc num>

Example: $0  RNCL130-ST-RNC28 28

HELP

exit 1
fi


SIMNAME=$1

if [ "$2" -le 9 ]
then
RNCNAME="RNC0"$2
RNCCOUNT="0"$2
else
RNCNAME="RNC"$2
RNCCOUNT=$2
fi



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


if [ "$2" -eq 2 ]
then
IUBEND=`expr $NUMOFRBS + 12` 
else
IUBEND=$NUMOFRBS
fi

if [ "$2" -ge 23 ] && [ "$2" -le 30 ]
then
ATM=0
IP=1
else
ATM=1
IP=0
fi

if [ "$2" -eq 32 ]
then
ATM=1
IP=1
fi

IUBSTART=188
IUBEND=250
IUBCOUNT=$IUBSTART

while [ "$IUBCOUNT" -le "$IUBEND" ]
do
echo 'CREATE' >> $MOSCRIPT
echo '(' >> $MOSCRIPT
echo '  parent "ManagedElement=1,RncFunction=1"' >> $MOSCRIPT
echo ' identity '$IUBCOUNT >> $MOSCRIPT
echo ' moType IubLink' >> $MOSCRIPT
echo ' exception none' >> $MOSCRIPT
echo ' nrOfAttributes 4' >> $MOSCRIPT
echo '   rbsId Integer '$IUBCOUNT >> $MOSCRIPT
echo ' rncModuleRef Ref "ManagedElement=1,RncFunction=1,RncModule=1"' >> $MOSCRIPT
echo '   controlPlaneTransportOption Struct' >> $MOSCRIPT
echo '      nrOfElements 2' >> $MOSCRIPT
echo '        atm Integer '$ATM >> $MOSCRIPT 
echo '        ipv4 Integer '$IP >> $MOSCRIPT
echo '   userPlaneTransportOption Struct' >> $MOSCRIPT
echo '      nrOfElements 2' >> $MOSCRIPT
echo '        atm Integer '$ATM >> $MOSCRIPT
echo '        ipv4 Integer '$IP >> $MOSCRIPT
echo ')' >> $MOSCRIPT

IUBCOUNT=`expr $IUBCOUNT + 1`

done



#########################################
#
# Make MML Script
#
#########################################

echo ""
echo "MAKING MML SCRIPT"
echo ""


echo '.open '$SIMNAME >> $MMLSCRIPT
echo '.select '$RNCNAME >> $MMLSCRIPT
echo '.start ' >> $MMLSCRIPT
echo 'useattributecharacteristics:switch="off";' >> $MMLSCRIPT
echo 'kertayle:file="'$PWD'/'$MOSCRIPT'";' >> $MMLSCRIPT





/netsim/inst/netsim_pipe < $MMLSCRIPT



rm $PWD/$MOSCRIPT
rm $PWD/$MMLSCRIPT





































