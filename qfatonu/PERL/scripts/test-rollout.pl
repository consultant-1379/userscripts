#!/usr/bin/perl -w
use Net::FTP;
use POSIX;
###################################################################################
#
#     File Name : rollout.pl
#
#     Version : 5.00
#
#     Author : Jigar Shah
#
#     Description : Gets the latest deployer build version from storage server.
#
#     Date Created : 28 Januray 2103
#
#     Syntax : ./rollout.pl <simPath> <IP-OSS-Master> <PATH> <caasIP>
#
#     Parameters : <simPath> Path where sims are.
#                  <IP-OSS-Master> IP address of OSS master
#                  <PATH> The working directory 
#                  <caasIP> The IP address of OMSAS
#
#     Example :  ./rollout.pl /sims/CORE/xjigash/simNetDeployer/simulation
#
#     Dependencies : 1. Should be able to access storage device - FTP server.
#
#     NOTE: 1. The module is only enabled to support FTP as a storage device
#
#     Return Values : 1 ->Not a root user
#                     2 -> Usage is incorrect     
#                     
###################################################################################
#
#----------------------------------------------------------------------------------
#Check if the scrip is executed as root user
#----------------------------------------------------------------------------------
#
$user = `whoami`;
chomp ($user);
$root = 'root';
if ($user ne $root){
        print"Error: Not root user. Please execute the script as root user\n";
        exit(1);
}
$PWD=`pwd`;
chomp($PWD);
#$dirSimNetDeployer = `cd .. ; pwd`;
$dirSimNetDeployer = "/tmp/CORE/simNetDeployer/14.2.7";
chomp($dirSimNetDeployer);
#
my $simPath = "/sims/xjigash/testSim/CORE/";
#my $simPath = "/sim/Nothing";
#system("sudo su -l netsim -c '$dirSimNetDeployer/bin/test-simNetDeployer.pl $simPath'");
#my $result = `sudo -u netsim -s -- '$dirSimNetDeployer/bin/test-simNetDeployer.pl $simPath'`;
my $result = system("sudo -u netsim -s -- '$dirSimNetDeployer/bin/test-simNetDeployer.pl $simPath'");
print "result = $result \n";
if($result eq 0){
  print("passed\n");
}else{
  print("failed\n");
}


