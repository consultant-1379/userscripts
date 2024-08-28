#!/usr/bin/perl

my @pids; # to hold process id's of child processes
my $pid_index = 0;
my $max_pid_index = 4;
my $pid;

my $testArray;

while($pid_index <= $max_pid_index){
  if($pids[$pid_index] = fork()){
    # this is the parent, just spins round and has childrem
    $pid_index++;
  } else {
    # this is the child, does a single task and then exits
    sleep(5);
    print "child $pid_index\n";
    push (@testArray, "hello");
    exit(0);
  }
}

print "waiting...\n";
foreach $pid (@pids){
  waitpid($pid,0);
}


print "testArray=".@testArray."\n";

print "All done\n";
