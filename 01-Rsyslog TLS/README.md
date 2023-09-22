# Creating TLS certificates

## Installing requirements

```bash
sudo apt install gnutls-bin
```

## Creating CA

Modificat as informações no arquivo `ca-template.cfg` conforme desejado

```bash
# Create CA Key and Certificate
certtool --generate-privkey --outfile ca-key.pem
certtool --generate-self-signed --load-privkey ca-key.pem --outfile ca.pem --template ca-template.cfg
```

## Certificate

Especificar as informações durante o wizard:

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

## Server Setup

- Executar o comando abaixo no servidor para copiar os arquivos para o diretório `/opt/rsyslog-tls` e ajustar arquivo `/etc/rsyslog.conf`

```bash
#!/bin/bash

## Disable imtcp module in /etc/rsyslog.conf 
sed -i '/imtcp/s/^/#/g' /etc/rsyslog.conf

## Install required packages
apt install -y ca-certificates

## Create /opt/rsyslog-tls folder
mkdir /opt/rsyslog-tls

## Copy files to /opt/rsyslog-tls
## Files to be copied: ca.pem, server-key.pem, server.pem
cp -r ../certs/ * /opt/rsyslog-tls

## Update certificates
cp /opt/rsyslog-tls/ca.pem /usr/local/share/ca-certificates/ca.pem
update-ca-certificates
```

- Editar arquivo de configuração em `/etc/rsyslog.d/00-rsyslog.tls.conf` com o seguinte conteúdo, revisando nomes dos arquivos configurados

```conf
# Defines GTLS as default netstream driver and its certificate properties
global(
    DefaultNetstreamDriver="gtls"
    DefaultNetstreamDriverCAFile="/opt/rsyslog-tls/ca.pem"
    DefaultNetstreamDriverCertFile="/opt/rsyslog-tls/client.pem"
    DefaultNetstreamDriverKeyFile="/opt/rsyslog-tls/client-key.pem"
)

# Configures the imtcp module as a TCP syslog receiver with TLS enabled, enforcing TLS 1.2 or 1.3
module(
    load="imtcp"
    StreamDriver.AuthMode="anon" ## Anonymous authentication
    StreamDriver.Mode="1"
    StreamDriver.Name="gtls"
)

## Omitir se configuração estiver presente no arquivo /etc/rsyslog.conf
input(
    type="imtcp"
    port="6514"
)
```

## Client Configuration

- Executar o comando abaixo no cliente para copiar os arquivos para o diretório `/opt/rsyslog-tls` e ajustar arquivo `/etc/rsyslog.conf`

```bash
#!/bin/bash

## Install required packages
apt install -y ca-certificates

## Create /opt/rsyslog-tls folder
mkdir /opt/rsyslog-tls

## Copy files to /opt/rsyslog-tls
cp ../00-rsyslog-tls/ca.pem /opt/rsyslog-tls/ca.pem

## Update certificates
cp /opt/rsyslog-tls/ca.pem /usr/local/share/ca-certificates/ca.pem
update-ca-certificates
```

- Editar arquivo de configuração para cliente em `/etc/rsyslog.d/00-rsyslog-client.conf` com o seguinte conteúdo, revisando nomes dos arquivos configurados

```conf
# Certificate files
$DefaultNetStreamDriverCAFile /opt/rsyslog-tls/ca.pem

# make gtls driver the default
$DefaultNetStreamDriver gtls
$ActionSendStreamDriverMode 1   # run driver in TLS-only mode
$ActionSendStreamDriverAuthMode anon
```
