#!/usr/bin/perl
 
use strict;
use warnings;
 
print "Starting main program\n";
my @childs;

my @rncs;
 
for ( my $count = 1; $count <= 1; $count++) {
        my $pid = fork();
        if ($pid) {
        # parent
        #print "pid is $pid, parent $$\n";
        push(@childs, $pid);
        } elsif ($pid == 0) {
                # child
                #sub1($count);
                my @tmpArray = countRelations($count);
                #foreach my $value (@tmpArray){ print $value; }
                #print @tmpArray, "\n";
                push @rncs, \@tmpArray;
                print "rncs=\n".@rncs, "\n";
                exit 0;
        } else {
                die "couldnt fork: $!\n";
        }
 
 
 
}
 
foreach (@childs) {
        my $tmp = waitpid($_, 0);
         print "done with pid $tmp\n";
 
}

print "rncs=\n".@rncs, "\n";

foreach (@rncs) {
    print @{$_}, "\n";
    # I could have this instead, but less clear:
    #print @$_, "\n";

    print ${$_}[0], "\n";
    # I could have this instead, but less clear:
    #print $$_[0], "\n";
}

#foreach  my @rnc (@rncs) {
#  foreach my $line (@rnc) {
#     print @line."\n";
#  }
#}
 
print "End of main program\n";


sub countRelations {
  my $rncId= shift;
  my $rncName = getRncName($rncId);

  my $filename1="UtranCellsSorted.txt";
  my @outputArray;

  my $longString= "####################################################\n".
                " $rncName utran relations\n".
                "####################################################\n";

  push(@outputArray, $longString);

  my @utranCells_Array =`grep $rncName $filename1`; 

  my $count=1;
  foreach my $utranCell (@utranCells_Array){

    chomp $utranCell;
    my $longString = "####################################################\n".
                     " COUNT=$count $utranCell\n".
                     "####################################################\n";

    push(@outputArray, $longString);
  }

  return @outputArray;
}
 
sub sub1 {
        my $num = shift;
        print "started child process for  $num\n";
        sleep $num;
        #print "done with child process for $num\n";
        print "done with child process for ".getRncName($num)."\n";
        return $num;
}


sub getRncName {
  my $COUNT= shift;
  my $RNCNAME;

  if($COUNT <= 9){
    $RNCNAME="RNC0".$COUNT;
  }
  else{
    $RNCNAME="RNC".$COUNT;
  }
  #print $RNCNAME;
  return $RNCNAME;
}

