#!/usr/bin/perl


my $text="SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=RNC01-1-1";
my $filename="UtranRelations.txt";

# Grep works faster
#my $result = `grep $text $filename`;
#print $result;

my $filename2="UtranRelations.txt";
#open(my $fh2, '<', $filename) || die "Couldn't open file $filename2: $!";
#while ( my $line = <$fh2>){
#       if ( $line =~ /$text/ ) {
#            print $line;
#        }
#}
#close $fh2;

my @array = (0,1,2,3,4,5,6);
#splice(@array, 3, 1);

my $index=0;
foreach my $value (@array){
   if ( $value == 5 ){
      splice(@array, $index, 1);
   }
   if ( $value == 3 ){
      splice(@array, $index, 1);
   }
  $index++;
}

#print join(':', @array)."\n";

#foreach my $value (@array){ print $value."\n";}

my @items = ( 0..5 );
my $index = 0;
while ($index <= $#items ) {
  my $value = $items[$index];
  print "testing $value\n";
  if ( $value == 1 or $value == 3 ) {
    print "removed value $value\n";
    splice @items, $index, 1;
  } else {
    $index++;
  }
}

foreach my $value (@items){ print $value."\n";}
