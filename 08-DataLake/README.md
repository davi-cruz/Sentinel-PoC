# Machine Learning and AI

## ADX

### Provisionamento

Provisionar ADX Padrão (Dev/Test é suficiente para PoC) para demonstrar capacidade de ingestão de dados a partir do Ingestion Pipeline

Provisionar também eventHub 

## Databricks

### Provisionamento

- Criar databricks com as configurações padrão, limitando a quantidade de recursos, uma vez que não se faz necessário para a PoC
- Após provisionado o Databricks, criar um cluster de recursos computacionais para PoC

### Libraries

Enquanto se provisiona o Cluster de compute, cadastrar as seguintes libraries
- PyPI
  - azure-identity==1.14.0
  - azure-monitor-query==1.2.0
  - plotly==5.17.0
- Upload/Python Whl
  - azure_sentinel_utilities (a partir do repo do github)
- Maven - https://mmlspark.azureedge.net/maven
  - **Spark 3.2**: com.microsoft.azure:synapseml_2.12:0.11.3
  - **Spark 3.3**: com.microsoft.azure:synapseml_2.12:0.11.3-spark3.3


