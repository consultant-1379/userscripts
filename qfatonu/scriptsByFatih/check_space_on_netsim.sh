#!/bin/bash

bold=`tput bold`
offbold=`tput sgr0`

set MASTER=atrcus575



loc_SERVERS=" netsimlin145 netsimlin148 netsimlin161 netsimlin180 netsimlin188 netsimlin192 netsimlin322 netsimlin323 netsimlin324 netsimlin303 netsimlin72 netsimlin73"

for SERVER in $loc_SERVERS # for testing purposes, get server from local variable
#for SERVER in $SERVERS # get serevrs from CONFIG file
do

  #foreach mc ( `egrep '^netsim.*list' /net/159.107.220.207/export/files/wranst/r7/config_files/${MASTER}.cfg | cut -f1 -d_` )

  mc=$SERVER  
  #echo $mc
  echo "${bold}$mc ${offbold}"
  #rsh -l netsim $mc 'ls -ltd R*'
  # rsh -l netsim $mc 'ls -l inst'
  # rsh -l netsim $mc 'echo ".show license" | /netsim/inst/netsim_shell' | grep expires
  rsh -l netsim $mc 'df -h' 

  #end

done

