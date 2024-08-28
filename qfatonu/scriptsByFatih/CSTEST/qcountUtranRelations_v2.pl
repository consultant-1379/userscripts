#!/usr/bin/perl

use strict;
use warnings;

my $NUM_OF_INTER_RELATION_PER_CELL=0;
my $TOTAL_NUM_OF_INTRA_RELATION_PER_RNC=0;
my $TOTAL_NUM_OF_INTER_RELATION_PER_RNC=0;
my $TOTAL_NUM_OF_EXTERNAL_RELATION_PER_RNC=0;

my $TOTAL_NUM_OF_INTRA_RELATION_FOR_NETWORK=0;
my $TOTAL_NUM_OF_INTER_RELATION_FOR_NETWORK=0;
my $TOTAL_NUM_OF_EXTERNAL_RELATION_FOR_NETWORK=0;

my $filename1="UtranCellsSorted.txt";
my $filename2="UtranRelations.txt";
open(my $fh1, '<', $filename1) || die "Couldn't open file $filename1: $!";
open(my $fh2, '<', $filename2) || die "Couldn't open file $filename2: $!";

my @all_Utran_Relations_Array;

my $START=1;
my $END=1;
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

  #while ( my $line = <$fh1>){
  #  if ( $line =~ /$RNCNAME/ ){
  #      #print $line;
  #      push (@utranCells_Array, $line);
  #  }
  #} 

  @utranCells_Array =`grep $RNCNAME $filename1`;
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
    print " $utranCell utran relations\n";
    print "####################################################\n";

    #exit 1;
    open(my $fh2, '<', $filename2) || die "Couldn't open file $filename2: $!";

    my @utranCell_Relations_Per_Cell_Array;
    @utranCell_Relations_Per_Cell_Array=`grep $utranCell UtranRelations.txt`;

    my $index = 0;
    foreach my $line (@all_Utran_Relations_Array){
    
      if ( $line =~ /$utranCell/ ){
        #print $line."\n";
        push (@utranCell_Relations_Per_Cell_Array, $line);
      }
    }
    close $fh2;

    @utranCell_Relations_Per_Cell_Array = sort {lowest($a) <=> lowest($b)} @utranCell_Relations_Per_Cell_Array;
    #foreach my $value (@utranCell_Relations_Per_Cell_Array){ print $value; }

    #if ($count == 320){
    if ($count == 3){
     exit 1;
     #last;
    }
    $count++;
  }

  $COUNT++;
}



close $fh1;
#close $fh2;
sub lowest {
  my @number1 = split(/UtranRelation=/,shift);
  return $number1[1];
}


