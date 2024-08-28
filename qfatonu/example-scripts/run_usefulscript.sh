#!/bin/sh

if [ $# -ne 2 ]; then
echo "enter oss server or name of netsim and name of the script to be run"
exit
fi

WDIR=`dirname $0`
. ${WDIR}/get_config_file.sh $@

for SERVER in $SERVERS
  do
    echo "rsh -l netsim ${SERVER} ./${2}"
    rsh -l netsim ${SERVER} ./${2} | sed "s/^/${SERVER}: /" &
  done
echo "Finished"
