#!/bin/sh

# Created by  : FAtih ONUR
# Created in  : 04.12.09
##
### VERSION HISTORY
# Ver1        : Created for req id: 2757
# Purpose     : Set ENodeBfunction
# Description :
# Date        : 12 Nov 2009
# Who         : FAtih ONUR

if [ "$#" -ne 1  ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 <rnc num>

Example: $0 1

HELP

exit 1
fi

################################
# Functions
################################

getSimName() # LTENO
{
LTE=$1
if [ "$LTE" -le "9" ]
then
 LTESIM="LTE0"$LTE
else
 LTESIM="LTE"$LTE
fi
SIMNAME=`ls /netsim/netsimdir | grep ${LTESIM} | grep -v zip`
echo $SIMNAME
}


################################
# Main
################################

NUMOFRBS=160
CELLNUM=4
LTE=$1

LTESIM=`getSimName $LTE`
SIMNAME=`ls /netsim/netsimdir | grep ${LTESIM} | grep -v zip`
PWD=`pwd`

if [ "$LTE" -le "9" ]
then
 LTENAME="LTE0"$LTE"ERBS00"
else
 LTENAME="LTE"$LTE"ERBS00"
fi


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


START=1
STOP=$NUMOFRBS
COUNT=$START


# NB The eNBId attribute must be unique in the network

TEMP=`expr $LTE \* $NUMOFRBS`
MINUS=`expr $NUMOFRBS - $START`
STARTENBID=`expr $TEMP - $MINUS`
ENBID=$STARTENBID

while [ "$COUNT" -le "$STOP" ]
do


echo 'SET' >> $MOSCRIPT
echo '(' >> $MOSCRIPT
echo '  mo "ManagedElement=1,ENodeBFunction=1"' >> $MOSCRIPT
echo '   identity 1' >> $MOSCRIPT
echo '   exception none' >> $MOSCRIPT
echo '   nrOfAttributes 2' >> $MOSCRIPT
echo '   eNodeBPlmnId Struct'  >> $MOSCRIPT
echo '   nrOfElements 3' >> $MOSCRIPT
echo '   mcc Integer 353' >> $MOSCRIPT
echo '   mnc Integer 57' >> $MOSCRIPT
echo '   mncLength Integer 2' >> $MOSCRIPT
echo '   eNBId Integer '$ENBID >> $MOSCRIPT
echo ')' >> $MOSCRIPT

ENBID=`expr $ENBID + 1`

 if [ "$COUNT" -le 9 ]
 then
    NENAME=${LTENAME}"00"$COUNT
 else
   if [ "$COUNT" -le 99 ]
   then
     NENAME=${LTENAME}"0"$COUNT
   else
     NENAME=${LTENAME}$COUNT
   fi
 fi


echo '.open '$SIMNAME >> $MMLSCRIPT
echo '.select '$NENAME >> $MMLSCRIPT
echo '.start ' >> $MMLSCRIPT
echo 'useattributecharacteristics:switch="off";' >> $MMLSCRIPT
echo 'kertayle:file="'$PWD'/'$MOSCRIPT'";' >> $MMLSCRIPT

  /netsim/inst/netsim_shell < $MMLSCRIPT

rm $PWD/$MOSCRIPT
rm $PWD/$MMLSCRIPT


COUNT=`expr $COUNT + 1`
done


