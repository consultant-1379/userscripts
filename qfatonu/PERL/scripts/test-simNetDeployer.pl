#!/usr/bin/perl -w
use strict;

my $dirSimNetDeployer = "/tmp/CORE/simNetDeployer/14.2.7/";
chdir("$dirSimNetDeployer/bin");

sub fetchFiles
{
my $path = $_[0];
#my $path = "testDir";
my $PWD = `pwd`;
chomp($PWD);

print "path=$path \n";
print "PWD=$PWD \n";
print ("Fetching files from $path on netsim server under /netsim/netsimdir \n");

my $errorStatus = 0;
`($PWD/../utils/fetchFiles.pl $path 2>&1) | tee ../logs/runtimLogFetchFiles.txt`;

my $errorHandler = `$PWD/../utils/checkForError.sh error ../logs/runtimLogFetchFiles.txt`;
if ($errorHandler != 0) {
        print("Error: Could not fetch feltch files from FTP server location $path\n");
        print("##########################################\n");
                $errorStatus = 1;
        }
         else {
                print("Successful file fetch Operation\n");
        }

print "errorStatus=$errorStatus \n";

return $errorStatus;

}

#my $storagePath = "/sim/Nothing";
my $storagePath = $ARGV[0];

my $errorStatusFetchFiles = &fetchFiles($storagePath);
print "errorStatusFetchFiles=$errorStatusFetchFiles \n";
if ("$errorStatusFetchFiles" == 1) {
  print ("failed \n");
  exit(1);
}else{
  print "passed\n";
}

=pod
=cut
