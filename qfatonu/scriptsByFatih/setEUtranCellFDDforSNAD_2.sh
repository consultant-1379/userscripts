#!/bin/sh

# Created by  : Fatih ONUR
# Created in  : 23.07.09
##
### VERSION HISTORY
# Ver1        : Created for LTE O 10.0 TERE, SNAD inconsistency  
# Purpose     : To Change tac attribite for 1500cells in EUtranCellFDD
# Description : 
# Date        : 23 July 2009
# Who         : Fatih ONUR
#
# Verr2       : Created for LTE O 10.0 TERE, SNAD inconsistency
# Purpose     : To Change tac attribite for all cells in EUtranCellFDD
# Description :
# Date        : 10 Sep 2009
# Who         : Fatih ONUR

if [ "$#" -ne 1  ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 <start>

Example: $0 start

DESCRIP: To Change tac attribite for all cells in EUtranCellFDD
         Below variables needs to be set up.

 NETSIMVERSION=inst (default)
 UNTILRBS=160 (default) # it assumes that simulation has 160 nodes

HELP

exit 1
fi


if [ $# -eq 1 ]; then
#LIST=`ls /netsim/netsimdir/L* | grep zip`
LIST=`ls /netsim/netsimdir/L* | grep zip | cut -c19-`
# echo "list works"
fi


# used for to exit after 3 sims
SIMCOUNT=1

for ZIP in $LIST
do
 if [ "$SIMCOUNT" -ge 5 ]
  then
   exit
 fi 

 SIM=`echo $ZIP | cut -c 1-$(echo "${#ZIP} - 4" | bc)`
 LTE=`echo $SIM |  awk '{print substr($0, length($0)-1)}' | awk '{print $1 + 0}'`

 echo "################"
 echo "LTE no: $LTE"
 echo "################"


 if [ -d "$HOME/netsimdir/$SIM" ]; then
     # *** Note ***
     # Assuming simulations are stored in default dir $HOME/netsimdir
     echo "Used uncompressed simulation"
     echo "Simulation $HOME/netsimdir/$SIM"
     echo "already exists. "
     echo ""
 fi



 SIMNAME=$SIM


NETSIMVERSION=inst
NETSIMDIR=$HOME


if [ "$LTE" -le "9" ]
then
 LTENAME="LTE0"$LTE"ERBS00"
else
 LTENAME="LTE"$LTE"ERBS00"
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



########################################
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


###################################################
#
# Need to calculate the first cellid in the sim
#
# LTE01 has Cells 1-640
# LTE02 has Cells 641-1280   ....etc
#
# Arithmetic Progression An = A1 + d(n-1)
#
# An = 1 + 640(n-1)
# An = 640(n) -639
#
###################################################

# added instead of env file
NUMOFRBS=160
CELLNUM=4

###################################################
#
# UNTILRBS=125; SIMCOUNT -ge 4 means 3 sims
#
# 1500 cells means 125 Nodes x 3 sims = 375 Nodes
# 375 nodes means 375 Nodes x 4 cells = 1500 cells
#
#####################################################

UNTILRBS=160


ERBSCOUNT=1
TOTALCELLS=`expr $CELLNUM \* $NUMOFRBS`
MINUS=`expr $TOTALCELLS - 1`
TEMP=`expr $TOTALCELLS \* $LTE`
STARTCELLID=`expr $TEMP - $MINUS`

CID=$STARTCELLID



while [ "$ERBSCOUNT" -le "$UNTILRBS"  ]
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

###################################################
#
# Need to calculate the first cellid in the sim
#
# LTE01 has Cells 1-640
# LTE02 has Cells 641-1280   ....etc
#
# Arithmetic Progression An = A1 + d(n-1)
# 
# An = 1 + 640(n-1)
# An = 640(n) -639
#
###################################################


CELLCOUNT=1
STOP=$CELLNUM

while [ "$CELLCOUNT" -le "$STOP" ]
do

TACID=3
echo "CID="$CID "TACID="$TACID
echo ""

#echo 'setmoattribute:mo="ManagedElement=1,ENodeBFunction=1,EUtranCellFDD='${NENAME}-$CELLCOUNT'",attributes="tac (Iteger)='$TACID'";' >> $MMLSCRIPT

cat >> $MOSCRIPT << MOSCT
SET
(
   mo "ManagedElement=1,ENodeBFunction=1,EUtranCellFDD= ${NENAME}-$CELLCOUNT"
    identity 1
    exception none   
    nrOfAttributes 1
       tac Integer $TACID
)
MOSCT

CID=`expr $CID + 1`
CELLCOUNT=`expr $CELLCOUNT + 1`
done


 echo '.select '$NENAME >> $MMLSCRIPT 
 echo '.start ' >> $MMLSCRIPT
 echo 'useattributecharacteristics:switch="off";' >> $MMLSCRIPT
 echo 'kertayle:file="'$PWD'/'$MOSCRIPT'";' >> $MMLSCRIPT
 $NETSIMDIR/$NETSIMVERSION/netsim_shell < $MMLSCRIPT
 ERBSCOUNT=`expr $ERBSCOUNT + 1`
 rm $PWD/$MOSCRIPT
 rm $PWD/$MMLSCRIPT
done

SIMCOUNT=`expr $SIMCOUNT + 1`
done
