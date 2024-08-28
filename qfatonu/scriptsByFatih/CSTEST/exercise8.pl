#!/usr/bin/perl

my @input = ( [1, 2, 3], [4, 5, 6] );
# [ 1, 2, 3 ] is an anonymous array.
# I could have this instead:
#@line1 = ( 1, 2, 3 );
#@line2 = ( 4, 5, 6 );
#my @input = ( \@line1, \@line2 );

my @data;
my $i = 0;

# The 'my' in the loop is imperative, otherwise, each row will erase the
# previous one.
# The braces in @{ ... }  are imperative because of operator precedence
# against the [ ] brackets
while (my @dataRow = @{$input[$i++]}) {
    print @dataRow, "\n";

    # This stores a pointer to the @dataRow array, i.e. its address or
    # reference.
    # So essentially, you get an array of addresses of arrays, which
    # effectively gives you an array of arrays.  Note that each sub-array
    # (each row) can be different sizes unlike traditional 2-dimensional
    # arrays.
    push @data, \@dataRow;
}

# Now how do we get the data out?
# So in our array of arrays, if you say @data[5] you're saying
# data[5] which you want to be an array.  but that's not the way we
# stored things; we stored things as addresses of (or references to) arrays.
# So you have to say $data[5] to get the address of the array, and use @ to
# get the array, i.e.  @{$data[5]}
# This is called dereferencing.

print "Output loop\n";

foreach (@data) {
    print @{$_}, "\n";
    # I could have this instead, but less clear:
    #print @$_, "\n";

    print ${$_}[0], "\n";
    # I could have this instead, but less clear:
    #print $$_[0], "\n";
}

# Or equivalently
print "Explicit Output\n";
print @{$data[0]}, "\n";
print ${$data[0]}[0], "\n";
print @{$data[1]}, "\n";
print ${$data[1]}[0], "\n";
