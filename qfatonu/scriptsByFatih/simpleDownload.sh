#!/bin/bash

echo "..download file starting"

fileName="simdep.tar.gz"

( cd tmp && /usr/bin/curl -u simguest:simguest -O ftp://ftp.athtem.eei.ericsson.se/TEP/qfatonu/download/$fileName ) \
  ||  { printf 'File does not exist or is not a regular file: %s\n' "$fileName" >&2; exit 1; }
#echo "dolarQM=$?"

echo "..download file ended!"
