#!/bin/bash


# alias command
shopt -s expand_aliases
alias cstest='/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s Seg_masterservice_CS -ns masterservice'

OUTPUTFILE1BASE="tmpUtranCellRelations"
LOGFILE=UtranCellRelations.log
RELATIONSDIR="relations"

PWD=`pwd`

if [ -f $PWD/$LOGFILE ]
then
  rm -r  $PWD/$LOGFILE
  echo "old "$PWD/$LOGFILE" removed"
fi

if [ ! -d $PWD/$RELATIONSDIR ]
then
  echo "Check the following dir exists:"$PWD/$RELATIONSDIR
  exit
fi



echo "$0 script started at `date`" | tee -a $LOGFILE

START=1
END=3
#END=106

SUM=0

COUNT=$START

while [ "$COUNT" -le $END ]
do

  if [ "$COUNT" -le 9 ]
  then
    RNCNAME="RNC0"$COUNT
    RNCCOUNT="0"$COUNT
 else
    RNCNAME="RNC"$COUNT
    RNCCOUNT=$COUNT
 fi

 OUTPUTFILE1=$OUTPUTFILE1BASE"_"$RNCNAME".txt"

 echo "*****************************************************"
 echo "* $RNCNAME utran relations are put into $OUTPUTFILE1"
 #echo "*****************************************************"

 RNCFUNCTION="SubNetwork=ONRM_RootMo_R,SubNetwork=$RNCNAME,MeContext=$RNCNAME,ManagedElement=1,RncFunction=1"
 #echo "RNCFUNCTION="$RNCFUNCTION

 (cstest lm $RNCFUNCTION -f '$type_name==UtranRelation' >> relations/$OUTPUTFILE1)&
 #SUM=`expr $SUM + $NUMOFEUFREQREL`

  COUNT=`expr $COUNT + 1`  
done


 echo "##################################################"
 echo "$0 script comleted at `date`" | tee -a $LOGFILE
 echo ""
 echo "See the following file for all utran realtions:$LOGFILE"
 
