#!/bin/bash
set -euo pipefail; IFS=$'\n\t'



export SK_PORTNUMBER="$1"
export SK_STUDENTID=13323657
export SK_IP_ADDRESS=$(/sbin/ifconfig en0 inet \
                     | grep -o "\d\+\.\d\+\.\d\+\.\d\+" \
                     | head -n 1 \
                     | tr -d '\n')
mix clean
mix run --no-halt
