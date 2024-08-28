#!/usr/bin/perl

use strict;
use warnings;

foreach my $value (1..10){
    print $value."\n";
    system(sleep 1);
    #my $a=$!; 
    #echo "a=$a";
}
print "\n";
