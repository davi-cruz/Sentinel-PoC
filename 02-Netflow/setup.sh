#!/bin/bash

## Setup Logstash e Filebeat 7
apt install apt-transport-https
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list
apt update && apt install default-jre logstash filebeat

## Ensure read permissions on libraries and logs
directories=("/var/log/logstash" "/var/log/filebeat" "/var/lib/logstash" "/var/lib/filebeat")
for dir in "${directories[@]}"
do
    mkdir -p $dir
    chmod -R 755 $dir
done

## Ensure read permissions on config files
chmod 755 "/etc/filebeat/filebeat.yml"

## Install Sentinel Logstash plugin 
/usr/share/logstash/bin/logstash-plugin install microsoft-sentinel-log-analytics-logstash-output-plugin

## Enable NetFlow Module
/usr/bin/filebeat modules enable netflow
sudo sed -i '/netflow_host/s/localhost/0.0.0.0/g' /etc/filebeat/modules.d/netflow.yml

## Replace Filebeat configuration to redirect to logstash
cp filebeat.yml /etc/filebeat/filebeat.yml

## Add Logstash configuration pipeline
cp netflow-to_sentinel.conf /etc/logstash/netflow-to-sentinel.conf_disabled
cp netflow-to_sentinel-temp.conf /etc/logstash/netflow-to_sentinel-temp.conf

mkdir /tmp/logstash

## Run Logstash and Filebeat
services=(logstash filebeat)
for service in "${services[@]}"
do
    systemctl enable $service
    systemctl start $service
done