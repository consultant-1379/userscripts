#!/bin/sh

if [ "$#" -ne 1  ]
then
 echo
 echo "Usage: $0 <rnc num>"
 echo
 echo "Example: $0 9"
 echo
 exit 1
fi

if [ "$1" -le 9 ]
then
RNCNAME="RNC0"$1
RNCCOUNT="0"$1
else
RNCNAME="RNC"$1
RNCCOUNT=$1
fi



echo "If "$RNCNAME" is connected and synchronized then the about should be"
echo
echo " [1] connectionStatus (enum SupportedConnStatus r): 2"
echo " [2] mirrorMIBsynchStatus (enum SupportedMirrorMibSynchStatus r): 3"
echo " [3] mirrorMIBupdateStatus (enum SupportedMirrorMibUpdateStatus nn): 2"
echo
echo "At the moment "$RNCNAME" looks like this"
/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s Seg_masterservice_CS la SubNetwork=ONRM_RootMo_R,SubNetwork=${RNCNAME},MeContext=${RNCNAME} connectionStatus mirrorMIBsynchStatus mirrorMIBupdateStatus
echo
echo "or check the yin yang files in /var/opt/ericsson/nms_umts_cms_nead_seg"
echo
echo "eg: tail -100f  /var/opt/ericsson/nms_umts_cms_nead_seg/neadStatus.log.yang  or yin | grep -i nodes"
echo
echo "or log into UAS and launch ONE Gui and go to common explorer application (cex)"



