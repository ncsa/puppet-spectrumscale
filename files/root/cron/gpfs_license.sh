#!/bin/bash

#set -x

nodelist="$(
/usr/lpp/mmfs/bin/mmlslicense -Y \
| /bin/awk -F ':' '
  $3 ~ /HEADER/ { next }
  $9 ~ /none/ { printf( "%s,", $7 ) }
  END { printf( "\n" ) }
' \
| /bin/sed -e 's/,$//' )"

[[ -n $nodelist ]] && /usr/lpp/mmfs/bin/mmchlicense client --accept -N $nodelist

#1           23      4       5        6        7        8               9                 10         11              12              13                14                15
#mmlslicense::HEADER:version:reserved:reserved:nodeName:requiredLicense:designatedLicense:totalNodes:licensedServers:l
#icensedClients:unlicensedServers:unlicensedClients:licensedFpo:
#
#mmlslicense::0:1:::lsst-verify00.ncsa.illinois.edu:server:server:68:1:56:0:11:0:
