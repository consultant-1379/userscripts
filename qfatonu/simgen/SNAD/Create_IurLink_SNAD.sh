#!/bin/sh

# Created by  : qfatonu
# Created in  : 26 August 2009
##
### VERSION HISTORY
# Ver1        : Created for WRAN deployment O.10.0 ShipG, SNAD Inconsistencies, req id:1361
# Purpose     : Create Iurlink and related UtranNetwork for SNAD.
# Description : 
# Date        : 26 August 2009 
# Who	      : Fatih ONUR

if [ $# -ne 1 ]; then

cat << HELP

Usage: $0 <rnc name>
Example: $0 RNC33
    
HELP
exit 1
fi

RNC=$1
MOSCRIPT=$0".mo"
MMLSCRIPT=$0".mml"

PWD=`pwd`

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
echo "MAKING MO SCRIPT"
echo ""

COUNT=51
while [ "$COUNT" -le 70 ]
do

echo 'CREATE' >> $MOSCRIPT
echo '(' >> $MOSCRIPT
echo '    parent "ManagedElement=1,RncFunction=1"' >> $MOSCRIPT
echo '    identity '$COUNT >> $MOSCRIPT
echo '    moType UtranNetwork' >> $MOSCRIPT
echo '    exception none' >> $MOSCRIPT
echo '    nrOfAttributes 3' >> $MOSCRIPT
echo '    "UtranNetworkId" String "1"' >> $MOSCRIPT
echo '    "aliasPlmnIdentities" Array Struct 0' >> $MOSCRIPT
echo '    "plmnIdentity" Struct' >> $MOSCRIPT
echo '        nrOfElements 3' >> $MOSCRIPT
echo '        "mcc" Integer 353' >> $MOSCRIPT
echo '        "mnc" Integer '$COUNT >> $MOSCRIPT
echo '        "mncLength" Integer 2' >> $MOSCRIPT
echo ')' >> $MOSCRIPT

echo 'CREATE' >> $MOSCRIPT
echo '(' >> $MOSCRIPT
echo '  parent "ManagedElement=1,RncFunction=1"' >> $MOSCRIPT
echo '   identity '$COUNT >> $MOSCRIPT
echo '   moType IurLink' >> $MOSCRIPT
echo '   exception none' >> $MOSCRIPT
echo '   nrOfAttributes 3' >> $MOSCRIPT
#echo '   mcc Integer 353' >> $MOSCRIPT
#echo '   mnc Integer '$COUNT >> $MOSCRIPT
#echo '   mncLength Integer 2' >> $MOSCRIPT
echo '   rncId Integer' $COUNT >> $MOSCRIPT
echo '   utranNetworkRef Ref "ManagedElement=1,RncFunction=1,UtranNetwork='$COUNT'"' >> $MOSCRIPT
echo '   userLabel String RNC34-'$COUNT >> $MOSCRIPT
echo ')' >> $MOSCRIPT


COUNT=`expr $COUNT + 1`
done


SIM=`ls /netsim/netsimdir | grep ${RNC} | grep -v zip`

echo 'Creating MMLScript...'
echo '.open '$SIM >> $MMLSCRIPT
#echo '.open RNCK965-ST-RNC34' >> $MMLSCRIPT
echo '.select '${RNC} >> $MMLSCRIPT
echo 'useattributecharacteristics:switch="off";' >> $MMLSCRIPT
echo 'kertayle:file="'$PWD'/'$MOSCRIPT'",commit_freq=operation;' >> $MMLSCRIPT

echo 'Executing MMLScript...'
/netsim/inst/netsim_shell < $MMLSCRIPT
rm -r  $PWD/$MMLSCRIPT
rm -r $PWD/$MOSCRIPT
echo 'Finished'
