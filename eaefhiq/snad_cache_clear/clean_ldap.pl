#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my $all;
my $help;
my $list;
my $verbose;

GetOptions( 
   "help"     => \$help,
   "list"     => \$list,
   "verbose"  => \$verbose,
);

my @search_patterns = qw(CPName CPGroup ipAddressing protocol IO ossAppbrowser ossAppWf managedElementId fdn neInfo);


my $usage = <<"USAGE";
Usage:   $0 [options]

    -h, --help
                display this help and exit
    -l, --list
                list the entries found without deleting them
    -v, --verbose
                output additional information

    Example: $0 
        will remove all unwanted ("@search_patterns") entries

USAGE

if ($help)
{
   die "$usage";
}

my $ignore_pattern = "MIB_|ONRM_ROOT_MO|PlannedConfigurationApp";

for my $dn (@search_patterns)
{
   my $results = `/bin/ldapsearch -T -b "o=lmera" "$dn=*"`;
   print "Found dn=$dn:\n$results\n" if $verbose;
   while ($results =~ m/dn: (($dn=)?(\S+))/g)
   {
      my $entry = $1;
      next if $entry =~ m/$ignore_pattern/;
      $entry =~ s/\s//g;  # remove unwanted newline and space chars
      print "$entry\n" if $list or $verbose;
      print "Deleting ... $entry\n" unless $list;
      my $result = `/bin/ldapdelete -D 'cn=admin,o=lmera' -w ldapadmin $entry` unless $list;   # do the delete unless "list" option was selected
      print "Result=$result\n" if $result and $verbose;
   }
}


