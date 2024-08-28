#!/bin/sh

# Created by : Fatih ONUR
# Created in : unknown
##
### VERSION HISTORY
##################################################
# Ver1        : Created for Shreaya Pallava, Core
# Purpose     : 
# Description :
# Date        : 07 AUG 2012
# Who         : Fatih ONUR
##################################################


if [ "$#" -ne 1  ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 <sim name> 

Example: $0 

SET: Subrack 

HELP

exit
fi

################################
# MAIN
################################

echo "... $0 script started running at "`date`
echo ""

SIMNAME=$1

PWD=`pwd`
NOW=`date +"%Y_%m_%d_%T:%N"`

max=1000000
RANDOM=$((`cat /dev/urandom|od -N1 -An -i` % $max))

MMLSCRIPT=$0${NOW}:$$${RANDOM}".mml"

NETSIM_DB_DIR="/netsim/netsim_dbdir/simdir/netsim/netsimdir"


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


ERBS_LIST=`ls $NETSIM_DB_DIR/$SIMNAME | grep ERBS`

echo ".open $SIMNAME" >> $MMLSCRIPT

for ERBS in $ERBS_LIST
do
	echo ".select $ERBS" >> $MMLSCRIPT
	echo "setmoattribute:mo=\"ManagedElement=1,Equipment=1,Subrack=1\", attributes=\"operationalProductData (struct, operationalProductData)=[$ERBS, $ERBS, $ERBS, $ERBS, $ERBS]\";" >> $MMLSCRIPT

done

/netsim/inst/netsim_pipe < $MMLSCRIPT

rm $PWD/$MMLSCRIPT

echo "...$0 script ended at "`date`
echo ""


