#!/bin/sh

# Created by..: Fatih ONUR 
# Date........: 17.02.09-Tuesday 
# Version.....: v1
# Purpose.....: To install the new Netsim License among many machines in one go.

if [ "$#" -ne 2  ]
then
cat<<HELP

NOTE: Ensure that script and licence file are located in the same directory 

Usage: $0 start <licence_file>

Example: $0 start eei_special_jumpstart.337.3.netsim6_1_licence.tar.Z

HELP
 exit 1
fi

LICENSE=$2

echo ""
echo "NETSIM LICENCE UPGRADE IS STARTING"
echo ""

SERVERLIST="netsimlin252 netsimlin254 "

for SERVER in $SERVERLIST
do
    echo '****************************************************'
    echo "$SERVER is upgrading to new licence"
    echo '****************************************************'

    /usr/bin/rcp $LICENSE $SERVER:/netsim/inst/eei_special_jumpstart.337.3.netsim6_1_licence.tar.Z
    /usr/bin/rsh -l netsim $SERVER echo ".install license "$LICENSE" | /netsim/inst/netsim_shell"
    /usr/bin/rsh -l netsim $SERVER echo ".e 'intcmdlib:delete_stream_field(importedlicenses).' | /netsim/inst/netsim_shell"

    echo '****************************************************'
    echo "$SERVER is upgraded to new licence"
    echo '****************************************************'
    echo ""
done

echo "NETSIM LICENCE UPGRADE FINISHED"
 echo ""
