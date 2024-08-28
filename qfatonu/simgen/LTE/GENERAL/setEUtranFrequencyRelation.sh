#!/bin/sh

# Created by  : Ronan Mehigan
# Created in  : 14.07.09
##
### VERSION HISTORY
# Ver1        : Created for LTE O 10.0 TERE
# Purpose     :
# Description :
# Date        : 14 July 2009
# Who         : Ronan Mehigan
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Ver2        : Created for req id:2757
# Purpose     : Set "eutranFrequencyRef" 
# Description :
# Date        : 04 Nov 2009
# Who         : Fatih ONUR

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

#########################################
#
# Make MML Script
#
#########################################

echo ""
echo "MAKING MML SCRIPT"
echo ""

COUNT=1

while [ "$COUNT" -le "$NUMOFRBS"  ]
do
 echo '.open '$SIMNAME > $MMLSCRIPT
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

CELLCOUNT=1
while [ "$CELLCOUNT" -le "$CELLNUM" ]
do
cat >> $MOSCRIPT << MOSCT
CREATE
(
   parent "ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=${NENAME}-$CELLCOUNT"
   identity 1
   moType EUtranFreqRelation
   exception none
    nrOfAttributes 1
      "eutranFrequencyRef" Ref "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,EUtranFrequency=1"
)
MOSCT
CELLCOUNT=`expr $CELLCOUNT + 1`
done

 echo '.select '$NENAME >> $MMLSCRIPT 
 echo '.start ' >> $MMLSCRIPT
 echo 'useattributecharacteristics:switch="off";' >> $MMLSCRIPT
 echo 'kertayle:file="'$PWD'/'$MOSCRIPT'";' >> $MMLSCRIPT
  /netsim/inst/netsim_shell < $MMLSCRIPT

 COUNT=`expr $COUNT + 1`
 rm $PWD/$MOSCRIPT
done

rm $PWD/$MMLSCRIPT

