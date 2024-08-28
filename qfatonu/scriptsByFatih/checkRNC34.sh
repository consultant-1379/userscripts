#!/bin/sh

echo "If RNC34 is connected and synchronized then the about should be"
echo
echo " [1] connectionStatus (enum SupportedConnStatus r): 2"
echo " [2] mirrorMIBsynchStatus (enum SupportedMirrorMibSynchStatus r): 3"
echo " [3] mirrorMIBupdateStatus (enum SupportedMirrorMibUpdateStatus nn): 2"
echo
echo "At the moment RNC34 looks like this"
/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s Seg_masterservice_CS la SubNetwork=ONRM_RootMo_R,SubNetwork=RNC34,MeContext=RNC34 connectionStatus mirrorMIBsynchStatus mirrorMIBupdateStatus
echo
echo "or check the yin yang files in /var/opt/ericsson/nms_umts_cms_nead_seg"
echo
echo "eg: tail -100f  /var/opt/ericsson/nms_umts_cms_nead_seg/neadStatus.log.yang  or yin | grep -i nodes"
echo
echo "or log into UAS and launch ONE Gui and go to common explorer application (cex)"



