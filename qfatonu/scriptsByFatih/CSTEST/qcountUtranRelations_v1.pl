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

my $filename1="file2.txt";
my $filename2="UtranRelations.txt";
open(my $fh1, '<', $filename1) || die "Couldn't open file $filename1: $!";
open(my $fh2, '<', $filename2) || die "Couldn't open file $filename2: $!";

my @all_Utran_Relations_Array;
#while ( my $line = <$fh2>){
   #print $line."\n";
#    push (@all_Utran_Relations_Array, $line);
#}
#@all_Utran_Relations_Array=<$fh2>;



my $START=1;
my $END=1;
my $COUNT;
  my $RNCNAME;
  my $RNCCOUNT;
  my $UTRANCELLS;
my @utranCells_Array;
#my @utranCell_Relations_Per_Cell_Array;
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

  while ( my $line = <$fh1>){
    if ( $line =~ /$RNCNAME/ ){
        #print $line;
        push (@utranCells_Array, $line);
    }
  } 
  #foreach my $value (@utranCells_Array){ print $value; }
 
  my $count=1; 
  foreach my $utranCell (@utranCells_Array){
    my @tmpUtranCell = split (/$separator/, $utranCell);
    $utranCell = $tmpUtranCell[1];

    #print $utranCell;
    #exit 1;

    chomp $utranCell;
    print "####################################################\n";
    print " $utranCell utran relations\n";
    print "####################################################\n";

    #exit 1;
    open(my $fh2, '<', $filename2) || die "Couldn't open file $filename2: $!";

    #while ( my $line = <$fh2>){
    my @utranCell_Relations_Per_Cell_Array;
    @utranCell_Relations_Per_Cell_Array=`grep $utranCell UtranRelations.txt`;

    my $index = 0;
    foreach my $line (@all_Utran_Relations_Array){
    #while($index <= $#all_Utran_Relations_Array){
    #  my $line = $all_Utran_Relations_Array[$index];
    
      if ( $line =~ /$utranCell/ ){
        #print $line."\n";
        push (@utranCell_Relations_Per_Cell_Array, $line);
        splice(@all_Utran_Relations_Array, $index , 1);
      } else{
        $index++;
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


