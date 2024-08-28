#!/bin/sh

# Created by  : qfatonu
# Created in  : 29 May 2009
##
### VERSION HISTORY
# Ver1        : Created for Faisal Ghaffar
# Purpose     : To start or stop all the nodes within netsimdir directory
# Description : Starting and stopping all the nodes of simulation within netsimdir directory
#               It is asummed that simulation weren't uncompressed before.    
# Date        : 29 May 2009
# Who         : Fatih ONUR

if [ "$#" -ne 1  ]
then
cat<<HELP

####################
# HELP
####################

Usage  : $0 <start|stop>

Example: $0 start
Example: $0 stop

DESCRIP: START or STOP all the nodes wtihin default /netsim/netsimdir directory
         Below variables needs to be set up.

 NETSIMVERSION=inst (default)
 STARTSTOPACTIVATE=no (default)
 ADDSHIP= (default empty)   


HELP

exit 1
fi

NETSIMVERSION=inst
NETSIMDIR=$HOME

ADDSHIP=
STARTSTOPACTIVATE=yes

PWD=`pwd`

MMLSCRIPT=$0".mml"


if [ -f $PWD/$MMLSCRIPT ]
then
 rm -r  $PWD/$MMLSCRIPT
echo "old "$PWD/$MMLSCRIPT " removed"
fi


if [ $# -eq 1 ]; then
LIST=`ls /netsim/netsimdir | grep zip`
fi
    
echo "#############################################################"
echo "# $0 $1 running"
echo "#############################################################"
echo ""


for ZIP in $LIST
do
SIM=`echo $ZIP | cut -c 1-$(echo "${#ZIP} - 4" | bc)`$ADDSHIP

 if [ -d "$HOME/netsimdir/$SIM" ]; then
     # *** Note *** 
     # Assuming simulations are stored in default dir $HOME/netsimdir
     echo "Used uncompressed simulation"
     echo "Simulation $HOME/netsimdir/$SIM"
     echo "already exists. "
     echo ""
 else
    echo "#############################################################"
    echo "# Uncompressing /netsim/netsimdir/$ZIP" 
    echo "#############################################################"   
    echo ""
    echo ".uncompressandopen "/netsim/netsimdir/$ZIP "/netsim/netsimdir/"$SIM "tryforce" | /netsim/inst/netsim_shell
 fi

if [ "$STARTSTOPACTIVATE" = "yes" ] ; then


if [ "$1" = "yes" ] ; then
ACTION=start
else
ACTION=stop
fi

echo "###############################################################"
echo "# $ACTION all nodes in /netsim/netsimdir/$SIM" simulation
echo "################################################################"
echo ""
cat >> $MMLSCRIPT << MMLSCT

.open $SIM
.select network
.$ACTION

MMLSCT
 
$NETSIMDIR/$NETSIMVERSION/netsim_shell < $MMLSCRIPT
rm -r  $PWD/$MMLSCRIPT
echo ""

fi

done
