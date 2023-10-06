# Configuring Flow Accounting (IPFIX/NetFlow) collection

To send flow accounting (IPFIX/NetFlow) to Microsoft Sentinel, is recommended to use Elastic Filebeat Netflow Module alongside with Logstash, to which Microsoft has its own output plugin.

More details on this process can be seen at the official docs at [Send data to Log Analytics from DCR using Logstash](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-portal#create-azure-ad-application)

## Checklist

- [ ] Install required software
- [ ] Create Entra ID App Registration for use with Logstash plugin
- [ ] Generate sample data
- [ ] Create and configure DCR
- [ ] Configure Logstash Plugin to send data to Sentinel

## Install Required Software

Run `setup.sh` file, which installs and configure all required software:

- Install Filebeat and Logstash
- Install Microsoft Sentinel Logstash Output Plugin
- Enable and configure Filebeat and Netflow module
- Enable and configure Logstash
- Copy Logstash pipeline files for `/etc/logstash/conf.d`
- Enable and start Filebeat and Logstash daemons

## Create Entra ID App Registration for use with Logstash plugin

Refer to original documentation for App Registration Creation. At the end of the process, you should have the following information readily available:

- Application (Client) Id
- Application (Client) Secret
- Directory (Tenant) Id

## Generate sample data

After the initial install, Filebeat and Logstash should be running at the collector machine. You can ensure it's running properly by following the steps below:

- Confirm if both services are running

```bash
sudo systemctl status filebeat.service logstash.service
```

- Confirm if Netflow listener is up. You should have `filebeat` process listening to 2055/UDP at all ports, just like the example below:

```bash
sudo ss -tulpn | grep filebeat
## Sample output
# udp   UNCONN 0      0                       *:2055             *:*    users:(("filebeat",pid=49489,fd=16))
```

- Confirm if Logstash listener is up at 5044/TCP. 

```bash
sudo ss -tulpn | grep 5044
## Sample output
# tcp   LISTEN 0      4096                    *:5044             *:*    users:(("java",pid=52820,fd=123))
```

- Confirm if sample file was generated at `/tmp/logstash`

```bash
ls -la /tmp/logstash/
## Sample output
#
#drwxr-xr-x  2 root root  4096 out  6 16:29 .
#drwxrwxrwt 34 root root  4096 out  6 18:25 ..
#-rw-r--r--  1 root root 19459 out  6 16:27 sampleFile1696620444.json
```

## Create and configure DCR

- Copy the sample file to your local machine by leveraging SCP or other file transfer method. `scp` command syntax sample is provided below

```bash
scp username@hostname:/tmp/logstash/sampleFile1696620444.json c:\temp\sampleFile1696620444.json
```

- Refer to original documentation and, when requested, upload the `sampleFilexxx.json` as example. 
- Use the query transformation below when requested. If from your sample any of the fields is missing, you can remove it without any issue (eg. `cloud`)

```kql
source
| extend TimeGenerated = todatetime(event.created)
| project-away cloud, ecs, ls_timestamp
```

- After completing the creation, grant the previously created App Registration **Monitoring Metrics Publisher** role at DCR level or any custom role you might create with `Microsoft.Insights/Telemetry/Write` rights.

## Configure Logstash Plugin to send data to Sentinel

- Fill in the required information to the definitive file `netflow-to-sentinel.conf_disabled` and rename it to `netflow-to-sentinel.conf` 
  - DCR and DCE information can be obtained from Azure Portal as described in the official reference
- Remove the `netflow-to-sentinel-temp.conf` from `/etc/logstash/conf.d` folder

```bash
sudo rm /etc/logstash/conf.d/netflow-to-sentinel-temp.conf
```

- Restart Logstash Service

```bash
sudo systemctl restart logstash.service
```

## Troubleshooting

- **General Logstash pipeline issues**: Review information located at `/var/log/logstash/logstash-plain.log`
- **Sample file don't get properly created**: Ensure the pipeline is running. You can also stop the service and run pipeline manually using debug mode

```bash
sudo systemctl stop logstash.service
sudo /usr/share/logstash/bin/logstash --debug -f /etc/logstash/conf.d/netflow-to-sentinel-temp.conf
```

- **Data isn't sent to Sentinel**:
  - Carefully review pipeline configuration file for any issues. Refer for the sample dummy pipeline for an example and start from there.
  - Ensure that App Registration Secret is valid and App Registration has proper rights to Data Collection Rule, as well as the Data Collection Endpoint URL is valid and associated to DCR. 

Any other error I would recommend you to review the filebeats and logstash logs for any issues.

