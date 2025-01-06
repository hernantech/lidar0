#!/bin/bash

if [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # IP address - start UDP listener
    exec /opt/pointpillars/lidar_processor --udp --host "$1"
elif [[ $1 =~ \.pcap$ ]]; then
    # PCAP file
    exec /opt/pointpillars/lidar_processor --pcap "$1"
else
    echo "Usage: $0 <ip_address or pcap_file>"
    exit 1
fi
