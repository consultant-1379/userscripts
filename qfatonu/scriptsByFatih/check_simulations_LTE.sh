#!/usr/bin/tcsh

set MASTER=atrcus575

foreach mc ( `egrep '^netsim.*list' /net/159.107.220.207/export/files/wranst/r7/config_files/${MASTER}.cfg | cut -f1 -d_` )
  #echo $mc
  echo "###############"
  grep ${mc}_list /net/159.107.220.207/export/files/wranst/r7/config_files/${MASTER}.cfg
  echo "###############"
  #rsh -l netsim $mc 'ls -ltd R*'
  rsh -l netsim $mc 'ls -ld /netsim/netsimdir/L*'
  #rsh -l netsim $mc 'echo ".show license" | /netsim/inst/netsim_shell'
  echo -------------------------------
end

