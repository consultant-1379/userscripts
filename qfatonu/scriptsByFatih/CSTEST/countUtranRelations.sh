#!/bin/sh


START=1
END=10

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

  NUMOFUTRANREL=`grep -c =$RNCNAME, UtranRelations.txt`
  echo "$RNCNAME="$NUMOFUTRANREL
  SUM=`expr $SUM + $NUMOFUTRANREL`

  COUNT=`expr $COUNT + 1`  
done

echo "SUM=$SUM"

