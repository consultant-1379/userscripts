#!/bin/sh

# Created by  : qfatonu
# Created in  : 08 Mar 10
##
### VERSION HISTORY
# Ver1        : Created for WRAN deployment o.10.2.4, req id:3425
# Purpose     :
# Description :
# Date        : 08.03.2010
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


TIMEOUT=9
rsh -l netsim  netsimlin144-inst *  & > /dev/null 2>&1
PID=$!
echo "PID:"$PID


# wait for the specified number of seconds for scp to complete
# if the timeout is exceeded, kill the process and move on to the next box

    while [ $TIMEOUT -gt 0 ]
    do
      echo "TIMEOUT="$TIMEOUT
      /bin/ps -p $PID > /dev/null 2>&1
      #echo "\$?="$?
      if [[ $? -ne 0 ]]
      then
        break
       echo "go"
      fi
      TIMEOUT=$(($TIMEOUT - 1))
      sleep 1
    done

# if the timeout reaches 0, then the process was killed. Report something.

    if [ $TIMEOUT -le 0 ]
    then
      echo "ERROR: Unable to connect to server ($PROGNAME)" # >> $SVRPATH/config.status
      # chmod 664 $SVRPATH/config.status
      kill -KILL $PID
    fi
