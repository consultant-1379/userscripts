#!/usr/bin/tcsh
set MASTER=atrcus575

foreach mc ( `egrep '^netsim.*list' /net/159.107.220.207/export/files/wranst/r7/config_files/${MASTER}.cfg | cut -f1 -d_` )
  echo "######################"
  echo "# "$mc
  echo "######################"
  #date
  #rsh -l netsim $mc 'ls -ltd R*'
  rsh -l netsim $mc 'ls -l inst'
  rsh -l netsim $mc 'echo ".show license" | /netsim/inst/netsim_shell' | grep expires
end

