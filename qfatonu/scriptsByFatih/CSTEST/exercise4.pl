#!/usr/bin/perl

use strict;
use warnings;

#system("php sender.php > /dev/null 2>&1 &");

sub getRncName {
  my $COUNT= shift;
  my $RNCNAME;

  if($COUNT <= 9){
    $RNCNAME="RNC0".$COUNT;
  }
  else{
    $RNCNAME="RNC".$COUNT;
  }
  #print $RNCNAME;
  return $RNCNAME;
}



#utrancellRelations_RNC01;
#UtrancellRelations_RNC01.txt;

my $tempFileName = "UtrancellRelations";
my $fileName;

foreach my $value (1..11){
  #$print $value."\n";
  #print $value;
 
  $fileName = $tempFileName."_".getRncName($value).".txt"; 
  print $fileName."\n"; 
  
}
print "\n";


