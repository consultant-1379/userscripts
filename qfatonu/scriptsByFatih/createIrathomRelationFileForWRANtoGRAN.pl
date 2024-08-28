#!/usr/bin/perl
# Created by  : Fatih ONUR
# Created in  : 24 Aug 2012
##
### VERSION HISTORY
# Ver1        : Created for Teji in 13A GRAN IRATHOM design
# Purpose     : Create relations file to pass an input to GRAN IRATHOM sripts
# Description :
# Date        : 10 02 2010
# Who         : Fatih ONUR


#### The number of relations that Gran and Utran Cells will have against each other
$division=13;

#### The number of totalcells that each RNC contains
$cellRange=320;

#### The last rncId that GranCell should have relation
$numOfRNC=39;

#### The last cellId that GranCell should have relation
$stopCell=12303;

#### The cellId for the loop to end
$endCell= ( $numOfRNC ) * $cellRange + 1;

$uc = 1;
$rncId = 1;


#### For Gran SimId Configuration
#
$numfOfCellsGranSim_1 = 5000;
$numfOfCellsGranSim_2 = 7696;
$gsmSimId = 1;
$gsmSimId_1_Check = 0;
$gsmSimId_2_Check = 0;
$tmpLastRange_1 = 1;
$tmpLastRange_2 = 1;

for ( $y = $cellRange; $y <= $endCell; )
{ 

  $uc= 1 + (( $rncId - 1 ) * $cellRange);
  $gc= $uc;

  for ($x = $division ; $x < $cellRange; )
  {
    $count = 1;
    $tmp = $uc;

    $lastRange= $x + (( $rncId - 1 ) * $cellRange);


    #######################################################################
    # This part o code for only gsmSimId : START
    #######################################################################

    if ( ($lastRange > ($numfOfCellsGranSim_1 + 1)) && ( $tmpLastRange_1 == 1 ) ) {
       $gsmSimId_1_Check = 1;
       $tmpLastRange_1 = $lastRange;

       #print "gsmSimId_1_Check=$gsmSimId_1_Check \n";
       #print "tmpLastRange_1=$tmpLastRange_1 \n";
    }
    if ( $lastRange != $tmpLastRange_1 ){
       #print "I am inside \$lastRange != \$tmpLastRange_1 \n";
       $gsmSimId_1_Check = 0;
       #print "gsmSimId_1_Check=$gsmSimId_1_Check \n";
    } 
    if ( $gsmSimId_1_Check ){
       $gsmSimId = $gsmSimId + 1;
    }

   if ( ($lastRange > ($numfOfCellsGranSim_1 + $numfOfCellsGranSim_2 + 1)) && ( $tmpLastRange_2 == 1 ) ) {
       $gsmSimId_2_Check = 1;
       $tmpLastRange_2 = $lastRange;

       #print "gsmSimId_1_Check=$gsmSimId_1_Check \n";
       #print "tmpLastRange_2=$tmpLastRange \n";
    }
    if ( $lastRange != $tmpLastRange_2 ){
       #print "I am inside \$lastRange != \$tmpLastRange_2 \n";
       $gsmSimId_2_Check = 0;
       #print "gsmSimId_1_Check=$gsmSimId_1_Check \n";
    }
    if ( $gsmSimId_2_Check ){
       $gsmSimId = $gsmSimId + 1;
    }

    #print "In any case: gsmSimId_1_Check=$gsmSimId_1_Check \n";
    #print "In any case: tmpLastRange=$tmpLastRange \n";

    #######################################################################
    # This part o code for only gsmSimId : START
    #######################################################################
   
   
    #print "last range $lastRange \n";

    while ($count <= 13)
    {

      if (($uc != $cellRange ) && ($uc <= $stopCell ) ){
         print "UtraCell $uc has (wran sim $rncId) GsmRelations to ExtGsmCells $tmp-$lastRange (gsm sim $gsmSimId) \n"; 
      }

      $count = $count + 1;
      $uc = $uc + 1;
    }
    $x = $x + $division;
  }


  $y= $y + $cellRange;

  $rncId= $rncId + 1; 
}


