#Created by  : qfatonu
# Created in  : 02 Mar 10
##
### VERSION HISTORY
# Ver1        : Created for WRAN deployment o.10.2.4, req id:3425
# Purpose     :
# Description :
# Date        : 02.03.2010
# Who         : Fatih ONUR

if [ "$#" -ne 1  ]
then
cat<<HELP

Usage: $0 <go>

Example: $0 GO

DESC   :

CONFIG : Followring variables can be set within scripts


HELP
 exit 1
fi

PWD=`pwd`

# functions
debug() { # $?

rc=$1
if [[ $rc != 0 ]] ; then
    echo "Exiting due to Error..."
    exit $rc
fi
}

checkExist() { # FILE

FILE=$1

if [ ! -f $PWD/$FILE ]
then
  echo "ERROR!! Script doesnt exist!"
  exit 0
fi
}

LOGFILE=$0.log

if [ -f $PWD/$LOGFILE ]
then
 rm $PWD/$LOGFILE 
 echo ${LOGFILE}" log file deleted" 
 echo ""
fi

EXECUTE=YES
HOSTNAME=`hostname`
#***************************************************************************************************************************
#									CONFIG FILE DETAILS							
#***************************************************************************************************************************
#LOC_SERVERS="netsimlin299 netsimlin300 netsimlin350 netsimlin351 netsimlin352 netsimlin223"
LOC_SERVERS="netsimlin271vm1 netsimlin271vm2"
#LOC_SERVERS="netsimlin271vm2"
netsimlin271vm1_list="RNC16"
netsimlin271vm2_list="RNC01"
netsimlin299_list="RNC01 RNC02 RNC03 RNC04 RNC05 RNC06 RNC07 RNC08 RNC09 RNC10 RNC11 RNC12 RNC13 RNC14 RNC15 RNC16"
netsimlin300_list="RNC17 RNC18 RNC19 RNC20 RNC21 RNC22 RNC23 RNC24 RNC25 RNC26 RNC27 RNC28 RNC29 RNC30 RNC31 RNC32"
netsimlin350_list="RNC33 RNC34 RNC35 RNC36 RNC37 RNC38 RNC39 RNC40 RNC41 RNC42 RNC43 RNC44 RNC45 RNC46 RNC47 RNC48"
netsimlin351_list="RNC49 RNC50 RNC51 RNC52 RNC53 RNC54 RNC55 RNC56 RNC57 RNC58 RNC59 RNC60 RNC61 RNC62 RNC63 RNC64"
netsimlin352_list="RNC65 RNC66 RNC67 RNC68 RNC69 RNC70 RNC71 RNC72 RNC73 RNC74 RNC75 RNC76 RNC77"
netsimlin223_list="RNC78 RNC79 RNC80 RNC81 RNC82"
#***************************************************************************************************************************

# change NUMOFSCRIPTS accordingly your need
NUMOFSCRIPTS=1
SCRIPT_1=Scripts.sh
SCRIPT_2=showfreeIPs
SCRIPT_3=
SCRIPT_4=
SCRIPT_5=
SCRIPT_6=saveAndCompressSims.sh


for SERVER in $LOC_SERVERS # get serevrs from CONFIG file
do

echo "#################################################################" | tee -a $LOGFILE
echo "# START SCRIPTS RUNNING ON.. >>"$SERVER | tee -a $LOGFILE
echo "#################################################################" | tee -a $LOGFILE
echo "Init Date: "`date` 2>&1 | tee -a $LOGFILE
echo ""


 #SERVER=${SERVER}-inst

 COUNT=1
 while [ "$COUNT" -le "$NUMOFSCRIPTS" ]
 do

   SCRIPT=`eval echo \\$SCRIPT_${COUNT}` 
   checkExist $SCRIPT

   #echo "/usr/bin/rcp /tmp/${SCRIPT} netsim@${SERVER}:/tmp/" | tee -a $LOGFILE
   echo "----------------------------"  | tee -a $LOGFILE
   echo "${HOSTNAME}> rcp /tmp/${SCRIPT} netsim@${SERVER}:/tmp/"  | tee -a $LOGFILE
   echo "----------------------------"  | tee -a $LOGFILE
   /usr/bin/rcp /tmp/${SCRIPT} netsim@${SERVER}:/tmp/ 2>&1 | tee -a $LOGFILE
   debug $? 2>&1 | tee -a $LOGFILE
   echo "" | tee -a $LOGFILE

   

   #echo "/usr/bin/rsh -n -l netsim $SERVER "chmod +x /tmp/${SCRIPT}"" | tee -a $LOGFILE
   echo "----------------------------" | tee -a $LOGFILE
   echo "${HOSTNAME}> rsh -n -l netsim $SERVER chmod +x /tmp/${SCRIPT}/" | tee -a $LOGFILE
   echo "----------------------------" | tee -a $LOGFILE
   /usr/bin/rsh -n -l netsim $SERVER "chmod +x /tmp/${SCRIPT}" 2>&1 | tee -a $LOGFILE
   debug $? 2>&1 | tee -a $LOGFILE
   echo "" | tee -a $LOGFILE


   LIST=`eval echo '$'${SERVER}_list`
   echo "$SERVER is fetching simulations of $LIST"

   if [  "$EXECUTE" != "YES" ]
   then
	echo "No execution of script"
        echo ""
        COUNT=`expr $COUNT + 1`
	continue
   fi

   
   for RNC in $LIST
   do
     ZERO=`echo $RNC | cut -c4`  # e.g echo RNC04 | cut -c4 assign to ZERO=0
     if [ "$ZERO" -eq "0" ]
     then
       RNCCOUNT=`echo $RNC | cut -c5` # e.g echo RNC04 | cut -c5 assign to ZERO=4
     else
       RNCCOUNT=`echo $RNC | cut -c4-5` # e.g echo RNC14 | cut -c4-5 assign to ZERO=14
     fi
	
     
     echo "RNCNAME="$RNC | tee -a $LOGFILE

     #echo "/usr/bin/rsh -n -l netsim $SERVER "/tmp/${SCRIPT}"" | tee -a $LOGFILE
     echo "----------------------------" | tee -a $LOGFILE
     echo "- ${SERVER}> /tmp/${SCRIPT} $RNCCOUNT " | tee -a $LOGFILE
     echo "----------------------------" | tee -a $LOGFILE
     /usr/bin/rsh -n -l netsim $SERVER "/tmp/${SCRIPT} ${RNCCOUNT}" 2>&1 | tee -a $LOGFILE
     debug $? 2>&1 | tee -a $LOGFILE
     echo "" | tee -a $LOGFILE
     # exit 0

   done


 COUNT=`expr $COUNT + 1`
 done

echo ""
echo "End Date: "`date` 2>&1 | tee -a $LOGFILE
echo "END.. >>"$SERVER | tee -a $LOGFILE
echo "#################################################################" | tee -a $LOGFILE
echo "" | tee -a $LOGFILE
echo "" | tee -a $LOGFILE

done

echo "END OF SCRIPT..." | tee -a $LOGFILE
echo ""


