#!/usr/bin/perl

open(MYINPUTFILE, "<UtranCellsWithCellId.txt"); # open for input
my(@lines) = <MYINPUTFILE>; # read file into list

my($line);
foreach $line (@lines) # loop thru list
{
  print "$line"; # print in sort order
}
close(MYINPUTFILE);
