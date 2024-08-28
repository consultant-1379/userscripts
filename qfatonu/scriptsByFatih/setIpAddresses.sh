#!/bin/sh

# Created by  : qfatonu
# Created in  : 28 Mar 2011
##
### VERSION HISTORY
# Ver1        : Created for WRAN2 deployment O11.2
# Purpose     : To set ip addresses
# Description : Get the base ip from "more /etc/host" command
# Date        : 28.03.2011
# Who         : Fatih ONUR

if [ "$#" -ne 1  ]
then
cat<<HELP

Usage: $0 <rnc num>

Example: $0 9 (run script for RNC09-ST-...)

DESC   :

CONFIG : Followring variables can be set within scripts


HELP
 exit 1
fi


################################
# MAIN
################################

echo "...script started running at "`date`
echo ""

# MANUAL ENVIREMOENTS
NETSIMVERSION=inst
NETSIMDIR=$HOME

if [ "$1" -le 9 ]
then
RNCNAME="RNC0"$1
RNCCOUNT="0"$1
else
RNCNAME="RNC"$1
RNCCOUNT=$1
fi

SIMNAME=`ls /netsim/netsimdir | egrep ${RNCNAME} | grep ST | grep -m1 -v zip`


PWD=`pwd`
# to get rid of extra prefix when we run the command on remote server
if [ ! -f $PWD/$0 ]
then
PWD=""
fi
NOW=`date +"%Y_%m_%d_%T:%N"`

MMLSCRIPT=$0${NOW}".mml"

if [ -f $PWD/$MMLSCRIPT ]
then
  rm -r  $PWD/$MMLSCRIPT
  echo "old "$PWD/$MMLSCRIPT " removed"
fi


#########################################
#
# Make MML Script
#
#########################################

echo ""
echo "MAKING MML SCRIPT"
echo ""

COUNT=$1
STOP=20

while [ "$COUNT" -le "$STOP" ]
do

if [ "$COUNT" -le 9 ]
then
RNCNAME="RNC0"$COUNT
RNCCOUNT="0"$COUNT
else
RNCNAME="RNC"$COUNT
RNCCOUNT=$COUNT
fi

SIMNAME=`ls /netsim/netsimdir | egrep ${RNCNAME} | grep ST | grep -m1 -v zip`


echo '.open '$SIMNAME >> $MMLSCRIPT
echo '.select '$RNCNAME >> $MMLSCRIPT
echo ".set port NetSimPort" >> $MMLSCRIPT
echo ".modifyne set_subaddr 10.14.197.$COUNT subaddr no_value" >> $MMLSCRIPT
echo ".set save" >> $MMLSCRIPT

$NETSIMDIR/$NETSIMVERSION/netsim_pipe < $MMLSCRIPT

COUNT=`expr $COUNT + 1`
done


rm $PWD/$MMLSCRIPT

echo "...script ended at "`date`
echo ""
