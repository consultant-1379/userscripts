#!/usr/bin/perl

use strict;
use warnings;

#my $count=177;
#my $count=200;
my $count=201;
my $specialArrayString="1:63,21;64:175,16;176:200,5";


my $intraRelationDistributionList ="1:53,9918;54:94,7590;95:103,18124;104:104,30444;105:105,48402;106:106,63436";
my $interRelationDistributionList ="1:104,3628;105:105,3001;106:106,1635";
my $externalRelationDistributionList ="1:65,3240;66:106,0";


my @result = ($specialArrayString =~ m/(\d+)/g);
#print "result="."@result"."\n";


my $mystring = "[2004/04/13] The date of this article.";
my @myarray = ($mystring =~ m/(\d+)/g);
#print join(",", @myarray);
#print "@myarray";


#print "\n";

my $numOfRelation = getItemForSelectedRange($count, $specialArrayString);
#print "numOfRelation=$numOfRelation\n"; 

my $numOfItems  = ($specialArrayString=~ tr/;//) + 1; 
#print "numOfItems=$numOfItems\n";
#print $specialArrayString."\n";

my @resultArray=("RNC01,Intra,123,89","RNC02,Inter,200,200");

my $rncName="RNC03";
my $requiredNumber=123;
my $total_Num_Of_Inter_Relation_Per_Rnc=100;
my $value ="$rncName,Inter,$requiredNumber,$total_Num_Of_Inter_Relation_Per_Rnc";
push(@resultArray, $value);

my $arrayCount=0;
foreach my $value (@resultArray){
   my $rncName;
   my $type;
   my $required;
   my $real;
   ($rncName, $type, $required, $real) = split(/,/, $value); 

  print "\UrncName=$rncName type=$type required=$required real=$real\n";
}




my $string="SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=RNC01-1-1";
my @outputArray = split(/,/, $string);
my $printableUtarnCell = $outputArray[5];
#print "printableUtarnCell=$printableUtarnCell\n";



sub getItemForSelectedRange { # COUNT SPECIALARRAYSTRING
  my $count = shift;
  my $specialArrayString = shift;
  my $numOfItems  = ($specialArrayString =~ tr/;//) + 1; 

  my $itemCounter=1; 
  foreach my $items (split/;/, $specialArrayString){
    #print $items."\n";
    my @itemsArray = ($items =~ m/(\d+)/g);
    #print "itemsArray="."@itemsArray"."\n";
    my $from = $itemsArray[0];
    my $to = $itemsArray[1];
    my $item = $itemsArray[2];
    #print "From=$from To=$to item=$item\n"

    if (($count >= $from) && ($count <= $to)){
      return $item;
      last;
     } elsif ( $itemCounter == $numOfItems ){
      return 0; 
      last;
     } 
     $itemCounter++; 
  }
}
