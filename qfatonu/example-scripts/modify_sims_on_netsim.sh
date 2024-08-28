#!/bin/sh -x

if [ $# -ne 1 ]; then
echo "enter oss server or name of netsim"
exit
fi

WDIR=`dirname $0`
. ${WDIR}/get_config_file.sh $@

for SERVER in $SERVERS
  do
    echo "rsh -l netsim ${SERVER} ./modify_sim.sh"
    rsh -l netsim ${SERVER} ./modify_sim.sh | sed "s/^/${SERVER}: /" &
  done
