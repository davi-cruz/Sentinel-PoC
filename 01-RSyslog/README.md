# 01 - RSyslog configuration for CEF/Syslog forwarding with AMA

## Checklist

- [ ] Machine Provisioning
- [ ] Criação Data Collection Rule
- [ ] Execução do script de configuração do Rsyslog
- [ ] TLS Configuration (Optional):
  - [ ] Installing requirements
  - [ ] Creating CA certificate
  - [ ] Creating Server certificate
  - [ ] Setup RSyslog Server
  - [ ] Setup RSyslog Client
- [ ] Troubleshooting

## Machine Provisioning

Follow the default provisioning steps for a Linux machine in your environment. In this example, we'll use an Ubuntu 22.04 LTS machine.

If this is a non-Azure machine, you'll need to onboard it to Azure Arc first. You can find more information about it [here](https://docs.microsoft.com/en-us/azure/azure-arc/servers/overview).

## Create Data Collection Rules

- Go to the Azure Portal and navigate to the **Microsoft Sentinel**. There find the **Content Hub** option.
- Install the **Common Event Format** solution. This will install the **Common Event Format (CEF) via AMA (Preview)** connector.
- Go to the newly installed connector and click on **Open Connector Page**. There you'll find the **Data Collection Rules** option where you should create one which should be associated with the machine provisioned in the previous step.
- Do the same for the **Syslog**, but this time creating a standard DCR and associating it with the machine provisioned in the previous step.

## Finish collector configuration

After the DCR, you need to complete RSyslog config by running the script below:

```bash
#!/bin/bash

## Enclose default logging configuration in the condition, preventing
## external logging to disk
sed -i '1i if ($fromhost-ip == "127.0.0.1") then {' /etc/rsyslog.d/50-default.conf
sed -i '$a }' /etc/rsyslog.d/50-default.conf

## Configure RSyslog
wget -O Forwarder_AMA_installer.py https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/DataConnectors/Syslog/Forwarder_AMA_installer.py && python3 Forwarder_AMA_installer.py
```

## TLS Configuration (Optional)

### Installing requirements

RSyslog implements GNU TLS, so we need to install the package `gnutls-bin` to validate the connection and we'll also leverage the `certtool` command to generate the certificates used for PoC.

```bash
sudo apt install gnutls-bin
```

### Creating CA certificate

Modify the information in the file `ca-template.cfg` as desired. You can also use `openssl` to generate the CA certificate or use an existing PKI infrastructure of your organization.

```conf
## ca-template.cfg
# X.509 Certificate options

country = BR
state = "Sao Paulo"
locality = "Sao Paulo"
organization = "Contoso"
unit = "Testing"
cn = "Contoso CA"
serial = 1
expiration_days = 365
ca
```

```bash
# Create CA Key and Certificate
certtool --generate-privkey --outfile ca-key.pem
certtool --generate-self-signed --load-privkey ca-key.pem --outfile ca.pem --template ca-template.cfg
```

### Creating Server certificate

Specify the information during the wizard:

- Country
- State
- Locality
- Common Name (FQDN da máquina)
- Is this a TLS web client certificate? **Yes**
- Is this a TLS web server certificate? **Yes**

```bash
certtool --generate-privkey --outfile client-key.pem --sec-param=medium
certtool --generate-request --load-privkey client-key.pem --outfile client-request.pem
certtool --generate-certificate --load-request client-request.pem --outfile client.pem --load-ca-certificate ca.pem --load-ca-privkey ca-key.pem
```

### Setup RSyslog Server

- Run the commands below on the server to copy the files to the `/etc/ssl/rsyslog` directory and adjust the `/etc/rsyslog.conf` file

```bash
## Install required packages
apt install -y ca-certificates

## Disable imtcp module in /etc/rsyslog.conf
sed -i '/imtcp/s/^/#/g' /etc/rsyslog.conf

## Create /etc/ssl/rsyslog folder
mkdir -p /etc/ssl/rsyslog

## Copy files to /etc/ssl/rsyslog
## Files to be copied: ca.pem, server-key.pem, server.pem
cp -r ../certs/ * /etc/ssl/rsyslog

## Update certificates
cp /etc/ssl/rsyslog/ca.pem /usr/local/share/ca-certificates/ca.pem
update-ca-certificates
```

- Create a configuration file at `/etc/rsyslog.d/00-rsyslog.tls.conf` with the instructions below. Make sure to review the file names configured in the `DefaultNetstreamDriver*` properties.

```conf
# Defines GTLS as default netstream driver and its certificate properties
global(
    DefaultNetstreamDriver="gtls"
    DefaultNetstreamDriverCAFile="/etc/ssl/rsyslog/ca.pem"
    DefaultNetstreamDriverCertFile="/etc/ssl/rsyslog/client.pem"
    DefaultNetstreamDriverKeyFile="/etc/ssl/rsyslog/client-key.pem"
)

# Configures the imtcp module as a TCP syslog receiver with TLS enabled, enforcing TLS 1.2 or 1.3
module(
    load="imtcp"
    StreamDriver.Name="gtls"
    StreamDriver.Mode="1"
    StreamDriver.AuthMode="anon"  
)

# Start listening on TCP port 6514
input(
    type="imtcp"
    port="6514"
)
```

Reload the RSyslog service to apply the changes:

```bash
sudo systemctl restart rsyslog
```

### Client Configuration

If you're using another RSyslog server as a client only, here's how to configure it. If you're using another application, you'll need to check the documentation to see how to configure it accordingly:

- Run the commands below on the client to copy the files to the `/etc/ssl/rsyslog` directory and adjust the `/etc/rsyslog.conf` file

```bash
#!/bin/bash

## Install required packages
apt install -y ca-certificates

## Create /etc/ssl/rsyslog folder
mkdir -p /etc/ssl/rsyslog

## Copy files to /etc/ssl/rsyslog
cp ../00-rsyslog-tls/ca.pem /etc/ssl/rsyslog/ca.pem

## Update certificates
cp /etc/ssl/rsyslog/ca.pem /usr/local/share/ca-certificates/ca.pem
update-ca-certificates
```

- Edit the configuration file for the client at `/etc/rsyslog.d/00-rsyslog-client.conf` with the following content, reviewing the file names configured in the `DefaultNetStreamDriver*` properties.

```conf
# Certificate files
global(
    DefaultNetStreamDriverCAFile="/etc/ssl/rsyslog/ca.pem"
)

# Make TLS the default transport
action(type="omfwd" protocol="tcp" port="6514"
       StreamDriver="gtls" StreamDriverMode="1" StreamDriverAuthMode="anon")
```

Reload the RSyslog service to apply the changes:

```bash
sudo systemctl restart rsyslog
```

## Troubleshooting

From the RSyslog Server, you can monitor the TCP port 514 or 6514 to see if the any client is connecting. Make sure to replace the interface and port numbers with the correct ones:

```bash
## RSyslog TCP
sudo tcpdump -A -i eth0 -s 0 'tcp port 514'

## RSyslog TLS
sudo tcpdump -A -i eth0 -s 0 'tcp port 6514'
```

Also, from a RSyslog Client, you can test the connection sending a test message.

```bash
## Send messages
#Syslog
logger -n hostname -P 514 -p local4.info -T "Test message"

#CEF
logger -n hostname -P 514 -p local4.warn -t CEF "CEF:0|Microsoft|ATA|1.9.0.0|AbnormalSensitiveGroupMembershipChangeSuspiciousActivity|Abnormal modification of sensitive groups|5|start=2018-12-12T18:52:58.0000000Z app=GroupMembershipChangeEvent suser=krbtgt msg=krbtgt has uncharacteristically modified sensitive group memberships. externalId=2024 cs1Label=url cs1=https://192.168.0.220/suspiciousActivity/5c113d028ca1ec1250ca0491"
```

If you're using TLS, you can do an additional check by using `gnutls-cli` validating the TLS connection configuration:

```bash
## Test connection
gnutls-cli --x509cafile /path/to/ca.pem --port 6514 hostname

## Send messages

#Syslog
logger -n hostname -P 514 -p local4.info -T "Test message"

#CEF
logger -n hostname -P 514 -p local4.warn -t CEF "CEF:0|Microsoft|ATA|1.9.0.0|AbnormalSensitiveGroupMembershipChangeSuspiciousActivity|Abnormal modification of sensitive groups|5|start=2018-12-12T18:52:58.0000000Z app=GroupMembershipChangeEvent suser=krbtgt msg=krbtgt has uncharacteristically modified sensitive group memberships. externalId=2024 cs1Label=url cs1=https://192.168.0.220/suspiciousActivity/5c113d028ca1ec1250ca0491"
```

Also, depending on your configuration for both CEF or Syslog ingestion, you may receive the messages but they may not being collected. In those scenarios, be sure that Facility and Severity are configured correctly in the DCR.

- I've written a powershell script that gets the PRI value from the Syslog message you may see using `tcpdump` and converts it to Facility and Severity. You can find it at this same folder.
