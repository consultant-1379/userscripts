#!/bin/bash

set +x
curl -O https://arm1s11-eiffel004.eiffel.gic.ericsson.se:8443/nexus/content/repositories/releases/com/ericsson/ci/simnet/ERICTAFenmnisimdep_CXP9031884/$simdepRelease/ERICTAFenmnisimdep_CXP9031884-$simdepRelease.jar
mkdir -p ERICTAFenmnisimdep_CXP9031884/src/main/resources;
unzip ERICTAFenmnisimdep_CXP9031884-$simdepRelease.jar -d ERICTAFenmnisimdep_CXP9031884/src/main/resources  
chmod -R 755 ./*
sed -i 's/\r//' `find ./ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins -print | egrep -i 'sh|pl|txt'`
#ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/applyTLS.sh -n $nssRelease -s $simdepRelease -t $serverType -i $ID_for_server -h "$serverName"

########################################################
#Finding netsim details from the given cluster id.
########################################################
clusterId=$ID_for_server
wget -q -O - --no-check-certificate "https://cifwk-oss.lmera.ericsson.se/generateTAFHostPropertiesJSON/?clusterId=${clusterId}&tunnel=true" > sed

NETSIM_HOSTNAMES=`grep -oh "\w*ieatnetsim\w*-\w*" sed`
if [ -n "$serverName" ]; then
  NETSIM_HOSTNAMES=$serverName
fi
echo "NETSIM_HOSTNAMES=$NETSIM_HOSTNAMES"

#NETSIM_HOSTS_ARRAY=("ieatnetsimv6000-01" "ieatnetsimv6000-02" "ieatnetsimv6000-03")
NETSIM_HOSTS_ARRAY=()
for NETSIM in $NETSIM_HOSTNAMES
do
  NETSIM_HOSTS_ARRAY+=("$NETSIM")
done
echo "NETSIM_HOSTS_ARRAY=${NETSIM_HOSTS_ARRAY[@]}"
echo "NETSIM_HOSTS_ARRAY[2]=${NETSIM_HOSTS_ARRAY[2]}"


NOW=`date +"%Y_%m_%d_%T:%N"`
LOGFILE_BASE="/tmp/tp${NOW}"

MAX_CONCURRENT_NUM_OF_JOBS=20  
CURRENT_NUM_OF_JOBS=0

TOTAL_NUM_OF_JOBS=`echo ${NETSIM_HOSTS_ARRAY[@]} | perl -lne '$count=0;$count++ for m/ieat/g;END{print $count}'`
TOTAL_NUM_OF_JOBS_COMPLETED=0
TOTAL_NUM_OF_JOBS_LEFT=0
TOTAL_NUM_OF_JOBS_FAILED=0
EXIT_CODES=''
FINISHED_JOBS=''
PIDS=''
BGP_OUTPUT_ARRAY=()

COUNT=1
if [ $TOTAL_NUM_OF_JOBS -ge $MAX_CONCURRENT_NUM_OF_JOBS ]
then
    STOP=`expr $COUNT + $MAX_CONCURRENT_NUM_OF_JOBS - 1`
    TOTAL_NUM_OF_JOBS_LEFT=`expr $TOTAL_NUM_OF_JOBS - $MAX_CONCURRENT_NUM_OF_JOBS`
else
    STOP=$TOTAL_NUM_OF_JOBS 
    TOTAL_NUM_OF_JOBS_LEFT=$TOTAL_NUM_OF_JOBS
fi

while [ "$COUNT" -le "$STOP" ]
do
    serverName=${NETSIM_HOSTS_ARRAY[$(($COUNT - 1))]}
    LOGFILE=${LOGFILE_BASE}_${NETSIM_HOSTS_ARRAY[$(($COUNT - 1))]}.log
    echo "***************************" >> $LOGFILE
    echo "*SERVER=${NETSIM_HOSTS_ARRAY[$(($COUNT - 1))]}*" >> $LOGFILE
    echo "***************************" >> $LOGFILE   

    #( ./someScript.sh $X $Y $Z 2>&1 ) | tee -a $LOGFILE & 
    #( ./backup_createSimulationIPParallel.sh $SIM $COUNT $ENV ) >> ${LOGFILE} 2>&1 &
    (./ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/applyTLS.sh -n $nssRelease -s $simdepRelease -t $serverType -i $ID_for_server -h "$serverName") >> ${LOGFILE} 2>&1 &
    #sleep $(($RANDOM / 10000)) &
    scriptBGP=$!
    PIDS="$PIDS $scriptBGP" 
    allBGP="$allBGP $scriptBGP"
    
    
    echo "...$COUNT=$SIM PID=$scriptBGP is running" | tee -a PIDS.log
    BGP_OUTPUT="$COUNT=${NETSIM_HOSTS_ARRAY[$(($COUNT - 1))]} PID=$scriptBGP" 
    BGP_OUTPUT_ARRAY[scriptBGP]=$BGP_OUTPUT

    #sleep 1
    CURRENT_NUM_OF_JOBS=`expr $CURRENT_NUM_OF_JOBS + 1`
    COUNT=`expr $COUNT + 1`
done

if [ $TOTAL_NUM_OF_JOBS_LEFT -ne 0 ]
then

  while true
  do

    #set $PIDS > /dev/null
    set -- $PIDS 
    for PID in "$@"
    do
      shift
      if kill -0 "$PID" 2>/dev/null; then
         #echo "---$PID is still running" | tee -a PIDS.log
         echo "---${BGP_OUTPUT_ARRAY[$PID]} is running" |  tee -a PIDS.log
         set -- "$@" "$PID"
      else
         wait "$PID"   
         EXIT_CODE=$?
         EXIT_CODES="$EXIT_CODES $EXIT_CODE"
         if [ $EXIT_CODE -ne 0 ]
         then
             echo "***WARNING: ${BGP_OUTPUT_ARRAY[$PID]} throw an error!!! See log files!!!"  
             TOTAL_NUM_OF_JOBS_FAILED=$(($TOTAL_NUM_OF_JOBS_FAILED + 1))
         fi
     
         echo "+++`date`" 
         CURRENT_NUM_OF_JOBS=$(($CURRENT_NUM_OF_JOBS - 1))
         TOTAL_NUM_OF_JOBS_COMPLETED=$(($TOTAL_NUM_OF_JOBS_COMPLETED + 1))
         TOTAL_NUM_OF_JOBS_LEFT=$(($TOTAL_NUM_OF_JOBS - $TOTAL_NUM_OF_JOBS_COMPLETED))
              
         echo "+++COMPLETED_JOB:"${BGP_OUTPUT_ARRAY[$PID]}
         echo "+++CURRENT_NUM_OF_JOBS="$CURRENT_NUM_OF_JOBS | tee -a PIDS.log
         echo "+++TOTAL_NUM_OF_JOBS_COMPLETED="$TOTAL_NUM_OF_JOBS_COMPLETED | tee -a PIDS.log
         echo "+++TOTAL_NUM_OF_JOBS_LEFT="$TOTAL_NUM_OF_JOBS_LEFT | tee -a PIDS.log
         echo "+++TOTAL_NUM_OF_JOBS_FAILED="$TOTAL_NUM_OF_JOBS_FAILED | tee -a PIDS.log


         TOTAL_EXECUTED_NUM_OF_JOBS=`expr $CURRENT_NUM_OF_JOBS + $TOTAL_NUM_OF_JOBS_COMPLETED`
       
         if [ $CURRENT_NUM_OF_JOBS -le $MAX_CONCURRENT_NUM_OF_JOBS ]\
            &&\
            [ $TOTAL_EXECUTED_NUM_OF_JOBS -lt $TOTAL_NUM_OF_JOBS ]
         then

            LOGFILE=${LOGFILE}_${NETSIM_HOSTS_ARRAY[$(($COUNT -1))]}.log

            echo "***************************" >> $LOGFILE
            echo "*SERVER=${NETSIM_HOSTS_ARRAY[$(($COUNT - 1))]}*" >> $LOGFILE
            echo "***************************" >> $LOGFILE   

            #( ./someScript.sh $X $Y $Z 2>&1 ) | tee -a $LOGFILE &
            #( ./backup_createSimulationIPParallel.sh $SIM $COUNT $ENV ) >> ${LOGFILE}_${NETSIM_HOSTS_ARRAY[$(($COUNT -1))]}.log 2>&1 &
            (./ERICTAFenmnisimdep_CXP9031884/src/main/resources/scripts/simdep/ext/jenkins/applyTLS.sh -n $nssRelease -s $simdepRelease -t $serverType -i $ID_for_server -h "$serverName") >> ${LOGFILE} 2>&1 &
            #sleep $(($RANDOM / 10000)) &
            scriptBGP=$!
            PID=$scriptBGP
            PIDS="$PIDS $scriptBGP"
            allBGP="$allBGP $scriptBGP"
            
            echo "...$COUNT=$SIM PID=$scriptBGP is running" | tee -a PIDS.log
            BGP_OUTPUT="$COUNT=${NETSIM_HOSTS_ARRAY[$(($COUNT - 1))]} PID=$scriptBGP" 
            BGP_OUTPUT_ARRAY[scriptBGP]=$BGP_OUTPUT
         
            CURRENT_NUM_OF_JOBS=$(($CURRENT_NUM_OF_JOBS + 1)) 
            COUNT=`expr $COUNT + 1`
            echo "+++CURRENT_NUM_OF_JOBS="$CURRENT_NUM_OF_JOBS | tee -a PIDS.log
            set -- "$@" "$PID"
          fi  
        fi

        if [ $TOTAL_NUM_OF_JOBS_COMPLETED -eq $TOTAL_NUM_OF_JOBS ]
        then
           break 2
        fi
        sleep 5
      done

      PIDS=`echo "$@"`
    done
fi
echo ""
#wait "$allBGP"
#while s=`ps -p $PID -o s=` && [[ "$s" && "$s" != 'Z' ]]; do
#    sleep 1
#done

#while kill -0 $allBGP 2> /dev/null; do sleep 1; done;
#for pidx in $allBGP
#do
#	while pgrep -u root $pidx > /dev/null; do sleep 1; done
#done

#echo "---PLEASE WAIT UNTIL ALL SCRIPTS ARE FINISHED SUCCESFULLY----" 

echo ""| tee -a $LOGFILE
echo " ***************************************" | tee -a $LOGFILE
echo " *    ALL JOBS ARE COMPLETED           *" | tee -a $LOGFILE
echo " ***************************************" | tee -a $LOGFILE
echo ""| tee -a $LOGFILE

COUNT=1
while [ "$COUNT" -le "$TOTAL_NUM_OF_JOBS" ]
do
    echo "LOGS:$COUNT"
    cat ${LOGFILE_BASE}_${NETSIM_HOSTS_ARRAY[$(($COUNT -1))]}.log
    COUNT=`expr $COUNT + 1`
done

echo " ***************************************"  
echo " *    SUMMARY OF ALL COMPLETED JOBS    *"  
echo " ***************************************" 
echo "+++TOTAL_NUM_OF_JOBS_COMPLETED="$TOTAL_NUM_OF_JOBS_COMPLETED 
echo "+++TOTAL_NUM_OF_JOBS_LEFT="$TOTAL_NUM_OF_JOBS_LEFT 
echo "+++TOTAL_NUM_OF_JOBS_FAILED="$TOTAL_NUM_OF_JOBS_FAILED 

if [ $TOTAL_NUM_OF_JOBS_FAILED -ne 0 ]
then
    echo "FAILED: See logs for failed ones, and reconfigure job to run against failed ones only"
    exit -1
fi
