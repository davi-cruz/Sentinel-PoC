# Configuração CEF/Syslog Collector

## Checklist

- Provisionamento da VM Linux
- Criação Data Collection Rule
- Execução do script de configuração do Rsyslog

## Provisionamento da VM Linux

Seguir com o provisionamento de máquina Linux padrão (Ubuntu 22.04 LTS)

## Criação Data Collection Rule

- Acessar o portal do Microsoft Sentinel e navegar até a opção **Content Hub**
- Instalar a solução **Common Event Format**
- Após Instalado, navegar até a opção **Data connectors** e selecionar a opção **Common Event Format (CEF) via AMA (Preview)** e selecionar a opção **Open Connector Page**
- Criar um Data Collection Rule associado ao servidor Linux provisionado e selecionar **LOG_INFO** como severidade mínima para informações a serem enviadas ao Sentinel
- Executar script de setup `setup.sh` para configuração do Rsyslog (run as **sudo**)

```bash
#!/bin/bash

## Enclose default logging configuration in the condition, preventing
## external logging to disk
sed -i '1i if ($fromhost-ip == "127.0.0.1") then {' /etc/rsyslog.d/50-default.conf
sed -i '$a }' /etc/rsyslog.d/50-default.conf

## Configure RSyslog
wget -O Forwarder_AMA_installer.py https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/DataConnectors/Syslog/Forwarder_AMA_installer.py
python3 Forwarder_AMA_installer.py
```
