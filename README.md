# 🚀 n8n with Oracle Instant Client Support

[🇺🇸 English below | 🇧🇷 Português abaixo]

## 📦 Image Overview

This is a custom Docker image of **[n8n](https://n8n.io/)** with full support for the **Oracle Instant Client 21.12**, enabling Oracle Database integrations in workflows.

- ✅ Based on official `n8n` image
- ✅ Includes Oracle Instant Client basic + SDK (21.12)
- ✅ Pre-installed `oracledb` Node.js driver
- ✅ Open-source and ready for production use

---

## 🐳 How to use

### 📥 Pull from Docker Hub

```bash
docker pull romariormr/romariobrito-n8n-oracle:latest

# N8N com Suporte Oracle - Docker Image

Este repositório contém uma imagem Docker personalizada do N8N com suporte para o Oracle Database. Siga as etapas abaixo para configurar e utilizar corretamente o ambiente.

---

## 📝 Sumário

1. [Configuração Oracle no N8N](#configurando-oracle-no-n8n)
2. [Como Criar os Arquivos de Configuração](#como-criar-os-arquivos-de-configuração)
3. [Adicionando Credenciais no N8N](#adicionando-credenciais-no-n8n)
4. [Deploy da Stack no Docker](#deploy-da-stack-no-docker)
5. [Configuração do Banco de Dados](#configuração-do-banco-de-dados)
6. [Doações](#doações)

---

## Configurando Oracle no N8N

Para utilizar o Oracle no N8N, você precisa realizar algumas configurações no seu ambiente Docker. Siga os passos abaixo:

1. **Verifique se o arquivo `yaml` possui a configuração correta dos arquivos `sqlnet.ora` e `tnsnames.ora`**.

   ![Imagem 1](file:///mnt/data/1a59e3f7-9c17-4b6f-b2cd-113fec98311f.png)

2. **Acesse a área de `Configs` no seu Docker Swarm** para configurar os arquivos necessários.

   ![Imagem 2](file:///mnt/data/163244a5-fb8b-4142-88e1-25464fbdfc6f.png)

3. **Crie os arquivos `sqlnet_ora_config` e `tnsnames_ora_config` com os seguintes conteúdos**:

   - **sqlnet_ora_config**
     ```txt
     SQLNET.ALLOWED_LOGON_VERSION_SERVER=8
     SQLNET.ALLOWED_LOGON_VERSION_CLIENT=8
     ```

   - **tnsnames_ora_config**
     ```txt
     {NAMEBD} =
       (DESCRIPTION =
         (ADDRESS = (PROTOCOL = TCP)(HOST = {IPSERVER01})(PORT = {PORT}))
         (ADDRESS = (PROTOCOL = TCP)(HOST = {IPSERVER02})(PORT = {PORT}))
         (LOAD_BALANCE = yes)
         (CONNECT_DATA =
           (SERVER = DEDICATED)
           (SERVICE_NAME = {NAMEBD})
         )
       )
     ```

   ![Imagem 3](file:///mnt/data/9ad56503-8591-4bce-81b4-d0978b2908d3.png)

---

## Adicionando Credenciais no N8N

Para configurar corretamente as credenciais de acesso ao Oracle no N8N, acesse a interface de configuração de credenciais e adicione as informações do banco de dados:

![Imagem 4](file:///mnt/data/ab910f15-cf65-4b7a-9243-fbacb0cc1759.png)

---

## Deploy da Stack no Docker

Após configurar os arquivos necessários, faça o deploy da stack utilizando o Docker Compose:

```bash
docker-compose -f docker-compose.yml up -d
