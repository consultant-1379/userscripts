#!/usr/bin/perl -w
use strict;
use warnings;

#use lib '/netsim/download/Net-OpenSSH-0.60/lib';
use Net::OpenSSH;

#use lib '/netsim/download/IO-Tty-1.02/lib';
#use IO::Pty;

#my $host= "gateway";
my $ssh = Net::OpenSSH->new(
 host => 'netsim',
 user => 'netsim',
 passwd => 'netsim'
);
$ssh->error and
  die "Couldn't establish SSH connection: ". $ssh->error;

my @ls = $ssh->capture("ls");
$ssh->error and
  die "remote ls command failed: " . $ssh->error;

my $count=0;
foreach my $line (@ls){
  print $count++ . "=$line ";
}

=pod
@ls = $ssh->capture("ls /tmp/");
$ssh->error and
  die "remote ls command failed: " . $ssh->error;

$count=0;
foreach my $line (@ls){
 # print $count++ . "=$line ";
}

=cut

$ssh = Net::OpenSSH->new(
 host => 'ossmaster',
 user => 'root',
 passwd => 'shroot'
);

 @ls = $ssh->capture("ls /tmp/");
$ssh->error and
  die "remote ls command failed: " . $ssh->error;

$count=0;
foreach my $line (@ls){
  print $count++ . "=$line ";
}



