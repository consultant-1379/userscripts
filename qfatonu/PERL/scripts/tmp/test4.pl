#!/usr/bin/perl -w
use strict;
use warnings;


use Net::OpenSSH;


my $timeout = 2;
my $debug = 0;

my $host = "gateway";
my $ssh = Net::OpenSSH-> new (
  $host,
  user => "root",
  passwd => "shroot",
  master_opts => [ -o => "StrictHostKeyChecking=no"]
);


my $remote = $ssh->make_remote_command("cd /root/qfatonu/tmp/ && tar xf -");
system "tar cf - . | $remote";

#my @call = $ssh->make_remote_command(ls => "/var/log");
#system @call;


my ($output, $errput) = $ssh->capture2({timeout => 1}, "find /");
$ssh->error and die "ssh failed: " . $ssh->error;




