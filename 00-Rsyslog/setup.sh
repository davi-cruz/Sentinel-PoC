#!/bin/bash

## Enclose default logging configuration in the condition, preventing
## external logging to disk
if [ -f /etc/rsyslog.d/50-default.conf ]; then
    sed -i '1i if ($fromhost-ip == "127.0.0.1") then {' /etc/rsyslog.d/50-default.conf
    sed -i '$a }' /etc/rsyslog.d/50-default.conf
fi



## Configure RSyslog
wget -O Forwarder_AMA_installer.py https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/DataConnectors/Syslog/Forwarder_AMA_installer.py
python3 Forwarder_AMA_installer.py