#!/bin/bash


getRncName()
{
  COUNT=$1

  if [ "$COUNT" -le 9 ]
  then
    RNCNAME="RNC0"$COUNT
  else
    RNCNAME="RNC"$COUNT
  fi

echo $RNCNAME
}

# alias command
shopt -s expand_aliases
alias cstest='/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s Seg_masterservice_CS -ns masterservice'


NUM_OF_INTER_RELATION_PER_CELL=0
TOTAL_NUM_OF_INTRA_RELATION_PER_RNC=0
TOTAL_NUM_OF_INTER_RELATION_PER_RNC=0
TOTAL_NUM_OF_EXTERNAL_RELATION_PER_RNC=0

TOTAL_NUM_OF_INTRA_RELATION_FOR_NETWORK=0
TOTAL_NUM_OF_INTER_RELATION_FOR_NETWORK=0
TOTAL_NUM_OF_EXTERNAL_RELATION_FOR_NETWORK=0



START=1
END=1
#END=106

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


  echo "####################################################"
  echo " $RNCNAME utran relations"
  echo "####################################################"

  UTRANCELLS=`grep $RNCNAME UtranCells.txt`
  #echo "UTRANCELLS=" $UTRANCELLS

  COUNT2=1

  for UTRANCELL in $UTRANCELLS
  do
     echo "******************************************"
     echo "*UTRANCELL=$UTRANCELL "
     echo "******************************************"

     #
     # Another solution
     #
     #UTRAN_RELATIONS_PER_CELL=`cstest lm $UTRANCELL -f '$type_name==UtranRelation' | sed -n 32,60p | wc -l`
     #echo "UTRAN_RELATIONS_PER_CELL="$UTRAN_RELATIONS_PER_CELL
     #exit

     UTRAN_RELATIONS_PER_CELL=`grep $UTRANCELL UtranRelations.txt`
     #
     #echo "UTRAN_RELATIONS_PER_CELL="$UTRAN_RELATIONS_PER_CELL
     #exit

     NUM_OF_INTRA_RELATION_PER_CELL=0
     NUM_OF_INTER_RELATION_PER_CELL=0
     NUM_OF_EXTERNAL_RELATION_PER_CELL=0
     for RELATION in $UTRAN_RELATIONS_PER_CELL
     do
        #echo "RELATION="$RELATION
        #exit
        #
        RELATIONID=`echo $RELATION | awk -F"=" '{print $8}'`
        #
        #echo "RELATIONID="$RELATIONID
        #exit


        if [ $RELATIONID -le 31 ]
        then
           NUM_OF_INTRA_RELATION_PER_CELL=`expr $NUM_OF_INTRA_RELATION_PER_CELL + 1`
        elif [ $RELATIONID -ge 31 ] && [ $RELATIONID -le 60 ]
        then
           NUM_OF_INTER_RELATION_PER_CELL=`expr $NUM_OF_INTER_RELATION_PER_CELL + 1`
        elif [ $RELATIONID -ge 61 ] 
        then
            NUM_OF_EXTERNAL_RELATION_PER_CELL=`expr $NUM_OF_EXTERNAL_RELATION_PER_CELL + 1`
        fi

     done

     echo "NUM_OF_INTRA_RELATION_PER_CELL="$NUM_OF_INTRA_RELATION_PER_CELL
     echo "NUM_OF_INTER_RELATION_PER_CELL="$NUM_OF_INTER_RELATION_PER_CELL
     echo "NUM_OF_EXTERNAL_RELATION_PER_CELL="$NUM_OF_EXTERNAL_RELATION_PER_CELL 
     #
     #exit

     TOTAL_NUM_OF_INTRA_RELATION_PER_RNC=`expr $TOTAL_NUM_OF_INTRA_RELATION_PER_RNC + $NUM_OF_INTRA_RELATION_PER_CELL`
     TOTAL_NUM_OF_INTER_RELATION_PER_RNC=`expr $TOTAL_NUM_OF_INTER_RELATION_PER_RNC + $NUM_OF_INTER_RELATION_PER_CELL`
     TOTAL_NUM_OF_EXTERNAL_RELATION_PER_RNC=`expr $TOTAL_NUM_OF_EXTERNAL_RELATION_PER_RNC + $NUM_OF_EXTERNAL_RELATION_PER_CELL`
   
     #
     ## TESTING ONLY 
     #
     if [ $COUNT2 -eq 3 ]
     then
       break 
     fi

     COUNT2=`expr $COUNT2 + 1` 
  done
  echo ""
  echo "-----------------------------------------"
  echo "TOTAL_NUM_OF_INTRA_RELATION_PER_RNC($RNCNAME)=$TOTAL_NUM_OF_INTRA_RELATION_PER_RNC"
  echo "TOTAL_NUM_OF_INTER_RELATION_PER_RNC($RNCNAME)=$TOTAL_NUM_OF_INTER_RELATION_PER_RNC"
  echo "TOTAL_NUM_OF_EXTERNAL_RELATION_PER_RNC($RNCNAME)=$TOTAL_NUM_OF_EXTERNAL_RELATION_PER_RNC"
  echo "-----------------------------------------"

  TOTAL_NUM_OF_INTRA_RELATION_FOR_NETWORK=`expr $TOTAL_NUM_OF_INTRA_RELATION_FOR_NETWORK + $TOTAL_NUM_OF_INTRA_RELATION_PER_RNC`
  TOTAL_NUM_OF_INTER_RELATION_FOR_NETWORK=`expr $TOTAL_NUM_OF_INTER_RELATION_FOR_NETWORK + $TOTAL_NUM_OF_INTER_RELATION_PER_RNC`
  TOTAL_NUM_OF_EXTERNAL_RELATION_FOR_NETWORK=`expr $TOTAL_NUM_OF_EXTERNAL_RELATION_FOR_NETWORK + $TOTAL_NUM_OF_EXTERNAL_RELATION_PER_RNC`

  COUNT=`expr $COUNT + 1`  
done

  echo ""
  echo "####################################################################################"
  echo " UTRAM RELATION NETWORK REPORT START FROM `getRncName $START` TO `getRncName $END` "
  echo "####################################################################################"
  echo "TOTAL_NUM_OF_INTRA_RELATION_FOR_NETWORK=$TOTAL_NUM_OF_INTRA_RELATION_FOR_NETWORK"
  echo "TOTAL_NUM_OF_INTER_RELATION_FOR_NETWORK=$TOTAL_NUM_OF_INTER_RELATION_FOR_NETWORK"
  echo "TOTAL_NUM_OF_EXTERNAL_RELATION_FOR_NETWORK=$TOTAL_NUM_OF_EXTERNAL_RELATION_FOR_NETWORK"

