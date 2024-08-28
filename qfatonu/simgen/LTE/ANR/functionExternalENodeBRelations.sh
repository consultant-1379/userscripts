#!/bin/sh

# Created by  : Fatih ONUR
# Created in  : 06.11.09
##
### VERSION HISTORY
# Ver1        : Created for LTE O 10.0 TERE
# Purpose     : Create The Mos on the EnodeB that are required when a relation has to be created to another EnodeB
# Description : Requirement of script is below
#    We could then simulate the scenario where ERBS1 now recognises ERBS17 and creates the Mos towards it and ERBS17 recognises ERBS1 and creates the Mos towards it.
#    You need to create an ExternalEnodeBFunction MO which represents the NodeB that the relation will eb created to on each Node.  (2 Mos in total)
#    You need to create 4  ExternalEUtranCell MO which represents the cells in the ENodeB that the relations will be created to on each Node.  (8 Mos in total)
#    You will need to create a relation from each cell on each node to the 4 other cells in the other EnodeB. (32 Mos in total)
#    E.g
#     Node 1 cell 1 will have 4 relations to Node 17 cell 1,2,3 and 4.      
#     Node 1 cell 2 wil have 4 relations to Node 17 cell 1,2,3 and 4.
#     Node 1 cell 3 wil have 4 relations to Node 17 cell 1,2,3 and 4.
#     Node 1 cell 4 wil have 4relations to Node 17 cell 1,2,3 and 4.
#     Node 17 cell 1 wil have 4relations to Node 1 cell 1,2,3 and 4.
#     Node 17 cell 2 wil have 4relations to Node 1 cell 1,2,3 and 4.
#     Node 17 cell 3 wil have 4relations to Node 1 cell 1,2,3 and 4.
#     Node 17 cell 4 wil have 4 relations to Node 1 cell 1,2,3 and 4.
#
#     Total of 42 Mos/
# Date        : 06 Nov 2009
# Who         : Fatih ONUR

if [ "$#" -ne 5  ]
then
cat<<HELP

####################
# HELP
####################

Usage          : $0 <LTE SIM NO> <YES|NO> <ERBSID_START> <ERBSID_END> <EX_ERBSID> 
 
Example        : $0 24 NO 1 1 17

<LTE SIM NO>   : for LTEA70-ST-LTE24.zip is 24
<YES|NO>       : YES parameter to delete created ExternalNodeBFunction and Relations instaed of creating
                 NO parameter creates ExternalNodeBFunction and Relations
<RBSID_START>  : First ERBSID to be connect with ExternalNodeBFunction
<ERBSID_END>   : Last ERBSID to be connect with ExternalNodeBFunction
<EX_ERBSID>    : External ERBSID to be connected with ERBSID


Config: Configurable parameters within script under 'Assign variables' title are followings...

DUAL - DUAL equals YES means Relation Needs To be created mutually
 
HELP

exit 1
fi

LTE=$1
DELETE=$2 # DELETE equals YES means to delete created ExternalNodeBFunction and Relations instaed of creating

# ERBSID to be connect with ExternalNodeBFunction
ERBSID_START=$3
ERBSID_END=$4

# External ERBSID to be connected with ERBSID
EX_ERBSID=$5

################################
# Assign variables
################################
NUMOFRBS=160
CELLNUM=4
PWD=`pwd`



# DUAL equals YES means Relation Needs To be created mutually 
DUAL=YES



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


getNENAME() # ERBSNO  
{

# LTE=$1
ERBSCOUNT=$1
 
if [ "$LTE" -le "9" ]
then
 LTENAME="LTE0"$LTE"ERBS00"
else
 LTENAME="LTE"$LTE"ERBS00"
fi
 
 if [ "$ERBSCOUNT" -le 9 ]
 then
    NENAME=${LTENAME}"00"$ERBSCOUNT
	echo $NENAME
 else
   if [ "$ERBSCOUNT" -le 99 ]
   then
     NENAME=${LTENAME}"0"$ERBSCOUNT
	 echo $NENAME
   else
     NENAME=${LTENAME}$ERBSCOUNT
	 echo $NENAME
   fi
 fi
}


runKertayle() # ERBSNO
{
ERBSCOUNT=$1

NENAME=`getNENAME $ERBSCOUNT`

LTESIM=`getSimName $LTE`
SIMNAME=`ls /netsim/netsimdir | grep ${LTESIM} | grep -v zip`

echo '.open '$SIMNAME >> $MMLSCRIPT
echo '.select '$NENAME >> $MMLSCRIPT
echo '.start ' >> $MMLSCRIPT
echo 'useattributecharacteristics:switch="off";' >> $MMLSCRIPT
echo 'kertayle:file="'$PWD'/'$MOSCRIPT'";' >> $MMLSCRIPT

 /netsim/inst/netsim_shell < $MMLSCRIPT

rm $PWD/$MOSCRIPT
rm $PWD/$MMLSCRIPT

}



#
## echo "creating ExternalENodeBFunction for EXTENODEBID
#
createExternalENodeBFunction() # EXTENODEBID 
{
  ERBSCOUNT=$1
  EXTENODEBID=$2
  echo 'CREATE' >> $MOSCRIPT
  echo '(' >> $MOSCRIPT
  echo '  parent "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1"' >> $MOSCRIPT
  echo '   identity '$EXTENODEBID >> $MOSCRIPT
  echo '   moType ExternalENodeBFunction' >> $MOSCRIPT
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
  ##################################### 
  
  TEMP1=`expr 4 \* $EXTENODEBID`
  CELLSTART=`expr $TEMP1 - 3`
  CELLCOUNT=$CELLSTART
  CELLSTOP=`expr $CELLSTART + 3`
  
  while [ "$CELLCOUNT" -le "$CELLSTOP" ]
  do
   echo 'CREATE' >> $MOSCRIPT
   echo '(' >> $MOSCRIPT
   echo '  parent "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction='$EXTENODEBID'"' >> $MOSCRIPT
   echo '   identity '$CELLCOUNT >> $MOSCRIPT
   echo '   moType ExternalEUtranCellFDD' >> $MOSCRIPT
   echo '   exception none' >> $MOSCRIPT
   echo '   nrOfAttributes 2' >> $MOSCRIPT
   echo '    localCellId Integer '$CELLCOUNT >> $MOSCRIPT
   echo '    tac Integer 1' >> $MOSCRIPT
   echo '    bPlmnList Array Struct 1' >> $MOSCRIPT
   echo '      nrOfElements 3' >> $MOSCRIPT
   echo '       mcc Integer 353' >> $MOSCRIPT
   echo '       mnc Integer 57' >> $MOSCRIPT
   echo '       mncLength Integer 2' >> $MOSCRIPT
   echo ')' >> $MOSCRIPT

   CELLCOUNT=`expr $CELLCOUNT + 1`
  done
  
  # Executing Kertayle Script 
  echo "creating ExternalENodeBFunction=ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction="$EXTENODEBID" and ExternalEUtranCellFDD cells"
  runKertayle $ERBSCOUNT
}

deleteExternalENodeBFunction() # EXTENODEBID
{
  ERBSCOUNT=$1
  EXTENODEBID=$2
  echo 'DELETE' >> $MOSCRIPT
  echo '(' >> $MOSCRIPT
  echo "mo ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction="$EXTENODEBID >> $MOSCRIPT
  echo ')' >> $MOSCRIPT


  #####################################
  #
  # An=4n-3
  #
  #####################################

  TEMP1=`expr 4 \* $EXTENODEBID`
  CELLSTART=`expr $TEMP1 - 3`
  CELLCOUNT=$CELLSTART
  CELLSTOP=`expr $CELLSTART + 3`

 # while [ "$CELLCOUNT" -le "$CELLSTOP" ]
 # do
 #  echo 'DELETE' >> $MOSCRIPT
 #  echo '(' >> $MOSCRIPT
 #  echo "  mo ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction="$EXTENODEBID",ExternalEUtranCellFDD="$CELLCOUNT >> $MOSCRIPT
 #  echo ')' >> $MOSCRIPT

 #  CELLCOUNT=`expr $CELLCOUNT + 1`
 # done

  # Executing Kertayle Script
  echo "deleting ExternalENodeBFunction=ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction="$EXTENODEBID" and ExternalEUtranCellFDD cells"
  runKertayle $ERBSCOUNT
}


#
## echo "creating relations from NENAME to ExternalCells under ExternalNodeBFunction="$EXTENODEBID"
#
createEUtranCellRelation() # ERBSNO, EXTENODEBID 
{
  ERBSCOUNT=$1
  NENAME=`getNENAME $ERBSCOUNT`
  EXTENODEBID=$2

  CELLCOUNT=1
  CELLSTOP=4

  while [ "$CELLCOUNT" -le "$CELLSTOP" ]
  do

    #####################################
    # An=4n-3
    #####################################
    TEMP1=`expr 4 \* $EXTENODEBID`
    XCELLSTART=`expr $TEMP1 - 3`
    XCELLCOUNT=$XCELLSTART
    XCELLSTOP=`expr $XCELLSTART + 3`

    TEMP2=`expr 4 \* $EXTENODEBID`
    RELATIONIDSTART=`expr $TEMP2 - 3`
    RELATIONID=`expr 100 + $RELATIONIDSTART` # 
   
    
    while [ "$XCELLCOUNT" -le "$XCELLSTOP" ]
    do
    		
      echo "CREATE" >> $MOSCRIPT
      echo "(" >> $MOSCRIPT
      echo "parent ManagedElement=1,ENodeBFunction=1,EUtranCellFDD="${NENAME}"-"$CELLCOUNT",EUtranFreqRelation=1" >> $MOSCRIPT
      echo "identity "$RELATIONID >> $MOSCRIPT
      echo " moType EUtranCellRelation" >> $MOSCRIPT
      echo "  exception none" >> $MOSCRIPT
      echo "  nrOfAttributes 2" >> $MOSCRIPT
      # echo "     eutranCellFddRef Ref ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction="$EXTENODEBID",ExternalEUtranCellFDD="$XCELLCOUNT >>$MOSCRIPT
      echo "     neighborCellRef Ref ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction="$EXTENODEBID",ExternalEUtranCellFDD="$XCELLCOUNT >>$MOSCRIPT
      echo ")" >> $MOSCRIPT

      RELATIONID=`expr $RELATIONID + 1`  
      XCELLCOUNT=`expr $XCELLCOUNT + 1`
    
    done
    CELLCOUNT=`expr $CELLCOUNT + 1`
  done

  # Executing Kertayle Script 
  echo "creating UtranCellRelations under ManagedElement=1,ENodeBFunction=1,EUtranCellFDD="${NENAME}"-"$CELLCOUNT",EUtranFreqRelation=1"
  runKertayle $ERBSCOUNT
}


deleteEUtranCellRelation() # ERBSNO, EXTENODEBID
{
  ERBSCOUNT=$1
  NENAME=`getNENAME $ERBSCOUNT`
  EXTENODEBID=$2

  CELLCOUNT=1
  CELLSTOP=4

  while [ "$CELLCOUNT" -le "$CELLSTOP" ]
  do

    #####################################
    # An=4n-3
    #####################################
    TEMP1=`expr 4 \* $EXTENODEBID`
    XCELLSTART=`expr $TEMP1 - 3`
    XCELLCOUNT=$XCELLSTART
    XCELLSTOP=`expr $XCELLSTART + 3`

    TEMP2=`expr 4 \* $EXTENODEBID`
    RELATIONIDSTART=`expr $TEMP2 - 3`
    RELATIONID=`expr 100 + $RELATIONIDSTART` #


    while [ "$XCELLCOUNT" -le "$XCELLSTOP" ]
    do

      echo "DELETE" >> $MOSCRIPT
      echo "(" >> $MOSCRIPT
      echo "mo ManagedElement=1,ENodeBFunction=1,EUtranCellFDD="${NENAME}"-"$CELLCOUNT",EUtranFreqRelation=1,EUtranCellRelation="$RELATIONID >> $MOSCRIPT
      echo ")" >> $MOSCRIPT

      RELATIONID=`expr $RELATIONID + 1`
      XCELLCOUNT=`expr $XCELLCOUNT + 1`

    done
    CELLCOUNT=`expr $CELLCOUNT + 1`
  done

  # Executing Kertayle Script
  echo "deleting UtranCelRelations UtranCellRelations under ManagedElement=1,ENodeBFunction=1,EUtranCellFDD="${NENAME}"-"$CELLCOUNT",EUtranFreqRelation=1"
  runKertayle $ERBSCOUNT
}


################################
# Main program
################################

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

echo ""
echo "script running, please wait..."


#########################################
# 
# Make MO Script
#
#########################################

echo ""
echo "MAKING MO SCRIPT"
echo ""


ERBSID_COUNT=$ERBSID_START

while [ "$ERBSID_COUNT" -le "$ERBSID_END" ]
do

####################################################################
# Creating ExternalENodeBFunction AND Relations to External Cells
####################################################################


if [ "$DUAL" != "YES" ]
then
  echo "DUAL is NO"
  if [ "$DELETE" != "YES" ]
  then 
    echo "DELETE is NO"
    createExternalENodeBFunction $ERBSID_COUNT $EX_ERBSID # takes ERBSNO, ExternalERBSNO
    createEUtranCellRelation $ERBSID_COUNT $EX_ERBSID # takes (from) ERBSNO, (To) ExternalERBSNO arguments
  else 
    echo "DELETE is YES"
    deleteEUtranCellRelation $ERBSID_COUNT $EX_ERBSID  # takes (from) ERBSNO, (To) ExternalERBSNO arguments
    deleteExternalENodeBFunction $ERBSID_COUNT $EX_ERBSID  # takes ERBSNO, ExternalERBSNO
  fi
else
  echo "DUAL is YES"
  if [ "$DELETE" != "YES" ]
  then
    echo "DELETE is NO"
    createExternalENodeBFunction $ERBSID_COUNT $EX_ERBSID # takes ERBSNO, ExternalERBSNO
    createEUtranCellRelation $ERBSID_COUNT $EX_ERBSID # takes (from) ERBSNO, (To) ExternalERBSNO arguments
    createExternalENodeBFunction $EX_ERBSID $ERBSID_COUNT # takes ERBSNO, ExternalERBSNO
    createEUtranCellRelation $EX_ERBSID $ERBSID_COUNT # takes (from) ERBSNO, (To) ExternalERBSNO arguments
  else
    echo "DELETE is YES"
    deleteEUtranCellRelation $ERBSID_COUNT $EX_ERBSID  # takes (from) ERBSNO, (To) ExternalERBSNO arguments
    deleteExternalENodeBFunction $ERBSID_COUNT $EX_ERBSID  # takes ERBSNO, ExternalERBSNO
    deleteEUtranCellRelation $EX_ERBSID $ERBSID_COUNT # takes (from) ERBSNO, (To) ExternalERBSNO arguments
    deleteExternalENodeBFunction $EX_ERBSID $ERBSID_COUNT # takes ERBSNO, ExternalERBSNO
  fi
fi


ERBSID_COUNT=`expr $ERBSID_COUNT + 1`
done

echo ""
echo "done!!! thanks for your patient..."
echo ""
