#!/bin/sh

# Created by  : qfatonu
# Created in  : 30.05.2010
##
### VERSION HISTORY
# Ver1        : req id:4187
# Purpose     : Creates "NbapCommon or NbapDedicated"
# Description :
# Date        : 28 May 2010
# Who         : Fatih ONUR

if [ "$#" -ne 2  ]
then
cat<<HELP

Usage: $0 <rnc num> <type>

Example: $0 1 L145 

CREATE : NbapCommon and NbapDedicated

HELP
 exit 1
fi

TYPE=$2
if [ "$1" -le 9 ]
then
RNCNAME="RNC0"$1
RNCCOUNT="0"$1
else
RNCNAME="RNC"$1
RNCCOUNT=$1
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

SIMNAME=`ls /netsim/netsimdir | grep ${RNCNAME} | grep ${TYPE} | grep PLM | grep -v zip`

#########################################
# 
# Make MO Script
#
#########################################

echo ""
echo "MAKING MO SCRIPT"
echo ""

NUMOFRBS=30

IUBCOUNT=1
IUBEND=$NUMOFRBS

while [ "$IUBCOUNT" -le "$IUBEND" ]
do

cat >> $MOSCRIPT << MOSCT

CREATE
(
  parent "ManagedElement=1,NodeBFunction=1,Iub=1"
 identity 1
 moType NbapCommon
 exception none
)


CREATE
(
  parent "ManagedElement=1,NodeBFunction=1,Iub=1"
 identity 1
 moType NbapDedicated
 exception none
)

MOSCT

IUBCOUNT=`expr $IUBCOUNT + 1`

done



#########################################
#
# Make MML Script
#
#########################################

echo ""
echo "MAKING MML SCRIPT"
echo ""

RBSNES='.*RBS.*'

cat >> $MMLSCRIPT << MMLSCT

.open $SIMNAME
.selectregexp simne $RBSNES
.start
useattributecharacteristics:switch="off";
kertayle:file="$PWD/$MOSCRIPT";

MMLSCT


 /netsim/inst/netsim_shell < $MMLSCRIPT


rm $PWD/$MOSCRIPT
rm $PWD/$MMLSCRIPT

