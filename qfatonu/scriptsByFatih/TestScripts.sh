#!/bin/sh

echo "TESTING"

MMLSCRIPT=$0$$".mml"

PWD=`pwd`
NOW=`date +"%Y_%m_%d_%T:%N"`

# to get rid of extra prefix when we run the command on remote server
if [ ! -f $PWD/$0 ]
  then
  PWD=""
fi

if [ "$1" -le 9 ]
then
  RNCNAME="RNC0"$1
  RNCCOUNT="0"$1
else
  RNCNAME="RNC"$1
  RNCCOUNT=$1
fi


if [ -f $PWD/$MMLSCRIPT ]
then
rm -r  $PWD/$MMLSCRIPT
echo "old "$PWD/$MMLSCRIPT " removed"
fi


SIMNAME=`ls /netsim/netsimdir | egrep ${RNCNAME} | egrep "ST|FT" | grep -m1 -v zip`

cat >> $MMLSCRIPT << MMLSCT

.open $SIMNAME 
.select $RNCNAME
.start -parallel
setmoattribute:mo="ManagedElement=1", attributes="userLabel (str)=TESTING"; 

MMLSCT

/netsim/inst/netsim_shell < $MMLSCRIPT

rm $PWD/$MMLSCRIPT
