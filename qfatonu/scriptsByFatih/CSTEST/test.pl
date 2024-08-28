#!/usr/bin/perl
use strict;
use warnings;


#for ($count = 10; $count >= 1; $count--) {
# 	print "$count ";
#}

open(DATA,">>file.txt") || die "Couldn't open file file.txt, $!";

# Open new file to write
#open(DATA2, ">file2.txt");
open(DATA2, ">UtranCellsSorted.txt");
open (MYFILE, 'UtranCellsWithCellId.txt');

my $count=0;

my @cellArray;
my @tempArray;
my @tempArray2;
my $separator=";";

while (<MYFILE>) {
  chomp;
  #print "$_\n";
  my $currentLine = "$_\n";
  #push(@utranCells, "$_");

  
  
# print DATA2 $currentLine;
 $count+=1;
 #print $count . "\n";

 push (@tempArray, $currentLine);
 if (($count % 2) == 0){
   #@tempArray=undef;
   #@tempArray2=undef;
   #my @tempArray;
   #my @tempArray2;
   #push (@tempArray, $currentLine);
   foreach (@tempArray) {$_='' unless defined $_; };
   @tempArray2 = split(' ',"@tempArray"); 
   #print "tempArray2="."@tempArray2"."\n";
   #print "tempArray2[7]="."$tempArray2[7]"."\n";
   push (@cellArray,$tempArray2[7].$separator.$tempArray2[0]."\n");
   #push (@cellArray,$tempArray2[7]);
   #print "\@tempArray="."@tempArray"."\n";
   #print scalar(@tempArray)."\n";
   @tempArray=undef;
   @tempArray2=undef;
 }

 if ($count == 140000){
   #exit 1
   last;
 }

}
close (MYFILE); 
close (DATA);

#print "*********************************\n";
#print "cellArray[2]=".$cellArray[2];

#print chomp("@cellArray");

#print "@cellArray";
#print "@cellArray";

@cellArray= sort {lowest($a) <=> lowest($b)} @cellArray;

foreach my $value (@cellArray){
   #print $value;
   #print DATA2 $value;
   my @lines = split (/$separator/,$value);
   print DATA2 $lines[1];
}

close (DATA2);


sub lowest {
  my @number1 = split(/$separator/,shift);
  return $number1[0];
}

