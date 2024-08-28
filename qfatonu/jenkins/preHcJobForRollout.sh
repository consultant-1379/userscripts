#!/bin/bashXY

# NOTE: This script is not meant to run standalone
#  It requires certain setup on Jenkins
#  Saved here to no to lose it

# powered by Fatih Onur
#get MS IP, so that it can be used by all build steps

echo "clusterId=$clusterId" > envVariables

msip=`wget -q -O - --no-check-certificate "https://cifwk-oss.lmera.ericsson.se/generateTAFHostPropertiesJSON/?clusterId=${clusterId}&tunnel=true" | awk -F',' '{print $1}' | awk -F':' '{print $2}' | sed -e "s/\"//g" -e "s/ //g"`
echo msip=${msip} >> envVariables
#echo "msip=${msip}"

netsims=`wget -q -O - --no-check-certificate "https://cifwk-oss.lmera.ericsson.se/generateTAFHostPropertiesJSON/?clusterId=${clusterId}&tunnel=true" | grep -oh "\w*ieatnetsim\w*-\w*"`
if [ ! -z "$serverName_4" ]; then
  netsims="${serverName_1} ${serverName_2} ${serverName_3} ${serverName_4} ${serverName_5} ${serverName_6} ${serverName_7} ${serverName_8} ${serverName_9}"
elif [ ! -z "$serverName_2" ]; then
  netsims="${serverName_1} ${serverName_2} ${serverName_3}"
else
 netsims="${serverName_1} "
fi
echo netsims=${netsims} >> envVariables


# powered by Fatih Onur
echo
echo -e "\033[1;32m***************CHECKING CORRECT NUMBER OF NETSIM BOX********************************\033[0m"

if [[ "$mediaArtifactName" == *"_5K"* ]]; then
  netsimUniqSize=3
elif [[ "$mediaArtifactName" == *"15K"* ]]; then
  netsimUniqSize=9
else   
 netsimUniqSize=1
fi

uniqNetsims=`echo $netsims | xargs -n 1 | sort -u | wc -l`


if [[ "$uniqNetsims" -eq 1 ]]; then
  echo "INFO: Netsim boxes are OK"
elif [[ "$uniqNetsims" -ne "$netsimUniqSize" ]]; then
  echo "ERROR: You have to have $netsimUniqSize uniq netsim box in order to use this job"
  exit -1
else
  echo "INFO: Netsim boxes are OK"
fi
  

#!/bin/bash +x
echo
echo -e "\033[1;32m***************SOFTWARE DIRECTORY SHOULDN'T BE OVER 70%********************************\033[0m"
echo -e "\033[1;32m***************PLEASE CHECK % BELOW********************************\033[0m"
software=$(ssh -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no root@$msip "df -kh /software")
echo ${software}
echo

#!/bin/bash +x
echo
echo -e "\033[1;32m***************CHECKING HEALTH OF LITP********************************\033[0m"
ssh -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no root@$msip "/opt/ericsson/enminst/bin/litp_healthcheck.sh"
echo

#!/bin/bash +x
echo -e "\033[1;32m***************CHECKING BLADES AREN'T IN FROZEN STATE********************************\033[0m"
ssh -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no root@$msip "/opt/ericsson/enminst/bin/enm_healthcheck.sh --action system_service_healthcheck --verbose"

#!/bin/bash +x
echo
echo -e "\033[1;32m***************CHECKING SERVICE GROUPS ARE IN GOOD STATE IN ENM********************************\033[0m"
ssh -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no root@$msip "/opt/ericsson/enminst/bin/vcs.bsh --groups"

#!/bin/bash +x
echo
echo -e "\033[1;32m***************CHECKING StatisticalSubscription********************************\033[0m"
ssh -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no root@$msip "/opt/ericsson/enmutils/bin/cli_app 'cmedit get * StatisticalSubscription'" | tee $LOGFILE 

#!/bin/bash +x
echo
echo -e "\033[1;32m***************CHECKING CellTraceSubscription********************************\033[0m"
ssh -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no root@$msip "/opt/ericsson/enmutils/bin/cli_app 'cmedit get * CellTraceSubscription'" | tee -a $LOGFILE 

#!/bin/bash +x
echo
echo -e "\033[1;32m***************CHECKING UETraceSubscription********************************\033[0m"
ssh -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no root@$msip "/opt/ericsson/enmutils/bin/./cli_app 'cmedit get * UETraceSubscription'" | tee -a $LOGFILE 


# powered by Fatih Onur
echo "\033[1;32m***************ANALYSING LOGS*********************************\033[0m"
#cat logs
cat $LOGFILE
INSTANCES=`grep " instance(s)" $LOGFILE | cut -d ' ' -f 1`
echo "INSTANCES=$INSTANCES"
for INSTANCE in $INSTANCES
do
    if [[ $INSTANCE -ne 0 ]]
    then
      echo "FAILED" exit -1 
    fi
done

# powered by Fatih Onur
echo "\033[1;32m***************NETSIM SERVER PRE-HC*********************************\033[0m"
scriptLink="https://arm901-eiffel004.athtem.eei.ericsson.se:8443/nexus/content/repositories/simnet/com/ericsson/simnet/pre_hc/checkServerExecuter.sh.txt"
curl -sSL $scriptLink | bash +x

