#!/bin/sh

# Created by  : FatiH OnuR
# Created in  : 08.12.09
##
### VERSION HISTORY
# Ver1        : Created for req id:2696
# Purpose     : (1) Cells at same site (RBS) are neighbours (2) At least one neighbour per cell
# Description : (1) This implies there are 100 cells that have no relations to cells in the same RBS.
#		(2) This implies there are 100 cells with no relations
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
## Creates inconsistency for WCC rule1 and rule2
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
WNENAME=$1
WCELLCOUNT=$2
WRELATIONID=$3
WTARGETCELLCOUNT=$4
cat >> $MOSCRIPT << MOSCT
SET
(
  mo ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=${WNENAME}-$WCELLCOUNT,EUtranFreqRelation=1,EUtranCellRelation=$WRELATIONID"
    exception none
    nrOfAttributes 1
       neighborCellRef Ref ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=${WNENAME}-$WTARGETCELLCOUNT
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


#
## Fix inconsistency for WCC rule2
#
setEUtranCellRelation_v2() # NENAME CELLCOUNT RELATIONID EXTENODEBID XCELLCOUNT/NEWXCELLCOUNT
{
NENAME=$1
CELLCOUNT=$2
RELATIONID=$3
EXTENODEBID=$4
XCELLCOUNT=$5
cat >> $MOSCRIPT << MOSCT
SET
(
  mo "ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=${NENAME}-$CELLCOUNT,EUtranFreqRelation=1,EUtranCellRelation=$RELATIONID"
    exception none"
      nrOfAttributes 1
        neighborCellRef Ref ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction=$EXTENODEBID,ExternalEUtranCellFDD=$XCELLCOUNT

)
MOSCT
}

createEUtranCellRelation_v2() # NENAME CELLCOUNT RELATIONID EXTENODEBID XCELLCOUNT/NEWXCELLCOUNT
{
YNENAME=$1
YCELLCOUNT=$2
YRELATIONID=$3
YEXTENODEBID=$4
YXCELLCOUNT=$5
cat >> $MOSCRIPT << MOSCT
CREATE
(
  parent "ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=${YNENAME}-$YCELLCOUNT,EUtranFreqRelation=1"
   identity $YRELATIONID
    moType EUtranCellRelation
    exception none
      nrOfAttributes 1
        neighborCellRef Ref ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction=$YEXTENODEBID,ExternalEUtranCellFDD=$YXCELLCOUNT
 
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

TEMP=`expr $LTE \* $NUMOFRBS`
MINUS=`expr $NUMOFRBS - 1`
EXTENODEBIDSTART=`expr $TEMP - $MINUS`


# ERBSTOTALCOUNT keeps of count of the total number of ERBSs in network

ERBSTOTALCOUNT=$EXTENODEBIDSTART

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

 EXTENODEBID=$EXTENODEBIDSTART
 EXTENODEBIDSTOP=`expr $EXTENODEBID + 15`

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
   # delNullEUtranCellRelation $NENAME $CELLCOUNT $RELATIONID # function used
   #setEUtranCellRelation $NENAME $CELLCOUNT $RELATIONID $TARGETCELLCOUNT # function used
   createEUtranCellRelation $NENAME $CELLCOUNT $RELATIONID $TARGETCELLCOUNT # function used
 

   RELATIONID=`expr $RELATIONID + 1`
   fi

 TARGETCELLCOUNT=`expr $TARGETCELLCOUNT + 1`
 done

#
 # Create relations to External Cells
 #


 while [ "$EXTENODEBID" -le "$EXTENODEBIDSTOP" ]
 do


   #####################################
   # An=4n-3
   #####################################

   TEMP1=`expr 4 \* $EXTENODEBID`
   XCELLSTART=`expr $TEMP1 - 3`
   XCELLCOUNT=$XCELLSTART
   XCELLSTOP=`expr $XCELLSTART + 3`

   if [ "$EXTENODEBID" -ne "$ERBSTOTALCOUNT" ]
 then
 #echo "creating relations to External Cells under ExternalNodeBFunction="$EXTENODEBID


   while [ "$XCELLCOUNT" -le "$XCELLSTOP" ]
   do
    if [ "$CELLCOUNT" -le 2 ]
    then
     XCELLSTOP=`expr $XCELLSTART + 1`
     #echo "creating relation to ExternalNodeBFunction="$EXTENODEBID"-ExternalEUtranCell="$XCELLCOUNT
  
     # delNullEUtranCellRelation $NENAME $CELLCOUNT $RELATIONID # function used
     # setNullEUtranCellRelation $NENAME $RELATIONID # function used
     #setEUtranCellRelation_v2 $NENAME $CELLCOUNT $RELATIONID $EXTENODEBID $XCELLCOUNT 
      createEUtranCellRelation_v2 $NENAME $CELLCOUNT $RELATIONID $EXTENODEBID $XCELLCOUNT 
	
 

     RELATIONID=`expr $RELATIONID + 1`
     XCELLCOUNT=`expr $XCELLCOUNT + 1`
    else
     XCELLSTOP=`expr $XCELLSTART + 1`
     NEWXCELLCOUNT=`expr $XCELLCOUNT + 2`
     #echo "creating relation to ExternalNodeBFunction="$EXTENODEBID"-ExternalEUtranCell="$NEWXCELLCOUNT

     # delNullEUtranCellRelation $NENAME $CELLCOUNT $RELATIONID # function used 
     #setNullEUtranCellRelation $NENAME $RELATIONID # function used
     # setEUtranCellRelation_v2 $NENAME $CELLCOUNT $RELATIONID $EXTENODEBID $NEWXCELLCOUNT	
      createEUtranCellRelation_v2 $NENAME $CELLCOUNT $RELATIONID $EXTENODEBID $NEWXCELLCOUNT	
 


     RELATIONID=`expr $RELATIONID + 1`
     XCELLCOUNT=`expr $XCELLCOUNT + 1`
    fi

   done

 fi

 EXTENODEBID=`expr $EXTENODEBID + 1`
 done



 CELLCOUNT=`expr $CELLCOUNT + 1`
 done

echo '.open '$SIMNAME >> $MMLSCRIPT
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
 
echo ""
echo "done!!! thanks for your patient..."
echo ""
