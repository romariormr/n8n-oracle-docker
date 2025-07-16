````markdown
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
````

---

# 🇧🇷 N8N com Suporte Oracle - Docker Image

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

## 🔧 Configurando Oracle no N8N

Para utilizar o Oracle no N8N, você precisa realizar algumas configurações no seu ambiente Docker. Siga os passos abaixo:

### 1. Verifique se o `docker-compose.yml` possui as configurações corretas:

<img width="557" height="191" alt="image" src="https://github.com/user-attachments/assets/36bb1155-eb74-4802-9170-627c94ac3776" />

### 2. Crie os arquivos de configuração `sqlnet.ora` e `tnsnames.ora` no Portainer (ou CLI):

<img width="447" height="465" alt="image" src="https://github.com/user-attachments/assets/9a31d803-4a2a-443d-815f-1d0ac920e6e0" />

#### Conteúdo do `sqlnet_ora_config`:

```txt
SQLNET.ALLOWED_LOGON_VERSION_SERVER=8
SQLNET.ALLOWED_LOGON_VERSION_CLIENT=8
```

#### Conteúdo do `tnsnames_ora_config`:

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

<img width="455" height="513" alt="image" src="https://github.com/user-attachments/assets/3d143573-d883-4a31-b9f1-38772e5002f0" />

---

## 🔐 Adicionando Credenciais no N8N

Na interface gráfica do N8N, vá em *Credenciais → Oracle Database* e configure como no exemplo abaixo:

<img width="715" height="559" alt="image" src="https://github.com/user-attachments/assets/3e839f0c-e317-4b27-93ca-399054cfe12f" />

---

## 🚀 Deploy da Stack no Docker

Após configurar os arquivos necessários, faça o deploy da stack utilizando o Docker Compose:

```bash
docker-compose -f docker-compose.yml up -d
```

---

## 🧠 Configuração do Banco de Dados

Certifique-se de que a conexão ao Oracle está funcionando corretamente. Caso necessário, verifique permissões de rede, listener do Oracle e logs da aplicação N8N.

---

## ❤️ Doações

Se este projeto lhe ajudou, considere apoiar com uma doação. Isso me motiva a continuar melhorando!

### 💳 [Doar com Mercado Pago](http://link.mercadopago.com.br/romariobrito)

---

📧 Para dúvidas ou sugestões, entre em contato ou abra uma issue.

```
