#!/bin/sh

# Created by  : FatiH OnuR
# Created in  : 08.12.09
##
### VERSION HISTORY
# Ver1        : Created for req id:2696
# Purpose     : (1) Cells at same site (RBS) are neighbours
# Description : (1) This implies there are 100 cells that have no relations to cells in the same RBS.
# Date        : 08 Nov 2009
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



#
## Creates inconsistency for WCC rule1
#
setNullEUtranCellRelation() # NENAME CELLCOUNT RELATIONID
{
NENAME=$1
CELLCOUNT=$2
RELATIONID=$3
cat >> $MOSCRIPT << MOSCT
SET
(
  mo ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=${NENAME}-$CELLCOUNT,EUtranFreqRelation=1,EUtranCellRelation=$RELATIONID"
    exception none
    nrOfAttributes 1
       neighborCellRef Ref null
)
MOSCT
}

delNullEUtranCellRelation() # NENAME CELLCOUNT RELATIONID
{
NENAME=$1
CELLCOUNT=$2
RELATIONID=$3
cat >> $MOSCRIPT << MOSCT
DELETE
(
  mo ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=${NENAME}-$CELLCOUNT,EUtranFreqRelation=1,EUtranCellRelation=$RELATIONID"
)
MOSCT
}


#
## Fix inconsistency for WCC rule1
#
setEUtranCellRelation() # NENAME CELLCOUNT RELATIONID TARGETCELLCOUNT
{
NENAME=$1
CELLCOUNT=$2
RELATIONID=$3
TARGETCELLCOUNT=$4
cat >> $MOSCRIPT << MOSCT
SET
(
  mo ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=${NENAME}-$CELLCOUNT,EUtranFreqRelation=1,EUtranCellRelation=$RELATIONID"
    exception none
    nrOfAttributes 1
       neighborCellRef Ref ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=${NENAME}-$TARGETCELLCOUNT
)
MOSCT
}

createEUtranCellRelation() # NENAME CELLCOUNT RELATIONID TARGETCELLCOUNT
{
NENAME=$1
CELLCOUNT=$2
RELATIONID=$3
TARGETCELLCOUNT=$4
cat >> $MOSCRIPT << MOSCT
CREATE
(
  parent ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=${NENAME}-$CELLCOUNT,EUtranFreqRelation=1"
    identity $RELATIONID
    moType EUtranCellRelation
    exception none
    nrOfAttributes 1
       neighborCellRef Ref ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=${NENAME}-$TARGETCELLCOUNT
)
MOSCT
}


echo ""
echo "script running, please wait..."

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

ERBSSTART=1
ERBSSTOP=8

ERBSCOUNT=$ERBSSTART
while [ "$ERBSCOUNT" -le "$ERBSSTOP" ]
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



 #
 # Create EUtranFreqRelation
 #


 #Loop through each Cell in ERBS
 CELLSTART=1
 CELLSTOP=4
 CELLCOUNT=$CELLSTART

 while [ "$CELLCOUNT" -le "$CELLSTOP" ]
 do


 #
 # Create Relations to Cells in same ERBS
 # Cell1 has Relations pointing to Cell2,3,4
 # Cell2 has Relations pointing to Cell1,3,4 ...etc
 #  

 TARGETCELLSTART=1
 TARGETCELLSTOP=4
 TARGETCELLCOUNT=$TARGETCELLSTART
 RELATIONID=1
 while [ "$TARGETCELLCOUNT" -le "$TARGETCELLSTOP" ]
 do
   
   if [ "$TARGETCELLCOUNT" -ne "$CELLCOUNT" ]
   then
   # echo "Setting Relation under EUtranCellFDD="${NENAME}"-"$CELLCOUNT
   # echo "To Point to EUtranCellFDD="${NENAME}"-"$TARGETCELLCOUNT

   # setNullEUtranCellRelation $NENAME $CELLCOUNT $RELATIONID # function used
    delNullEUtranCellRelation $NENAME $CELLCOUNT $RELATIONID # function used
   #setEUtranCellRelation $NENAME $CELLCOUNT $RELATIONID $TARGETCELLCOUNT # function used
   # createEUtranCellRelation $NENAME $CELLCOUNT $RELATIONID $TARGETCELLCOUNT # function used
 

   RELATIONID=`expr $RELATIONID + 1`
   fi

 TARGETCELLCOUNT=`expr $TARGETCELLCOUNT + 1`
 done

 CELLCOUNT=`expr $CELLCOUNT + 1`
 done

echo '.select '$NENAME >> $MMLSCRIPT
echo '.start ' >> $MMLSCRIPT
echo 'useattributecharacteristics:switch="off";' >> $MMLSCRIPT
echo 'kertayle:file="'$PWD'/'$MOSCRIPT'";' >> $MMLSCRIPT
   
  /netsim/inst/netsim_shell < $MMLSCRIPT
  
 
rm $PWD/$MOSCRIPT
rm $PWD/$MMLSCRIPT


ERBSCOUNT=`expr $ERBSCOUNT + 1`
done

echo ""
echo "done!!! thanks for your patient..."
echo ""
