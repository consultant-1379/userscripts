#! /bin/ksh

rm -f Rncs.txt
/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s Seg_masterservice_CS lt RncFunction > Rncs.txt


# for all rncs
rncs=`cat Rncs.txt`

# or use specific number 
RNCNO=34
#rncs="SubNetwork=ONRM_RootMo_R,SubNetwork=RNC${RNCNO},MeContext=RNC${RNCNO},ManagedElement=1,RncFunction=1"

for rnc in $rncs
do
        rm -f urs.txt
	print $rnc
       	/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest -s Seg_masterservice_CS lm $rnc -f '$type_name==UtranRelation' -an adjacentCell > urs.txt
        inter=`grep adjacentCell urs.txt | grep MeContext | grep -v $rnc | wc -l`
        echo "number inter = " $inter	

        intra=`grep adjacentCell urs.txt | grep MeContext | grep $rnc | wc -l`
        external=`grep adjacentCell urs.txt | grep -v MeContext | wc -l`

        echo "number intra = " $intra	
        echo "number external = " $external
done
