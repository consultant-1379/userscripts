#!/bin/sh

# Created by  : qfatonu
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

EXECUTE=NO
HOSTNAME=`hostname`
PROXY=atrclin2
#SERVERS="netsimlin144 netsimlin146"
#loc_SERVERS="netsimlin144"
#loc_SERVERS="netsimlin144 netsimlin146 netsimlin147 netsimlin149 netsimlin150 netsimlin151 netsimlin152 netsimlin153 netsimlin156 netsimlin187 netsimlin186"
#loc_SERVERS="netsimlin301 netsimlin302 netsimlin303 netsimlin304 netsimlin305 netsimlin306"
#loc_SERVERS="netsimlin302 netsimlin303 netsimlin304 netsimlin305 netsimlin306"
#loc_SERVERS="netsimlin308"

# change NUMOFSCRIPTS accordingly your need
NUMOFSCRIPTS=2
SCRIPT_1=deleteUtranRelation.sh
SCRIPT_2=createUtranRelation.sh
SCRIPT_3=
SCRIPT_4=
SCRIPT_5=
SCRIPT_6=saveAndCompressSims.sh

#INPUTSERVER=atrcus734
INPUTSERVER=atrcus534
TARGET_CONFIGDIR=/export/home/ejershe/TCM-WebPage/wran/config_files
TARGET_CONFIGFILE=${TARGET_CONFIGDIR}/${INPUTSERVER}.cfg
CONFIGDIR=/tmp/
CONFIGFILE=${CONFIGDIR}/${INPUTSERVER}.cfg
rsh -n -l qfatonu ${PROXY} "/usr/bin/rcp ${TARGET_CONFIGFILE} netsim@${HOSTNAME}:/tmp/" 2>&1 | tee -a $LOGFILE
. $CONFIGFILE


#for SERVER in $loc_SERVERS # for testing purposes, get server from local variable
for SERVER in $SERVERS # get serevrs from CONFIG file
do

echo "#################################################################" | tee -a $LOGFILE
echo "# START SCRIPTS RUNNING ON.. >>"$SERVER | tee -a $LOGFILE
echo "#################################################################" | tee -a $LOGFILE
echo "Init Date: "`date` 2>&1 | tee -a $LOGFILE
echo ""


SERVER=${SERVER}-inst
#SERVER=${SERVER}

 COUNT=1
 while [ "$COUNT" -le "$NUMOFSCRIPTS" ]
 do

   SCRIPT=`eval echo \\$SCRIPT_${COUNT}` 
   checkExist $SCRIPT

   echo "/usr/bin/rcp $PWD/${SCRIPT} qfatonu@${PROXY}:/tmp/"  | tee -a $LOGFILE
   echo "----------------------------"  | tee -a $LOGFILE
   echo "${HOSTNAME}> rcp /tmp/${SCRIPT} qfatonu@${PROXY}:/tmp/"  | tee -a $LOGFILE
   echo "----------------------------"  | tee -a $LOGFILE
   /usr/bin/rcp $PWD/${SCRIPT} qfatonu@${PROXY}:/tmp/ 2>&1 | tee -a $LOGFILE
   debug $? 2>&1 | tee -a $LOGFILE
   echo "" | tee -a $LOGFILE

   echo "rsh -n -l qfatonu ${PROXY} "/usr/bin/rcp /tmp/${SCRIPT} netsim@${SERVER}:/tmp/"" | tee -a $LOGFILE
   echo "----------------------------"  | tee -a $LOGFILE
   echo "${SERVER}> rcp /tmp/${SCRIPT} netsim@${SERVER}:/tmp/"  | tee -a $LOGFILE
   echo "----------------------------"  | tee -a $LOGFILE
   rsh -n -l qfatonu ${PROXY} "/usr/bin/rcp /tmp/${SCRIPT} netsim@${SERVER}:/tmp/" 2>&1 | tee -a $LOGFILE
   debug $? 2>&1 | tee -a $LOGFILE
   echo "" | tee -a $LOGFILE

   echo "rsh -n -l qfatonu ${PROXY} "/usr/bin/rsh -n -l netsim $SERVER "chmod +x /tmp/${SCRIPT}""" | tee -a $LOGFILE
   echo "----------------------------" | tee -a $LOGFILE
   echo "${SERVER}> chmod +x /tmp/${SCRIPT}" | tee -a $LOGFILE
   echo "----------------------------" | tee -a $LOGFILE
   rsh -n -l qfatonu ${PROXY} "/usr/bin/rsh -n -l netsim $SERVER "chmod +x /tmp/${SCRIPT}"" 2>&1 | tee -a $LOGFILE
   debug $? 2>&1 | tee -a $LOGFILE
   echo "" | tee -a $LOGFILE


   HOST=`rsh -n -l qfatonu ${PROXY} "/usr/bin/rsh -n -l netsim $SERVER "hostname""`
   LIST=`eval echo '$'${HOST}_list`
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
     ZERO=`echo $RNC | cut -c4`  # e.g iecho RNC04 | cut -c4 assign to ZERO=0
     if [ "$ZERO" -eq "0" ]
     then
       RNCCOUNT=`echo $RNC | cut -c5` # e.g iecho RNC04 | cut -c5 assign to ZERO=4
     else
       RNCCOUNT=`echo $RNC | cut -c4-5` # e.g iecho RNC14 | cut -c4-5 assign to ZERO=14
     fi
	
     
     echo "RNCNAME="$RNC | tee -a $LOGFILE

     echo "rsh -n -l qfatonu ${PROXY} "/usr/bin/rsh -n -l netsim $SERVER "/tmp/${SCRIPT}""" | tee -a $LOGFILE
     echo "----------------------------" | tee -a $LOGFILE
     echo "- ${SERVER}> /tmp/${SCRIPT} $RNCCOUNT" | tee -a $LOGFILE
     echo "----------------------------" | tee -a $LOGFILE
     rsh -n -l qfatonu ${PROXY} "/usr/bin/rsh -n -l netsim $SERVER "/tmp/${SCRIPT} ${RNCCOUNT}"" 2>&1 | tee -a $LOGFILE
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

