#!/usr/bin/perl

use strict;
use warnings;

my @strings_ll = qw(why bostich socket zebra);
my @sorted_strings_ll = sort {lowest_letter($a) cmp lowest_letter($b)} @strings_ll;
print "Strings, sorted for their lowest letter\n";
#print join "\n",@sorted_strings_ll;

sub lowest_letter {
  my $string = shift;
  my $lowest_letter = chr(255);
  foreach my $letter (split //, $string) {
   print $letter."\n"; 
    $lowest_letter = $letter if $letter lt $lowest_letter;
  }
  return $lowest_letter;
}
