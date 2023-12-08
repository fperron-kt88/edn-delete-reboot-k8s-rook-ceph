#!/bin/bash

cat ./91_install_ports.sh  | grep port_forward | grep -v function | awk '{print $2 $5}' | perl -pe 's/^"//;s/"/:/'| perl -ne 's/\n/ /g;print' | xargs ./____check_ports.sh
