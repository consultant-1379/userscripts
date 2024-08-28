#!/usr/bin/perl

use strict;
use warnings;

my $info;
my @out;

$info = "1-One";

@out = split(/-/,$info);

print "out="."$out[1]"."\n";


my @strings = qw(1-why 30-bostich 400-socket 4-zebra);
#my @sorted_strings = sort {lowest($a) cmp lowest($b)} @strings;
my @sorted_strings = sort {lowest($a) <=> lowest($b)} @strings;

print "\n\n Sorted strings \n";
print join "\n",@sorted_strings,"\n";

sub lowest {
  my @number1 = split(/-/,shift);
  return $number1[0];
}
 
