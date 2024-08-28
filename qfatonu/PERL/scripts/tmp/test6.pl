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


#my $remote = $ssh->make_remote_command("cd /root/qfatonu/tmp/ && tar xf -");
#system "tar cf - . | $remote";

#my @call = $ssh->make_remote_command(ls => "/var/log");
#system @call;


#my ($output, $errput) = $ssh->capture2({timeout => 1}, "find / -name qfatonu");
#my ($output, $errput) = $ssh->capture2({timeout => 1}, "find /");
my @cmd = "
Xwhoami;
cd /tmp ; 
mkdir -p fatihTmpDir1;
pwd;
ls -l
";
#my ($output, $errput) = $ssh->capture2({timeout => 1}, @cmd);
my (@output, $errput) = $ssh->capture({timeout => 1}, @cmd);
#print "output= @output \n";
#print "errput= $errput \n";

my $count = 0;
foreach my $line (@output){
  print "[$count] $line\n";
  $count++;
}

$ssh->scp_put("/netsim/qfatonu/t*", "/root/qfatonu/tmp2");

$ssh->error and die "ssh failed: " . $ssh->error;




