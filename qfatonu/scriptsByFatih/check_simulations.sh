#!/usr/bin/tcsh

set MASTER=atrcus734

foreach mc ( `egrep '^netsim.*list' /net/159.107.220.207/export/files/wranst/r7/config_files/${MASTER}.cfg | cut -f1 -d_` )
  #echo $mc
  echo "###############"
  grep ${mc}_list /net/159.107.220.207/export/files/wranst/r7/config_files/${MASTER}.cfg
  echo "###############"
  #rsh -l netsim $mc 'ls -ltd R*'
  rsh -l netsim $mc 'ls -ld /netsim/netsimdir/R*'
  echo -------------------------------
end

