#!/usr/bin/perl

use strict;
use warnings;

#my $NUM_OF_INTER_RELATION_PER_CELL=0;
my $TOTAL_NUM_OF_INTRA_RELATION_PER_RNC=0;
my $TOTAL_NUM_OF_INTER_RELATION_PER_RNC=0;
my $TOTAL_NUM_OF_EXTERNAL_RELATION_PER_RNC=0;

my $TOTAL_NUM_OF_INTRA_RELATION_FOR_NETWORK=0;
my $TOTAL_NUM_OF_INTER_RELATION_FOR_NETWORK=0;
my $TOTAL_NUM_OF_EXTERNAL_RELATION_FOR_NETWORK=0;

#my $filename1="UtranCellsSorted.txt";
#my $filename2="UtranRelations.txt";
#my $filename2="UtranRelations_RNC01.txt";
#open(my $fh1, '<', $filename1) || die "Couldn't open file $filename1: $!";
#open(my $fh2, '<', $filename2) || die "Couldn't open file $filename2: $!";

my $utranCellsFile="UtranCellsSorted.txt";
my $utranCellRelationsFileBase = "UtranCellRelations_"; 
my $utranCellRelatiosDir = "relations";

#my @all_Utran_Relations_Array;

my $START=1;
my $END=1;
#my $END=106;
my $COUNT;
  my $RNCNAME;
  my $RNCCOUNT;
  my $UTRANCELLS;
my @utranCells_Array;
my $separator=";";


$COUNT=$START;
while ($COUNT <= $END)
{

  if ($COUNT <= 9) 
  {
    $RNCNAME="RNC0".$COUNT;
    $RNCCOUNT="0".$COUNT;
  }
  else
  {
    $RNCNAME="RNC".$COUNT;
    $RNCCOUNT=$COUNT;
  } 

  print "####################################################\n";
  print " $RNCNAME utran relations\n";
  print "####################################################\n";

  my $TOTAL_NUM_OF_INTRA_RELATION_PER_RNC=0;
  my $TOTAL_NUM_OF_INTER_RELATION_PER_RNC=0;
  my $TOTAL_NUM_OF_EXTERNAL_RELATION_PER_RNC=0;


  my $utranCellRelationsFile=$utranCellRelationsFileBase.$RNCNAME.".txt";
  #print $utranCellRelationsFile."\n";
  #exit 1;

  @utranCells_Array =`grep $RNCNAME, $utranCellsFile`;
  #foreach my $value (@utranCells_Array){ print $value; }
  #exit 1;
 
  my $count=1; 
  foreach my $utranCell (@utranCells_Array){
    #my @tmpUtranCell = split (/$separator/, $utranCell);
    #$utranCell = $tmpUtranCell[1];

    #print $utranCell;
    #exit 1;

    chomp $utranCell;
    print "####################################################\n";
    print " $RNCNAME-COUNT=$count $utranCell\n";
    print "####################################################\n";

    #exit 1;

    my @utranCell_Relations_Per_Cell_Array;
    @utranCell_Relations_Per_Cell_Array=`grep $utranCell $utranCellRelatiosDir/$utranCellRelationsFile`;
    @utranCell_Relations_Per_Cell_Array = sort {lowest($a) <=> lowest($b)} @utranCell_Relations_Per_Cell_Array;
    #foreach my $value (@utranCell_Relations_Per_Cell_Array){ print $value; }
    #exit 1;

    
    my $NUM_OF_INTRA_RELATION_PER_CELL=0;
    my $NUM_OF_INTER_RELATION_PER_CELL=0;
    my $NUM_OF_EXTERNAL_RELATION_PER_CELL=0;
    #foreach my $line (@all_Utran_Relations_Array){

    foreach my $line (@utranCell_Relations_Per_Cell_Array){
      if ( $line =~ /$utranCell/ ){
        #print $line."\n";
       
        my @tmpLines = split (/UtranRelation=/, $line);
        my $RELATIONID= $tmpLines[1];
        #print "RELATIONID=$RELATIONID\n";
       
        if ( $RELATIONID <= 31 ){
           $NUM_OF_INTRA_RELATION_PER_CELL=$NUM_OF_INTRA_RELATION_PER_CELL + 1;
        }
        elsif ( ($RELATIONID >= 32) && ( $RELATIONID <= 60 )){
           $NUM_OF_INTER_RELATION_PER_CELL=$NUM_OF_INTER_RELATION_PER_CELL + 1;
        }
        elsif ( $RELATIONID >= 61 ){
           $NUM_OF_EXTERNAL_RELATION_PER_CELL=$NUM_OF_EXTERNAL_RELATION_PER_CELL + 1;
        } 
      }
      
     #
     #exit 1;

    }
     print "NUM_OF_INTRA_RELATION_PER_CELL=$NUM_OF_INTRA_RELATION_PER_CELL\n";
     print "NUM_OF_INTER_RELATION_PER_CELL=$NUM_OF_INTER_RELATION_PER_CELL\n";
     print "NUM_OF_EXTERNAL_RELATION_PER_CELL=$NUM_OF_EXTERNAL_RELATION_PER_CELL\n";
     #exit 1;

     $TOTAL_NUM_OF_INTRA_RELATION_PER_RNC=$TOTAL_NUM_OF_INTRA_RELATION_PER_RNC + $NUM_OF_INTRA_RELATION_PER_CELL;
     $TOTAL_NUM_OF_INTER_RELATION_PER_RNC=$TOTAL_NUM_OF_INTER_RELATION_PER_RNC + $NUM_OF_INTER_RELATION_PER_CELL;
     $TOTAL_NUM_OF_EXTERNAL_RELATION_PER_RNC=$TOTAL_NUM_OF_EXTERNAL_RELATION_PER_RNC + $NUM_OF_EXTERNAL_RELATION_PER_CELL;


    #@utranCell_Relations_Per_Cell_Array = sort {lowest($a) <=> lowest($b)} @utranCell_Relations_Per_Cell_Array;
    #foreach my $value (@utranCell_Relations_Per_Cell_Array){ print $value; }

    if ($count == 32000000){
    #if ($count == 320){
    #if ($count == 3){
     #exit 1;
     last;
    }
    $count++;
  }

  print "\n";
  print "-----------------------------------------\n";
  print "TOTAL_NUM_OF_INTRA_RELATION_PER_RNC($RNCNAME)=$TOTAL_NUM_OF_INTRA_RELATION_PER_RNC"."\n";
  print "TOTAL_NUM_OF_INTER_RELATION_PER_RNC($RNCNAME)=$TOTAL_NUM_OF_INTER_RELATION_PER_RNC"."\n";
  print "TOTAL_NUM_OF_EXTERNAL_RELATION_PER_RNC($RNCNAME)=$TOTAL_NUM_OF_EXTERNAL_RELATION_PER_RNC"."\n";
  print "-----------------------------------------\n";

  $TOTAL_NUM_OF_INTRA_RELATION_FOR_NETWORK=$TOTAL_NUM_OF_INTRA_RELATION_FOR_NETWORK + $TOTAL_NUM_OF_INTRA_RELATION_PER_RNC;
  $TOTAL_NUM_OF_INTER_RELATION_FOR_NETWORK=$TOTAL_NUM_OF_INTER_RELATION_FOR_NETWORK + $TOTAL_NUM_OF_INTER_RELATION_PER_RNC;
  $TOTAL_NUM_OF_EXTERNAL_RELATION_FOR_NETWORK=$TOTAL_NUM_OF_EXTERNAL_RELATION_FOR_NETWORK + $TOTAL_NUM_OF_EXTERNAL_RELATION_PER_RNC;

  $COUNT++;
}

  print "\n";
  print "####################################################################################\n";
  print " UTRAN RELATION NETWORK REPORT START FROM ".getRncName($START)." TO ".getRncName($END)."\n";
  print "####################################################################################\n";
  print "TOTAL_NUM_OF_INTRA_RELATION_FOR_NETWORK=$TOTAL_NUM_OF_INTRA_RELATION_FOR_NETWORK"."\n";
  print "TOTAL_NUM_OF_INTER_RELATION_FOR_NETWORK=$TOTAL_NUM_OF_INTER_RELATION_FOR_NETWORK"."\n";
  print "TOTAL_NUM_OF_EXTERNAL_RELATION_FOR_NETWORK=$TOTAL_NUM_OF_EXTERNAL_RELATION_FOR_NETWORK"."\n";



#close $fh1;
#close $fh2;
sub lowest {
  my @number1 = split(/UtranRelation=/,shift);
  return $number1[1];
}

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

 


