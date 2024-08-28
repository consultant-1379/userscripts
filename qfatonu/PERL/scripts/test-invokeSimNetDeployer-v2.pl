#!/usr/bin/perl -w
use Net::FTP;
use Expect;
use Net::SSH::Expect;

=pod
#
#---------------------------------------------------------------------------------
#Environment variables
#---------------------------------------------------------------------------------
#Status - Work in Progress
#The idea here is to read all parameters and from the configEnvironment file
my $ossServerName = 'ossmaster';
@arr = `nslookup $ossServerName`;
$ossmasterAddress = substr($arr[4],9);
chomp($ossmasterAddress);
my $omsrvsServerName = 'omsrvm';
@arr = `nslookup $omsrvsServerName`;
$omsrvsAddress = substr($arr[4],9);
chomp($omsrvsAddress);
#
print "nope\n";

#
##
print("Accessing netsim to verify connectivity\n");
##Creating SSH object
my $sshNetsim = Net::SSH::Expect-> new (
host => "netsim",
user => 'root',
raw_pty => 1
);

print "nope10\n";
#
#Starting SSH process
$sshNetsim->run_ssh() or die LogFiles("SSH process couldn't start: $!");
        my $line;
        # returns the next line, removing it from the input stream:
        while ( defined ($line = $sshNetsim->read_line()) ) {
            print $line . "\n";  
        }
  # closes the ssh connection
        $sshNetsim->close();

=cut

#sub rollout
#{

$dirSimNetDeployer="/tmp/CORE/simNetDeployer/14.2.7";

#Creating SSH object
my $ssh = Net::SSH::Expect-> new (
host => "netsim",
user => 'root',
raw_pty => 1
);
#Starting SSH process
$ssh->run_ssh() or die LogFiles("SSH process couldn't start: $!");

        # 3) you should be logged on now. Test if you received the remote prompt:
        ($ssh->read_all(2) =~ /netsim/) or die "where's the remote prompt?";

        # disable terminal translations and echo on the SSH server
        # executing on the server the stty command:
#        $ssh->exec("stty raw -echo");

print("The simulations are being rolled out on netsim now. Please login and refer to dirSimNetDeployer/logs/simNetDeployerLogs.txt for more dtails \n");
my $output = $ssh->exec("chmod u+x $dirSimNetDeployer/bin/test-rollout.pl");
#my @output = $ssh->exec("chmod u+x $dirSimNetDeployer/bin/test-rollout.pl");
#print "output=$output \n";
#print ("The Parameters passes are \nPATH_OF_SIMS_ON_FTP = path \nIP_ADDRESS_OF_OSSMASTER = ossmasterAddress \nSIMNET_DEPLOYER_DIR = dirSimNetDeployer\nIP_ADDRESS_OF_CAAS = caasAddress \nSECURITY_STATUS_TLS = securityStatusTLS\nSECURITY_STATUS_SL3 = securityStatusSL3\n");
        # disable terminal translations and echo on the SSH server
        # executing on the server the stty command:
        $ssh->exec("stty raw -echo");

#my @result= $ssh->exec("$dirSimNetDeployer/bin/test-rollout.pl");
my $result= $ssh->exec("$dirSimNetDeployer/bin/test-rollout.pl");
my @array = split("\n", $result, length($result));
#ssh->waitfor("Done",60000) or die "Something went wrong during rollout $!";
print "result= $result \n";
=pod
        #$line="";
        my @output;
	my $index = 0;
        # returns the next line, removing it from the input stream:
        #while ( defined ($line = $ssh->read_line()) ) {
        #while ( defined ($line = shift @output)) {
        for my $line (@result){
		$output[$index++] = $line;
            print "[$index] - $line . \n";  
		
        }
#$numOfElements = @output;
#$lastLine = $output[$numOfElements - 1];
=cut
#print "lastLine=$lastLine\n";
        my @output;
        my $index = 0;
        for my $line (@array){
                $output[$index++] = $line;
            print "[$index] - $line . \n";

        }

my $numOfElements = @output;
my $lastLine = $output[$numOfElements - 2];
print "lastLine=$lastLine\n";

#}

#&rollout();

=pod
=cut
