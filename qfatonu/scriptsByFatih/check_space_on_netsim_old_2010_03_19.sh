#!/usr/bin/tcsh

set bold=`tput bold`
set offbold=`tput rmso`

set MASTER=atrcus575

foreach mc ( `egrep '^netsim.*list' /net/159.107.220.207/export/files/wranst/r7/config_files/${MASTER}.cfg | cut -f1 -d_` )

  #echo $mc
  echo "${bold}$mc ${offbold}"
  #rsh -l netsim $mc 'ls -ltd R*'
  # rsh -l netsim $mc 'ls -l inst'
  # rsh -l netsim $mc 'echo ".show license" | /netsim/inst/netsim_shell' | grep expires
  rsh -l netsim $mc 'df -h' 
end

