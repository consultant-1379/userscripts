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

if [ "$#" -ne 6  ]
then
cat<<HELP

####################
# HELP
####################

Usage          : $0 <LTE SIM NO> <CRE|DEL|MOD> <ERBSID_START> <ERBSID_END> <EX_ERBSID> <CELL_END>
 
Example        : $0 1 CRE 1 1 17 4

<LTE SIM NO>   : for LTEA70-ST-LTE01.zip is 1
<CRE|DEL|MOD>  : DEL parameter to delete created ExternalNodeBFunction and Relations instaed of creating
                 CRE parameter creates ExternalNodeBFunction and Relations
                 MOD parameter modifies ExternalNodeBFunction and Relations
<RBSID_START>  : First ERBSID to be connect with ExternalNodeBFunction
<ERBSID_END>   : Last ERBSID to be connect with ExternalNodeBFunction
<EX_ERBSID>    : External ERBSID to be connected with ERBSID
<CELL_END>     : Can take value between 1 to 4, and define for up to which cell relation should be created. 
                 example:
		 if CELL_END=1 then Node A cell 1 will have 4 relations to Node xB cell 1,2,3 and 4
                                         Node xB cell 1 will have 4 relations to Node A cell 1,2,3 and 4


Config: Configurable parameters within script under 'Assign variables' title are followings...

DUAL - DUAL equals YES means Relation Needs To be created mutually
 
HELP

exit 1
fi

LTE=$1
DO=$2 # DO parameter gets 3 values CRE|DEL|MOD. CRE means CREATE mod is activated, DEL means DELETE mod is activated, MOD means MODIFY mod is activated

# ERBSID to be connect with ExternalNodeBFunction
ERBSID_START=$3
ERBSID_END=$4

# External ERBSID to be connected with ERBSID
EX_ERBSID=$5

# Define for up to which cell relation should be created
CELLEND=$6

################################
# Assign variables
################################
NUMOFRBS=160
CELLNUM=4
PWD=`pwd`

# DUAL equals YES means Relation Needs To be created mutually 
DUAL=NO



################################
# Functions
################################

#
## function to ensure that not to create existed ExternalNodeBfunction for 16 range of ERBS
#
checkExternalNodeBFunctionIdRange() # ERBSID_END EX_ERBSID
{

ERBSID_END=$1
EX_ERBSID=$2

DIV=`expr $ERBSID_END / 16`
MOD=`expr $ERBSID_END % 16`

#
# EX_ERBSIDSTART: =17 for ERBSID1-16: =33 for ERBSID16-32........
#

if [ "$MOD" -eq 0 ]; then
 EX_ERBSIDSTART=`expr \( $DIV \* 16 \) + 1`
else
 EX_ERBSIDSTART=`expr \( \( $DIV + 1 \) \* 16 \) + 1`
fi

#echo "EX_ERBSIDSTART="$EX_ERBSIDSTART

if [ "$EX_ERBSID" -lt "$EX_ERBSIDSTART" ]
then
  echo ""
  echo "EX_ERBSID must be bigger than "$EX_ERBSIDSTART" to exit 16 ERBS Nodes Range"
  echo "Please check your value assigned for EX_ERBSID value and rerun sctipt again..."
  exit 1
fi
}


#
## to get system date
#
getDATE() #
{
echo "`date`"
}

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

echo "PWD :"$PWD

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
createExternalENodeBFunction() # ERBSCOUNT EXTENODEBID 
{
  ERBSCOUNT=$1
  EXTENODEBID=$2
  ANRCREATED=`getDATE`
  echo 'CREATE' >> $MOSCRIPT
  echo '(' >> $MOSCRIPT
  echo '  parent "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1"' >> $MOSCRIPT
  echo '   identity '$EXTENODEBID >> $MOSCRIPT
  echo '   moType ExternalENodeBFunction' >> $MOSCRIPT
  echo '   exception none' >> $MOSCRIPT
  echo '   nrOfAttributes 2' >> $MOSCRIPT
  echo '    eNBId Integer '$EXTENODEBID >> $MOSCRIPT
  echo '    eNodeBPlmnId Struct' >> $MOSCRIPT
  echo '      nrOfElements 4' >> $MOSCRIPT
  echo '       mcc Integer 353' >> $MOSCRIPT
  echo '       mnc Integer 57' >> $MOSCRIPT
  echo '       mncLength Integer 2' >> $MOSCRIPT
  echo " anrCreated Boolean true" >> $MOSCRIPT
  echo " timeOfAnrCreation String  '`'getDATE'`'" >> $MOSCRIPT
  echo ')' >> $MOSCRIPT


  CELLSTART=1
  CELLCOUNT=$CELLSTART
  CELLSTOP=$CELLNUM
 
  while [ "$CELLCOUNT" -le "$CELLSTOP" ]
  do
   echo 'CREATE' >> $MOSCRIPT
   echo '(' >> $MOSCRIPT
   echo '  parent "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction='$EXTENODEBID'"' >> $MOSCRIPT
   echo '   identity '$CELLCOUNT >> $MOSCRIPT
   echo '   moType ExternalEUtranCellFDD' >> $MOSCRIPT
   echo '   exception none' >> $MOSCRIPT
   echo '   nrOfAttributes 4' >> $MOSCRIPT
   echo '    localCellId Integer '$CELLCOUNT >> $MOSCRIPT
   echo '    tac Integer 1' >> $MOSCRIPT
   echo '    bPlmnList Array Struct 1' >> $MOSCRIPT
   echo '      nrOfElements 3' >> $MOSCRIPT
   echo '       mcc Integer 353' >> $MOSCRIPT
   echo '       mnc Integer 57' >> $MOSCRIPT
   echo '       mncLength Integer 2' >> $MOSCRIPT
   echo '    eutranFrequencyRef Ref "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,EUtranFrequency=1"' >> $MOSCRIPT
   echo "    anrCreated Boolean true" >> $MOSCRIPT
   echo " timeOfAnrCreation String  '`'getDATE'`'" >> $MOSCRIPT
   echo ')' >> $MOSCRIPT

   CELLCOUNT=`expr $CELLCOUNT + 1`
  done
  
  # Executing Kertayle Script 
  echo "creating ExternalENodeBFunction=ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction="$EXTENODEBID" and ExternalEUtranCellFDD cells"
  runKertayle $ERBSCOUNT
}

#
## echo "modifying ExternalENodeBFunction for EXTENODEBID
#
modifyExternalENodeBFunction() # ERBSCOUNT EXTENODEBID
{
  ERBSCOUNT=$1
  EXTENODEBID=$2
  echo 'SET' >> $MOSCRIPT
  echo '(' >> $MOSCRIPT
  echo '  mo "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction='$EXTENODEBID'"' >> $MOSCRIPT
  echo '   nrOfAttributes 3' >> $MOSCRIPT
  echo '    eNBId Integer '$EXTENODEBID >> $MOSCRIPT
  echo '    eNodeBPlmnId Struct' >> $MOSCRIPT
  echo '      nrOfElements 4' >> $MOSCRIPT
  echo '       mcc Integer 353' >> $MOSCRIPT
  echo '       mnc Integer 57' >> $MOSCRIPT
  echo '       mncLength Integer 2' >> $MOSCRIPT
  echo " anrCreated Boolean true" >> $MOSCRIPT
  echo " timeOfAnrModification String  '`'getDATE'`'" >> $MOSCRIPT
  echo ')' >> $MOSCRIPT


  CELLSTART=1
  CELLCOUNT=$CELLSTART
  CELLSTOP=$CELLNUM

  while [ "$CELLCOUNT" -le "$CELLSTOP" ]
  do
   echo 'SET' >> $MOSCRIPT
   echo '(' >> $MOSCRIPT
   echo '  mo "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction='$EXTENODEBID',ExternalEUtranCellFDD='$CELLCOUNT'"' >> $MOSCRIPT
   echo '   nrOfAttributes 4' >> $MOSCRIPT
   echo '    localCellId Integer '$CELLCOUNT >> $MOSCRIPT
   echo '    tac Integer 1' >> $MOSCRIPT
   echo '    bPlmnList Array Struct 1' >> $MOSCRIPT
   echo '      nrOfElements 3' >> $MOSCRIPT
   echo '       mcc Integer 353' >> $MOSCRIPT
   echo '       mnc Integer 57' >> $MOSCRIPT
   echo '       mncLength Integer 2' >> $MOSCRIPT
   echo '    eutranFrequencyRef Ref "ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,EUtranFrequency=1"' >> $MOSCRIPT
   echo "    anrCreated Boolean true" >> $MOSCRIPT
   echo " timeOfAnrModification String  '`'getDATE'`'" >> $MOSCRIPT
   echo ')' >> $MOSCRIPT

   CELLCOUNT=`expr $CELLCOUNT + 1`
  done

  # Executing Kertayle Script
  echo "modifying ExternalENodeBFunction=ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction="$EXTENODEBID" and ExternalEUtranCellFDD cells"
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


  CELLSTART=1
  CELLCOUNT=$CELLSTART
  CELLSTOP=$CELLNUM



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
  CELLSTOP=$CELLEND

  while [ "$CELLCOUNT" -le "$CELLSTOP" ]
  do


   XCELLSTART=1
   XCELLCOUNT=$XCELLSTART
   XCELLSTOP=$CELLNUM

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
      echo "     neighborCellRef Ref ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction="$EXTENODEBID",ExternalEUtranCellFDD="$XCELLCOUNT >>$MOSCRIPT
      echo "     anrCreated Boolean true" >> $MOSCRIPT
      echo " timeOfAnrCreation String  '`'getDATE'`'" >> $MOSCRIPT
      echo ")" >> $MOSCRIPT

      RELATIONID=`expr $RELATIONID + 1`  
      XCELLCOUNT=`expr $XCELLCOUNT + 1`
    
    done
    CELLCOUNT=`expr $CELLCOUNT + 1`
  done

  # Executing Kertayle Script 
  echo "creating eUtranCellRelations under ManagedElement=1,ENodeBFunction=1,EUtranCellFDD="${NENAME}"-"$CELLCOUNT",EUtranFreqRelation=1"
  runKertayle $ERBSCOUNT
}

#
## echo "modifying relations from NENAME to ExternalCells under ExternalNodeBFunction="$EXTENODEBID"
#
modifyEUtranCellRelation() # ERBSNO, EXTENODEBID
{
  ERBSCOUNT=$1
  NENAME=`getNENAME $ERBSCOUNT`
  EXTENODEBID=$2

  CELLCOUNT=1
  CELLSTOP=$CELLEND

  while [ "$CELLCOUNT" -le "$CELLSTOP" ]
  do


   XCELLSTART=1
   XCELLCOUNT=$XCELLSTART
   XCELLSTOP=$CELLNUM

    TEMP2=`expr 4 \* $EXTENODEBID`
    RELATIONIDSTART=`expr $TEMP2 - 3`
    RELATIONID=`expr 100 + $RELATIONIDSTART` #


    while [ "$XCELLCOUNT" -le "$XCELLSTOP" ]
    do

      echo "SET" >> $MOSCRIPT
      echo "(" >> $MOSCRIPT
      echo "mo ManagedElement=1,ENodeBFunction=1,EUtranCellFDD="${NENAME}"-"$CELLCOUNT",EUtranFreqRelation=1,EUtranCellRelation="$RELATIONID >> $MOSCRIPT
      echo "  nrOfAttributes 2" >> $MOSCRIPT
      echo "     neighborCellRef Ref ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction="$EXTENODEBID",ExternalEUtranCellFDD="$XCELLCOUNT >>$MOSCRIPT
      echo "     anrCreated Boolean true" >> $MOSCRIPT
      echo " timeOfAnrModification String  '`'getDATE'`'" >> $MOSCRIPT      
      echo ")" >> $MOSCRIPT

      RELATIONID=`expr $RELATIONID + 1`
      XCELLCOUNT=`expr $XCELLCOUNT + 1`

    done
    CELLCOUNT=`expr $CELLCOUNT + 1`
  done

  # Executing Kertayle Script
  echo "modifying eUtranCellRelations under ManagedElement=1,ENodeBFunction=1,EUtranCellFDD="${NENAME}"-"$CELLCOUNT",EUtranFreqRelation=1"
  runKertayle $ERBSCOUNT
}


deleteEUtranCellRelation() # ERBSNO, EXTENODEBID
{
  ERBSCOUNT=$1
  NENAME=`getNENAME $ERBSCOUNT`
  EXTENODEBID=$2

  CELLCOUNT=1
  CELLSTOP=$CELLEND

  while [ "$CELLCOUNT" -le "$CELLSTOP" ]
  do

   XCELLSTART=1
   XCELLCOUNT=$XCELLSTART
   XCELLSTOP=$CELLNUM

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


checkExternalNodeBFunctionIdRange $ERBSID_END $EX_ERBSID


ERBSID_COUNT=$ERBSID_START

while [ "$ERBSID_COUNT" -le "$ERBSID_END" ]
do

####################################################################
# Creating ExternalENodeBFunction AND Relations to External Cells
####################################################################

if [ "$DUAL" != "YES" ]
then
  echo "DUAL is NO"
  if [ "$DO" = "CRE" ]
  then 
    echo "CREATE MOD IS ACTIVATED"
    createExternalENodeBFunction $ERBSID_COUNT $EX_ERBSID # takes ERBSNO, ExternalERBSNO
    createEUtranCellRelation $ERBSID_COUNT $EX_ERBSID # takes (from) ERBSNO, (To) ExternalERBSNO arguments
  elif [ "$DO" = "MOD" ] ; then
    echo "MODIFY MOD IS ACTIVATED"
    modifyExternalENodeBFunction $ERBSID_COUNT $EX_ERBSID # takes ERBSNO, ExternalERBSNO
    modifyEUtranCellRelation $ERBSID_COUNT $EX_ERBSID # takes (from) ERBSNO, (To) ExternalERBSNO arguments
  elif [ "$DO" = "DEL" ] ; then 
    echo "DELETE MOD IS ACTIVATED"
    deleteEUtranCellRelation $ERBSID_COUNT $EX_ERBSID  # takes (from) ERBSNO, (To) ExternalERBSNO arguments
    deleteExternalENodeBFunction $ERBSID_COUNT $EX_ERBSID  # takes ERBSNO, ExternalERBSNO
  else 
    echo ""
    echo "ERROR DETECTED!!!"
    echo "PLease check your parameters and rerun script again"
    echo ""
  fi
else
  echo "DUAL is YES"
  if [ "$DO" = "CRE" ] 
  then
    echo "CREATE MOD IS ACTIVATED" 
    createExternalENodeBFunction $ERBSID_COUNT $EX_ERBSID # takes ERBSNO, ExternalERBSNO
    createEUtranCellRelation $ERBSID_COUNT $EX_ERBSID # takes (from) ERBSNO, (To) ExternalERBSNO arguments
    createExternalENodeBFunction $EX_ERBSID $ERBSID_COUNT # takes ERBSNO, ExternalERBSNO
    createEUtranCellRelation $EX_ERBSID $ERBSID_COUNT # takes (from) ERBSNO, (To) ExternalERBSNO arguments
  elif [ "$DO" = "MOD" ] ; then
    echo "MODIFY MOD IS ACTIVATED"
    modifyExternalENodeBFunction $ERBSID_COUNT $EX_ERBSID # takes ERBSNO, ExternalERBSNO
    modifyEUtranCellRelation $ERBSID_COUNT $EX_ERBSID # takes (from) ERBSNO, (To) ExternalERBSNO arguments
    modifyExternalENodeBFunction $EX_ERBSID $ERBSID_COUNT # takes ERBSNO, ExternalERBSNO
    modifyEUtranCellRelation $EX_ERBSID $ERBSID_COUNT # takes (from) ERBSNO, (To) ExternalERBSNO arguments
  elif [ "$DO" = "DEL" ] ; then
    echo "DELETE MOD IS ACTIVATED"
    deleteEUtranCellRelation $ERBSID_COUNT $EX_ERBSID  # takes (from) ERBSNO, (To) ExternalERBSNO arguments
    deleteExternalENodeBFunction $ERBSID_COUNT $EX_ERBSID  # takes ERBSNO, ExternalERBSNO
    deleteEUtranCellRelation $EX_ERBSID $ERBSID_COUNT # takes (from) ERBSNO, (To) ExternalERBSNO arguments
    deleteExternalENodeBFunction $EX_ERBSID $ERBSID_COUNT # takes ERBSNO, ExternalERBSNO
  else
    echo ""
    echo "ERROR DETECTED!!!"
    echo "PLease check your parameters and rerun script again"
    echo ""
  fi
fi


ERBSID_COUNT=`expr $ERBSID_COUNT + 1`
done

echo ""
echo "done!!! thanks for your patient..."
echo ""
