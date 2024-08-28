#!/usr/bin/perl

use strict;
use warnings;

my $total_Num_Of_Intra_Relation_For_Network=0;
my $total_Num_Of_Inter_Relation_For_Network=0;
my $total_Num_Of_External_Relation_For_Network=0;
my $total_Num_Of_UtranCell_Relation_For_Network=0;
  my $total_Num_Of_Intra_Relation_Per_Rnc=0;
  my $total_Num_Of_Inter_Relation_Per_Rnc=0;
  my $total_Num_Of_External_Relation_Per_Rnc=0;


my $count_For_Rnc;
my $rncName;
my $utranCells;
my @utranCells_Array;
my $separator=";";

# CONFIGURABLE PART
my $start=1;
#my $end=1;
my $end=106;

my $utranCellsFile="UtranCellsSorted.txt";
my $utranCellRelationsFileBase = "UtranCellRelations_"; 
my $utranCellRelatiosDir = "relations";

$count_For_Rnc=$start;
while ($count_For_Rnc <= $end)
{

  $rncName=getRncName($count_For_Rnc);

  print "####################################################\n";
  print " $rncName utran relations\n";
  print "####################################################\n";

  my $total_Num_Of_Intra_Relation_Per_Rnc=0;
  my $total_Num_Of_Inter_Relation_Per_Rnc=0;
  my $total_Num_Of_External_Relation_Per_Rnc=0;


  my $utranCellRelationsFile=$utranCellRelationsFileBase.$rncName.".txt";
  #print $utranCellRelationsFile."\n";
  #exit 1;

  @utranCells_Array =`grep $rncName, $utranCellsFile`;
  #foreach my $value (@utranCells_Array){ print $value; }
  #exit 1;
 
  my $count_For_Total_Cell_Per_Rnc=1; 
  foreach my $utranCell (@utranCells_Array){
    #print $utranCell;
    #exit 1;

    chomp $utranCell;
    print "####################################################\n";
    print " $rncName-COUNT=$count_For_Total_Cell_Per_Rnc $utranCell\n";
    print "####################################################\n";
    #exit 1;

    my @utranCell_Relations_Per_Cell_Array;
    @utranCell_Relations_Per_Cell_Array=`grep $utranCell, $utranCellRelatiosDir/$utranCellRelationsFile`;
    @utranCell_Relations_Per_Cell_Array = sort {lowest($a) <=> lowest($b)} @utranCell_Relations_Per_Cell_Array;
    #foreach my $value (@utranCell_Relations_Per_Cell_Array){ print $value; }
    #exit 1;
    
    my $num_Of_Intra_Relation_Per_Cell=0;
    my $num_Of_Inter_Relation_Per_Cell=0;
    my $num_Of_External_Relation_Per_Cell=0;

    foreach my $line (@utranCell_Relations_Per_Cell_Array){
      if ( $line =~ /$utranCell/ ){
        #print $line."\n";
       
        my @tmpLines = split (/UtranRelation=/, $line);
        my $relationId= $tmpLines[1];
        #print "relationId=$relationId\n";
       
        if ( $relationId <= 31 ){
           $num_Of_Intra_Relation_Per_Cell=$num_Of_Intra_Relation_Per_Cell + 1;
        }
        elsif ( ($relationId >= 32) && ( $relationId <= 60 )){
           $num_Of_Inter_Relation_Per_Cell=$num_Of_Inter_Relation_Per_Cell + 1;
        }
        elsif ( $relationId >= 61 ){
           $num_Of_External_Relation_Per_Cell=$num_Of_External_Relation_Per_Cell + 1;
        } 
      }
      
     #
     #exit 1;

    }
     print "num_Of_Intra_Relation_Per_Cell=$num_Of_Intra_Relation_Per_Cell\n";
     print "num_Of_Inter_Relation_Per_Cell=$num_Of_Inter_Relation_Per_Cell\n";
     print "num_Of_External_Relation_Per_Cell=$num_Of_External_Relation_Per_Cell\n";
     #exit 1;

     $total_Num_Of_Intra_Relation_Per_Rnc+= $num_Of_Intra_Relation_Per_Cell;
     $total_Num_Of_Inter_Relation_Per_Rnc+= $num_Of_Inter_Relation_Per_Cell;
     $total_Num_Of_External_Relation_Per_Rnc+= $num_Of_External_Relation_Per_Cell;


    # TEST PURPOSES ONLY
    #if ($count_For_Total_Cell_Per_Rnc == 3){
    # exit 1;
    # last;
    #}
    $count_For_Total_Cell_Per_Rnc++;
  }

  print "\n";
  print "-----------------------------------------\n";
  print "total_Num_Of_Intra_Relation_Per_Rnc($rncName)=$total_Num_Of_Intra_Relation_Per_Rnc"."\n";
  print "total_Num_Of_Inter_Relation_Per_Rnc($rncName)=$total_Num_Of_Inter_Relation_Per_Rnc"."\n";
  print "total_Num_Of_External_Relation_Per_Rnc($rncName)=$total_Num_Of_External_Relation_Per_Rnc"."\n";
  print "-----------------------------------------\n";

  $total_Num_Of_Intra_Relation_For_Network+= $total_Num_Of_Intra_Relation_Per_Rnc;
  $total_Num_Of_Inter_Relation_For_Network+= $total_Num_Of_Inter_Relation_Per_Rnc;
  $total_Num_Of_External_Relation_For_Network+= $total_Num_Of_External_Relation_Per_Rnc;

  $count_For_Rnc++;
}

$total_Num_Of_UtranCell_Relation_For_Network+= $total_Num_Of_Intra_Relation_For_Network;
$total_Num_Of_UtranCell_Relation_For_Network+= $total_Num_Of_Inter_Relation_For_Network;
$total_Num_Of_UtranCell_Relation_For_Network+= $total_Num_Of_External_Relation_For_Network;

  print "\n";
  print "####################################################################################\n";
  print " UTRAN RELATION NETWORK REPORT START FROM ".getRncName($start)." TO ".getRncName($end)."\n";
  print "####################################################################################\n";
  print "total_Num_Of_Intra_Relation_For_Network=$total_Num_Of_Intra_Relation_For_Network"."\n";
  print "total_Num_Of_Inter_Relation_For_Network=$total_Num_Of_Inter_Relation_For_Network"."\n";
  print "total_Num_Of_External_Relation_For_Network=$total_Num_Of_External_Relation_For_Network"."\n";
  print "total_Num_Of_UtranCell_Relation_For_Network=$total_Num_Of_UtranCell_Relation_For_Network"."\n";


sub lowest { # UTRANCELLRELATIONSTRING
  my @number1 = split(/UtranRelation=/,shift);
  return $number1[1];
}

sub getRncName { # COUNT 
  my $count= shift;
  my $rncName;

  if($count <= 9){ 
    $rncName="RNC0".$count;
  }
  else{
    $rncName="RNC".$count;
  }
  #print $rncName;
  return $rncName;
}

 


