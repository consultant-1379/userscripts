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



#************************************************************
#************************************************************
# START OF PARALLEL RUN FUNCTIONS
#************************************************************

## Function: set_parallel_variables ###
#
#   Sets parallel variables and arrays per parallel process for use in parallel_status and parallel_wait functions
#
# Arguments:
#       none
# Return Values:
#       none

set_parallel_variables()
{
    last_pid="$!"
    parallel_pids="$parallel_pids $last_pid"
    parallel_strings[$last_pid]="$PARALLEL_STATUS_STRING"
    parallel_logs[$last_pid]="$LOG_FILE"
}

### Function: reset_parallel_variables ###
#
#   Resets parallel variables and arrays for use in parallel_status and parallel_wait functions
#
# Arguments:
#       none
# Return Values:
#       none

reset_parallel_variables ()
{
    processes_remaining_last=999
    parallel_pids=""
    parallel_strings=()
    parallel_logs=()
    LOG_FILE=""
    PARALLEL_STATUS_STRING=""
    SHOW_STATUS_UPDATES="YES"
    SHOW_OUTPUT_BORDERS="YES"
    PARALLEL_STATUS_HEADER=""
}
### Function: parallel_status ###
#
#   Used in proceses to check status of parallel proceses
#
# Arguments:
#       none
# Return Values:
#       none
parallel_status() {
    set $parallel_pids

    for pid in "$@"; do
        shift
        if kill -0 "$pid" 2>/dev/null; then
            set -- "$@" "$pid"
        fi
    done
    processes_remaining_now="$#"

    if [[ $processes_remaining_last -ne $processes_remaining_now ]]
    then

        output=$(
        set $parallel_pids

        echo "                                                                                            |"
        echo "                  |================================================================|        |"
        echo "                  | Parallel Status: $PARALLEL_STATUS_HEADER"
        echo "                  |----------------------------------------------------------------|        |"
        echo "                  |                                                                |        |"
        echo "                __|                                                                |________|"
        echo "               |"

        for pid in "$@"; do
            shift
            if kill -0 "$pid" 2>/dev/null; then
                echo "               | INFO:  ${parallel_strings[$pid]}: Running (Temp logfile ${parallel_logs[$pid]} )"
                set -- "$@" "$pid"
            else
                wait "$pid"
                EXIT_CODE="$?"
                if [[ $EXIT_CODE -eq 0 ]]
                then
                    echo "               | INFO:  ${parallel_strings[$pid]}: Completed"
                else
                    echo "               | ERROR: ${parallel_strings[$pid]}: Completed with exit code $EXIT_CODE, please check"
                fi
            fi
        done
        echo "               |__                                                                  ________"
        echo "                  |                                                                |        |"
        echo "                  |                                                                |        |"
        echo "                  |----------------------------------------------------------------|        |"
        echo "                  | Parallel Summary: Processes Remaining: $processes_remaining_now                       |        |"
        echo "                  |================================================================|        |"
        echo "                                                                                            |"
        )
        echo "$output"
    fi
    processes_remaining_last="$#"
}
### Function: parallel_finish ###
#
#   Used in functions to finish off a paralle process, output its logfile, retrieve its return code etc
#
# Arguments:
#       none
# Return Values:
#       none

parallel_finish()
{
    PARALLEL_EXIT_CODE="$?"

    output=$(
    if [[ "$SHOW_OUTPUT_BORDERS" != "NO" ]]
    then
        echo "                                                                                            |"
        echo "    |==============================================================================|        |"
        echo "    | Start Of Output For: $PARALLEL_STATUS_STRING"
        echo "    |------------------------------------------------------------------------------|        |"
        echo "    |                                                                              |        |"
        echo "____|                                                                              |________|"
        echo ""
    fi
    cat "$LOG_FILE"
    if [[ "$SHOW_OUTPUT_BORDERS" != "NO" ]]
    then
        echo "____                                                                                ________"
        echo "    |                                                                              |        |"
        echo "    |                                                                              |        |"
        echo "    |------------------------------------------------------------------------------|        |"
        echo "    | End Of Output For: $PARALLEL_STATUS_STRING"
        echo "    |==============================================================================|        |"
        echo "                                                                                            |"
    fi
    )
    echo "$output"
    cat "$LOG_FILE" >> $LOGFILE
    rm $LOG_FILE
    exit "$PARALLEL_EXIT_CODE"
}

### Function: parallel_wait ###
#
#   Used in functions to wait for parallel processes to finish
#
# Arguments:
#       none
# Return Values:
#       none

parallel_wait() {
    if [[ "$SHOW_STATUS_UPDATES" != "NO" ]]
    then
        output=$(
        echo ""
        echo "  |==============================================================================================|"
        echo "  | Starting Parallel Processes: $PARALLEL_STATUS_HEADER"
        echo "  |----------------------------------------------------------------------------------------------|"
        echo "  |                                                                                              |"
        echo "__|                                                                                          ____|"
        echo "                                                                                            |"
        )
        echo "$output"
        parallel_status
    fi
    set $parallel_pids
    while :; do
        #echo "Processes remaining: $#"
        for pid in "$@"; do
            #       echo "Checking on $pid"
            shift
            if kill -0 "$pid" 2>/dev/null; then
                #         echo "$pid is still running"
                set -- "$@" "$pid"
            else
                # A process just finished, print out the parallel status
                if [[ "$SHOW_STATUS_UPDATES" != "NO" ]]
                then
                    parallel_status
                fi
            fi
        done
        if [[ "$#" == 0 ]]
        then
            break
        fi
        sleep 1
    done

    if [[ "$SHOW_STATUS_UPDATES" != "NO" ]]
    then
        output=$(
        echo "__                                                                                          |____"
        echo "  |                                                                                              |"
        echo "  |                                                                                              |"
        echo "  |----------------------------------------------------------------------------------------------|"
        echo "  | Completed Parallel Processes: $PARALLEL_STATUS_HEADER"
        echo "  |==============================================================================================|"
        echo ""
        echo ""
        )
        echo "$output"
    fi

    # Exit script if one of the processes had a non 0 return code

    set $parallel_pids
    while :; do
        for pid in "$@"; do
            #       echo "Checking on $pid"
            shift
            if kill -0 "$pid" 2>/dev/null; then
                #         echo "$pid is still running"
                set -- "$@" "$pid"
            else
                # A process just finished, print out the parallel status
                wait "$pid"
                EXIT_CODE="$?"
                if [[ $EXIT_CODE -ne 0 ]]
                then
                    echo "INFO: At least one of the parallel processes ended with non 0 exit code, exiting script"
                    exit_routine $EXIT_CODE
                fi
            fi
        done
        if [[ "$#" == 0 ]]
        then
            break
        fi
        sleep 1
    done
    reset_parallel_variables


}
#************************************************************
#************************************************************
# END OF PARALLEL RUN FUNCTIONS
#************************************************************

PWD=`pwd`
NOW=`date +"%Y_%m_%d_%T"`

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

LOGFILE=${0}"_"${NOW}.log

if [ -f $PWD/$LOGFILE ]
then
 rm $PWD/$LOGFILE 
 echo ${LOGFILE}" log file deleted" 
 echo ""
fi

EXECUTE=YES
HOSTNAME=`hostname`
PROXY=atrclin2
#SERVERS="netsimlin144 netsimlin146"
#loc_SERVERS=" netsimlin145 netsimlin148 netsimlin161 netsimlin180 netsimlin188 netsimlin192 netsimlin322 netsimlin323 netsimlin324 netsimlin303 netsimlin72 netsimlin73"
#loc_SERVERS="netsimlin142"
#loc_SERVERS="netsimlin142 netsimlin145 netsimlin148 netsimlin161 netsimlin180 netsimlin188 netsimlin192 netsimlin322 netsimlin323 netsimlin324"
loc_SERVERS="netsimlin180 netsimlin188 netsimlin192 netsimlin322 netsimlin323 netsimlin324"
#loc_SERVERS="netsimlin180 netsimlin188"
#loc_SERVERS="netsimlin180"



# change NUMOFSCRIPTS accordingly your need
NUMOFSCRIPTS=1
#SCRIPT_1=createExternalNodes_ReqId5088.sh
SCRIPT_1=saveAndCompressSims.sh
SCRIPT_3=
SCRIPT_4=
SCRIPT_5=
SCRIPT_6=

INPUTSERVER=atrcus727
TARGET_CONFIGDIR=/export/home/qfatonu/config
TARGET_CONFIGFILE=${TARGET_CONFIGDIR}/${INPUTSERVER}_WRAN.cfg
CONFIGDIR=/tmp
CONFIGFILE=${CONFIGDIR}/${INPUTSERVER}_WRAN.cfg
rsh -n -l qfatonu ${PROXY} "/usr/bin/rcp ${TARGET_CONFIGFILE} netsim@${HOSTNAME}:/tmp/" 2>&1 | tee -a $LOGFILE
. $CONFIGFILE


for SERVER in $loc_SERVERS # for testing purposes, get server from local variable
#for SERVER in $SERVERS # get serevrs from CONFIG file
do

echo "#################################################################" | tee -a $LOGFILE
echo "# START SCRIPTS RUNNING ON.. >>"$SERVER | tee -a $LOGFILE
echo "#################################################################" | tee -a $LOGFILE
echo "Init Date: "`date` 2>&1 | tee -a $LOGFILE
echo ""


 SERVER=${SERVER}

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
   echo "$SERVER is fetching simulations of $LIST"  2>&1 | tee -a $LOGFILE
   echo " "  2>&1 | tee -a $LOGFILE

   if [  "$EXECUTE" != "YES" ]
   then
	echo "No execution of script"  2>&1 | tee -a $LOGFILE
        echo " "  2>&1 | tee -a $LOGFILE
        COUNT=`expr $COUNT + 1`
	continue
   fi

   
   for RNC in $LIST
   do

     ###################################
     # Parallel variable initialization
     ###################################
     LOG_FILE=/tmp/$RNC.log
     PARALLEL_STATUS_HEADER="Running Scripts"
     PARALLEL_STATUS_STRING="Runnnig Scripts for $RNC" on "$SERVER
     SHOW_STATUS_UPDATES="YES"
     SHOW_OUTPUT_BORDERS="YES"
     ###################################
     (
     (


       ZERO=`echo $RNC | cut -c4`  # e.g iecho RNC04 | cut -c4 assign to ZERO=0
       if [ "$ZERO" -eq "0" ]
       then
         RNCCOUNT=`echo $RNC | cut -c5` # e.g iecho RNC04 | cut -c5 assign to ZERO=4
       else
         RNCCOUNT=`echo $RNC | cut -c4-5` # e.g iecho RNC14 | cut -c4-5 assign to ZERO=14
       fi
	
     
       echo "RNCNAME="$RNC | tee -a $LOG_FILE

       echo "_rsh -n -l qfatonu ${PROXY} "/usr/bin/rsh -n -l netsim $SERVER "/tmp/${SCRIPT}""" | tee -a $LOG_FILE
       echo "----------------------------" | tee -a $LOG_FILE
       echo "- ${SERVER}> /tmp/${SCRIPT} $RNCCOUNT" | tee -a $LOG_FILE
       echo "----------------------------" | tee -a $LOG_FILE
       rsh -n -l qfatonu ${PROXY} "/usr/bin/rsh -n -l netsim $SERVER "/tmp/${SCRIPT} ${RNCCOUNT}"" 2>&1 | tee -a $LOG_FILE
       debug $? 2>&1 | tee -a $LOG_FILE
       echo "" | tee -a $LOG_FILE
       # exit 0

      ) > $LOG_FILE 2>&1;parallel_finish
      ) & set_parallel_variables

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

parallel_wait

echo "END OF SCRIPT..." | tee -a $LOGFILE
echo ""
echo "End Date: "`date` 2>&1 | tee -a $LOGFILE



