# Configuring Flow Accounting Connector

Source: [Send data to Log Analytics from DCR using Logstash](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-portal#create-azure-ad-application)

- Install the plugin: Run `setup.sh` for plugin and dependency installation
  - Script installs logstash and filebeat
  - Enable Netflow module
  - configure filebeat (set output to logstash instead of Elasticsearch)
  - copy logstash temporary and definitive configuration
- Create the required DCR-related resources
  - After configuring flow accounting to filebeat endpoint, get sample file at `/tmp/logshtash` and create DCR
- Configure Logstash configuration file
  - Insert App Registration Client ID and Secret, as well as the provisioned Entra ID Tenant
    - App Registration should have "Monitoring MEtrics Publisher" or `Microsoft.Insights/Telemetry/Write` permission in the previously created DCR
  - Also Insert DCR Immutable ID and Stream name and Data Collection Endpoint URL
  - Delete the temporary configuration file and rename the definitive one, removing the _disabled suffix.
- Restart Logstash
- View incoming logs in Microsoft Sentinel
- Monitor output plugin audit logs