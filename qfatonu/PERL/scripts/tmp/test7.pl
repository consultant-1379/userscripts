#!/usr/bin/perl -w
use strict;
use warnings;


#use Net::SFTP::Foreign;
use Net::OpenSSH;


my $host = "gateway";

open my $stderr_fh, '>>', "./$host.err" or die;
open my $stdout_fh, '>>', "./$host.log" or die;

 
my $ssh = Net::OpenSSH->new(
$host, 
user => "root",
passwd => "shroot",
default_stderr_fh => $stderr_fh,
default_stdout_fh => $stdout_fh );
$ssh->error and die "SSH connection failed: " . $ssh->error;
 
$ssh->scp_put("/foo/bar*", "/tmp")
  or die "scp failed: " . $ssh->error;
