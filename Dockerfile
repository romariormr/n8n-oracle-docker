FROM docker.n8n.io/n8nio/n8n:latest

USER root

RUN apk --no-cache add unzip libaio curl

COPY instantclient-basic-linux.x64-21.12.0.0.0dbru.zip /tmp/
COPY instantclient-sdk-linux.x64-21.12.0.0.0dbru.zip /tmp/

RUN mkdir -p /opt/oracle &&     unzip /tmp/instantclient-basic-linux.x64-21.12.0.0.0dbru.zip -d /opt/oracle &&     unzip /tmp/instantclient-sdk-linux.x64-21.12.0.0.0dbru.zip -d /opt/oracle &&     mv /opt/oracle/instantclient_21_12 /opt/oracle/instantclient &&     rm -f /tmp/*.zip

ENV OCI_LIB_DIR=/opt/oracle/instantclient
ENV OCI_INC_DIR=/opt/oracle/instantclient/sdk/include
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient:$LD_LIBRARY_PATH
ENV PATH=/opt/oracle/instantclient:$PATH

RUN npm_config_user=root npm install -g oracledb n8n-nodes-oracle

ENV N8N_CUSTOM_EXTENSIONS="/usr/local/lib/node_modules/n8n-nodes-oracle"

USER node
