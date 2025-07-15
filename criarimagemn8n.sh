#!/bin/bash
set -euo pipefail

# Nome padrão da imagem
DEFAULT_VERSION="latest"
DEFAULT_TAG="n8n-oracle"

echo "🎯 Versão do n8n desejada [padrão: ${DEFAULT_VERSION}]:"
read -r VERSION
VERSION=${VERSION:-$DEFAULT_VERSION}

echo "🏷️ Nome da imagem/tag [padrão: ${DEFAULT_TAG}]:"
read -r IMAGE_TAG
IMAGE_TAG=${IMAGE_TAG:-$DEFAULT_TAG}

# Nomes dos arquivos ZIP
BASIC_ZIP="instantclient-basic-linux.x64-21.12.0.0.0dbru.zip"
SDK_ZIP="instantclient-sdk-linux.x64-21.12.0.0.0dbru.zip"

# Verifica se os arquivos existem
if [[ ! -f "$BASIC_ZIP" || ! -f "$SDK_ZIP" ]]; then
  echo "❌ Os arquivos Oracle Instant Client não foram encontrados."
  echo "👉 Acesse: https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html"
  echo "   E baixe os arquivos:"
  echo "   - $BASIC_ZIP"
  echo "   - $SDK_ZIP"
  echo "Coloque ambos nesta mesma pasta e execute novamente."
  exit 1
fi

# Gera Dockerfile dinâmico
echo "⚙️ Gerando Dockerfile para n8n:${VERSION} com suporte Oracle..."

cat > Dockerfile <<EOF
FROM docker.n8n.io/n8nio/n8n:${VERSION}

USER root

RUN apk --no-cache add unzip libaio curl

COPY ${BASIC_ZIP} /tmp/
COPY ${SDK_ZIP} /tmp/

RUN mkdir -p /opt/oracle && \
    unzip /tmp/${BASIC_ZIP} -d /opt/oracle && \
    unzip /tmp/${SDK_ZIP} -d /opt/oracle && \
    mv /opt/oracle/instantclient_21_12 /opt/oracle/instantclient && \
    rm -f /tmp/*.zip

ENV OCI_LIB_DIR=/opt/oracle/instantclient
ENV OCI_INC_DIR=/opt/oracle/instantclient/sdk/include
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient:\$LD_LIBRARY_PATH
ENV PATH=/opt/oracle/instantclient:\$PATH

RUN npm_config_user=root npm install -g oracledb n8n-nodes-oracle

ENV N8N_CUSTOM_EXTENSIONS="/usr/local/lib/node_modules/n8n-nodes-oracle"

USER node
EOF

echo "🐳 Iniciando build da imagem ${IMAGE_TAG}:${VERSION}..."
docker build -t ${IMAGE_TAG}:${VERSION} .

echo "✅ Imagem construída com sucesso: ${IMAGE_TAG}:${VERSION}"

