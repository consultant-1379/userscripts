#!/bin/sh

# Created by  : FatiH OnuR
# Created in  : 07.12.09
##
### VERSION HISTORY
# Ver1        : Created for req id:2765
# Purpose     : To Correct wrong eNBId among ExternalENodeBFunction MOs
# Description :
# Date        : 07 Nov 2009
# Who         : Fatih ONUR
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Ver2        : 
# Purpose     : 
# Description :
# Date        : 
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

echo ""
echo "MAKING MO SCRIPT"
echo ""

############################################
#
# LTE01ERBS01 has ExternalENodeBFunction 1-16 !1
# LTE01ERBS02 has ExternalENodeBFunction 1-16 !2
# LTE01ERBS03 has ExternalENodeBFunction 1-16 !3
# . . . . . . . . . . . . .  . . . . . . . 
# . . . . . . . . . . . . . . . . . . . . .
# LTE01ERBS16 has ExternalENodeBFunction 1-16 !16
#
# LTE01ERBS17 has ExternalENodeBFunction 17-32 !17 
# LTE01ERBS18 has ExternalENodeBFunction 17-32 !18 ...etc
#
# .......etc
#
# LTE02ERBS01 has ExternalENodeBFunction 161-176 !161
# LTE02ERBS02 has ExternalENodeBFunction 161-176 !162
#
# LTE02ERBS16 has ExternalENodeBFunction 161-176 !176
#
# LTE02ERBS17 has ExternalENodeBFunction 177-192 !177
#
#  ......etc
#
############################################

ERBSCOUNT=152

###########################################
#
# LTE01 has 160 ERBS, so the first ERBS is ERBSID=1
# LTE02 has 160 ERBS, so the first ERBS is ERBSID=161 ...etc
#
# An = A1 + d (n -1)
# An = 1 + 160(n-1)
# An = 160n - 159
#
#
###########################################

TEMP=`expr $LTE \* $NUMOFRBS`
MINUS=`expr $NUMOFRBS - $ERBSCOUNT`
TEMPEXTENODEBIDSTART=`expr $TEMP - $MINUS`

MOD=`expr $TEMPEXTENODEBIDSTART % 16`
DIV=`expr $TEMPEXTENODEBIDSTART / 16`

if [ "$MOD" -gt 0 ]
then
  EXTENODEBIDSTART=`expr \( 16 \* $DIV \) + 1`
else
  EXTENODEBIDSTART=`expr \( 16 \* \( $DIV - 1 \) \) + 1`
fi


# ERBSTOTALCOUNT keeps of count of the total number of ERBSs in network

ERBSTOTALCOUNT=$TEMPEXTENODEBIDSTART


while [ "$ERBSCOUNT" -le "$NUMOFRBS"  ]
do
 echo '.open '$SIMNAME > $MMLSCRIPT
 if [ "$ERBSCOUNT" -le 9 ]
 then
    NENAME=${LTENAME}"00"$ERBSCOUNT
 else
   if [ "$ERBSCOUNT" -le 99 ]
   then
     NENAME=${LTENAME}"0"$ERBSCOUNT
   else
     NENAME=${LTENAME}$ERBSCOUNT
   fi
 fi




EXTENODEBID=$EXTENODEBIDSTART
EXTENODEBIDSTOP=`expr $EXTENODEBID + 15`

echo "********************"
echo "LTE="$NENAME
echo "LOCAL ERBS"=$ERBSCOUNT
echo "TOTAL ERBS"=$ERBSTOTALCOUNT
echo "*******************"

while [ "$EXTENODEBID" -le "$EXTENODEBIDSTOP" ]
do


 if [ "$EXTENODEBID" -ne "$ERBSTOTALCOUNT" ]
 then

   echo 'SET' >> $MOSCRIPT
   echo '(' >> $MOSCRIPT
   echo '  mo "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction='$EXTENODEBID'"' >> $MOSCRIPT
   echo '   exception none' >> $MOSCRIPT
   echo '   nrOfAttributes 2' >> $MOSCRIPT
   echo '    eNBId Integer '$EXTENODEBID >> $MOSCRIPT
   echo '    eNodeBPlmnId Struct' >> $MOSCRIPT
   echo '      nrOfElements 3' >> $MOSCRIPT
   echo '       mcc Integer 353' >> $MOSCRIPT
   echo '       mnc Integer 57' >> $MOSCRIPT
   echo '       mncLength Integer 2' >> $MOSCRIPT
   echo ')' >> $MOSCRIPT

   #####################################
   #
   # An=4n-3
   # 
   # 
   #
   #
   ##################################### 

   TEMP1=`expr 4 \* $EXTENODEBID`
   CELLSTART=`expr $TEMP1 - 3`
   CELLCOUNT=$CELLSTART
   CELLSTOP=`expr $CELLSTART + 3`

   while [ "$CELLCOUNT" -le "$CELLSTOP" ]
   do

   echo 'SET' >> $MOSCRIPT
   echo '(' >> $MOSCRIPT
   echo '  mo "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction='$EXTENODEBID',ExternalEUtranCellFDD='$CELLCOUNT'"' >> $MOSCRIPT
   echo '   exception none' >> $MOSCRIPT
   echo '   nrOfAttributes 1' >> $MOSCRIPT
   echo '    eutranFrequencyRef Ref "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,EUtranFrequency=1"' >> $MOSCRIPT
   echo ')' >> $MOSCRIPT

   CELLCOUNT=`expr $CELLCOUNT + 1`
   done

#   echo "Setting ExternalENodeBFunction="$EXTENODEBID
 fi


EXTENODEBID=`expr $EXTENODEBID + 1`
done


echo '.select '$NENAME >> $MMLSCRIPT
echo '.start ' >> $MMLSCRIPT
echo 'useattributecharacteristics:switch="off";' >> $MMLSCRIPT
echo 'kertayle:file="'$PWD'/'$MOSCRIPT'";' >> $MMLSCRIPT

  /netsim/inst/netsim_shell < $MMLSCRIPT

rm $PWD/$MOSCRIPT
rm $PWD/$MMLSCRIPT


REM=`expr $ERBSCOUNT \% 16`
if [ "$REM" -eq "0" ]
then 
 EXTENODEBIDSTART=`expr $EXTENODEBIDSTART + 16`
else
 echo "dont change it" >> /dev/null
fi

ERBSTOTALCOUNT=`expr $ERBSTOTALCOUNT + 1`
ERBSCOUNT=`expr $ERBSCOUNT + 1`
done

