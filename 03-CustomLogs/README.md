# 03 - Custom Logs

## Pre-requisites

To create a DCR for custom logs, you need the following:

- A sample log file in JSON format. If you're ingesting logs from a custom application like Apache or MySQL, you can use the provided script to convert the *.log to JSON in the expected format of the Tool. The script is available [here](./Convert-DCRSampleToJson.ps1).
- A KQL Transformation query to parse the log file. The query can be created during the DCR creation process or you can use the provided query. You also may decide to ingest the logs without parsing them and use query functions like **Parsers** if necessary.

## General instructions

If you're ingesting data to a new table, you need to provide additional information in order to create it accordingly.
You'll be asked to provide the following information:

- **Table name**: The name of the table that will be created in the Log Analytics workspace. The name must be unique and can't be changed after the DCR is created. It will be appended with **_CL** to indicate that it's a custom log table.
- **Table description**: A description for the table. It can be changed after the DCR is created.
- **Data Collection Endpoint**: The endpoint where the logs will be sent. This is required once we may have to do some processing during ingestion time
- **Data Collection Rule Name**: The name of the DCR. You can use an existing DCR or create a new one.

After providing the information, you'll be guided through a process of uploading sample data and creating a KQL query to parse the data. You can use the provided sample data and query or upload your own.

Note that when you upload a sample file and do the transformations, the final schema will be the one used to create the table. If you need to change the schema, you'll need to modify it later.

## Apache Logs

To leverage existing assets for MMA Apache Logs ingestion, you may collect logs as is and then use the built-in parser **ApacheHTTPService**.
To ingest Apache Logs, the following information is useful:

- Table name: **ApacheHTTPService**
- Transformation KQL:

```kusto
source
| extend TimeGenerated = now()
```

## MariaDB e MySQL

For MySQL and MariaDB, you need to enable the audit plugin and configure it to write to a file. While the audit plugin is available for MariaDB by default, only MySQL Enterprise versions comes with the plugin available.

If you require auditing for MySQL Community Instances, you can use the [AWS Audit Plugin](https://github.com/aws/audit-plugin-for-mysql) but you'll need to build MySQL install from source

Also ensure that audits and logs are enabled in the MySQL configuration file (`my.ini`). Refer to the [MySQL documentation](https://dev.mysql.com/doc/refman/8.0/en/audit-log-plugin-installation.html) or [MariaDB documentation](https://mariadb.com/kb/en/audit-plugin-installation/) for more information.

To ingest MySQL and MariaDB logs, the following information is useful:

- Table name: **MySQLAuditLogs**
- Transformation KQL:

```kusto
source
| parse RawData with timestamp "," serverhost "," username "," host "," connectionid "," queryid "," operation "," databaseName "," object "," retcode
| extend temp = extract_all(@\"(\d{4})(\d{2})(\d{2}) (\d{2}:\d{2}:\d{2})", timestamp)[0]
| extend TimeGenerated = todatetime(strcat(temp[0],'-',temp[1],'-',temp[2],' ',temp[3]))
| project-away RawData, temp, timestamp
```
