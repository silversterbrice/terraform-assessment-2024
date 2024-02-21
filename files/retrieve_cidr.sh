#!/bin/bash

API_URL="https://FDQN/vend_ip"
CIDR=$(curl -s $API_URL | jq -r '.ip_address + .subnet_size')

if [ -n "$CIDR" ]; then
    echo "$CIDR" > cidr.txt
else
    echo "Failed to retrieve CIDR from API." >&2
    exit 1
fi
