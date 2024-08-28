#!/bin/sh

# Created by..: Fatih ONUR
# Date........: 17.02.09-Tuesday
# Version.....: v1
# Purpose.....: To install the new Netsim License among many machines in one go.
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Created by..: Fatih ONUR
# Date........: 01.28.10-Monday
# Version.....: v2
# Purpose.....: To install the new Netsim License among many machines in one go for COMNIF environment.

if [ "$#" -ne 2  ]
then
cat<<HELP

NOTE: Ensure that script and license file are located in the same directory 
      Insert license file_name manually into script

Usage: $0 start <license_file>

Example: $0 start eei_special_jumpstart.337.3.netsim6_1_licence.tar.Z

HELP
 exit 1
fi

LICENSE=$2
#LICENSE=/.Fatih/Licenses/R21_Licences/eei_special_jumpstart.337.4.netsim6_1_licence.tar.Z


echo ""
echo "NETSIM LICENSE UPGRADE IS STARTING"
echo ""

# Specially made for COMNIF enviroment
# For other srevers use rcp to copy licens onto machine and delete -inst suffix
SERVERLIST="netsimlin144 netsimlin146 netsimlin147 netsimlin149 netsimlin150 netsimlin151 netsimlin152 netsimlin153 netsimlin156 netsimlin187 netsimlin186  netsimlin129 netsimlin168"

for SERVER in $SERVERLIST
do
    echo '****************************************************'
    echo "$SERVER is upgrading to new license"
    echo '****************************************************'
   
    # wget was used before due to permission denied but rcp still works
       /usr/bin/rsh -l netsim $SERVER-inst "wget -nc http://atrclin2.athtem.eei.ericsson.se/TCM3/NetsimSite/Include/$LICENSE -P/netsim/inst/"
    # rcp $LICENSE netsim@$SERVER:/netsim/inst/
    /usr/bin/rsh -l netsim -n $SERVER-inst echo ".install license "$LICENSE" | /netsim/inst/netsim_shell"
    /usr/bin/rsh -l netsim -n $SERVER-inst echo ".e 'intcmdlib:delete_stream_field(importedlicenses).' | /netsim/inst/netsim_shell"

    echo '****************************************************'
    echo "$SERVER is upgraded to new license"
    echo '****************************************************'
    echo ""
done

echo "NETSIM LICENSE UPGRADE FINISHED"
 echo ""
