#!/bin/bash
# filepath: /mnt/release-imagem.sh

set -euo pipefail

# CONFIGURAÇÕES
REPO_OWNER="romariormr"
REPO_NAME="n8n-oracle-docker"
DOCKER_IMAGE="romariobrito-n8n-oracle"
TAG="${1:-}"
TOKEN="${GITHUB_TOKEN:-}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# VALIDAÇÕES INICIAIS
if [ -z "$TAG" ]; then
    log_error "Uso: $0 <tag>"
    echo "Exemplo: $0 1.104.3"
    exit 1
fi

if [ -z "$TOKEN" ]; then
    log_error "Defina a variável de ambiente GITHUB_TOKEN com seu token do GitHub."
    echo "Export exemplo: export GITHUB_TOKEN=seu_token_aqui"
    exit 1
fi

# Verifica se a imagem Docker existe
if ! docker image inspect "${DOCKER_IMAGE}:${TAG}" > /dev/null 2>&1; then
    log_error "Imagem Docker '${DOCKER_IMAGE}:${TAG}' não encontrada!"
    echo "Imagens disponíveis:"
    docker images "${DOCKER_IMAGE}" || true
    exit 1
fi

TAR_NAME="n8n-oracle-${TAG}.tar"

# CONFIGURAÇÃO DO GIT
log_info "Configurando Git..."

# Configura estratégia de merge para evitar o erro de branches divergentes
git config pull.rebase false

# Verifica se estamos em um repositório Git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Não está em um repositório Git válido!"
    exit 1
fi

# VERIFICA E RESOLVE CONFLITOS
log_info "Verificando estado do repositório..."

# Verifica se há merge em progresso
if [ -f .git/MERGE_HEAD ]; then
    log_error "Merge em progresso detectado!"
    echo "Execute primeiro: ./fix-git-conflicts.sh"
    exit 1
fi

# Limpa estados inconsistentes do Git
if [ -d .git/rebase-merge ]; then
    log_warning "Rebase pendente detectado. Abortando rebase..."
    git rebase --abort 2>/dev/null || rm -rf .git/rebase-merge
fi

if [ -d .git/rebase-apply ]; then
    log_warning "Apply pendente detectado. Limpando..."
    rm -rf .git/rebase-apply
fi

# Verifica arquivos com conflito
CONFLICTED_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null || true)
if [ -n "$CONFLICTED_FILES" ]; then
    log_error "Arquivos com conflito detectados: $CONFLICTED_FILES"
    echo "Execute primeiro: ./fix-git-conflicts.sh"
    exit 1
fi

# SINCRONIZAÇÃO COM REPOSITÓRIO REMOTO
log_info "Sincronizando com repositório remoto..."

# Vai para branch master/main
MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "master")
if ! git checkout "$MAIN_BRANCH" 2>/dev/null && ! git checkout master 2>/dev/null; then
    log_error "Não foi possível acessar a branch principal."
    echo "Execute primeiro: ./fix-git-conflicts.sh"
    exit 1
fi

# Faz fetch antes do pull
git fetch origin

# Verifica se há conflitos locais
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    log_warning "Há alterações não commitadas. Fazendo stash..."
    git stash push -m "Auto-stash antes do release v${TAG}"
    STASHED=true
else
    STASHED=false
fi

# Faz pull com merge strategy
if ! git pull origin "$MAIN_BRANCH" --no-rebase; then
    log_error "Falha ao sincronizar com o repositório remoto."
    log_info "Resolva os conflitos manualmente e execute o script novamente."
    exit 1
fi

# Restaura stash se necessário
if [ "$STASHED" = true ]; then
    log_info "Restaurando alterações locais..."
    git stash pop || log_warning "Não foi possível restaurar stash automaticamente"
fi

# VERIFICA SE A RELEASE JÁ EXISTE
log_info "Verificando se a release v${TAG} já existe..."
HTTP_CODE=$(curl -s -w "%{http_code}" -o /tmp/release_check.json \
    -H "Authorization: token ${TOKEN}" \
    "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/tags/v${TAG}")

if [ "$HTTP_CODE" = "200" ]; then
    log_warning "Release v${TAG} já existe no GitHub. Abortando."
    rm -f /tmp/release_check.json
    exit 0
fi
rm -f /tmp/release_check.json

# EXPORTA A IMAGEM DOCKER
log_info "Salvando imagem Docker ${DOCKER_IMAGE}:${TAG}..."
if ! docker save "${DOCKER_IMAGE}:${TAG}" -o "${TAR_NAME}"; then
    log_error "Falha ao salvar a imagem Docker!"
    exit 1
fi

# Valida tamanho do arquivo TAR (máx 2GB para GitHub)
TAR_SIZE=$(stat -c%s "${TAR_NAME}")
MAX_SIZE=$((2*1024*1024*1024))
TAR_SIZE_MB=$((TAR_SIZE / 1024 / 1024))

log_info "Tamanho do arquivo: ${TAR_SIZE_MB}MB"

if [ "$TAR_SIZE" -ge "$MAX_SIZE" ]; then
    log_error "O arquivo ${TAR_NAME} excede 2GB (${TAR_SIZE_MB}MB). GitHub tem limite de 2GB por arquivo."
    log_info "Considere otimizar sua imagem Docker ou usar Docker Hub."
    rm -f "${TAR_NAME}"
    exit 1
fi

# COMMITA MUDANÇAS NO GIT (se houver) - EXCLUINDO ARQUIVOS .tar
log_info "Verificando alterações para commit..."

# Garante que arquivos .tar não sejam commitados
echo "*.tar" >> .gitignore
echo "*.tar.gz" >> .gitignore
echo "*.zip" >> .gitignore
sort .gitignore | uniq > .gitignore.tmp && mv .gitignore.tmp .gitignore

# Remove o arquivo TAR do staging se estiver lá
git reset HEAD "${TAR_NAME}" 2>/dev/null || true
git reset HEAD "*.tar" 2>/dev/null || true

# Adiciona apenas arquivos necessários (exclui .tar)
git add .gitignore
git add -A
git reset HEAD "*.tar" 2>/dev/null || true

if ! git diff --cached --quiet; then
    log_info "Commitando alterações (excluindo arquivos .tar)..."
    git commit -m "feat: release v${TAG} - ${DOCKER_IMAGE}"
    
    if ! git push origin "$MAIN_BRANCH"; then
        log_error "Falha ao fazer push. Resolva conflitos e tente novamente."
        rm -f "${TAR_NAME}"
        exit 1
    fi
    log_success "Alterações commitadas e enviadas!"
else
    log_info "Nenhuma alteração para commit."
fi

# CRIA RELEASE VIA API DO GITHUB
log_info "Criando release v${TAG} no GitHub..."

# Gera changelog básico
CHANGELOG="## 🐳 Release da Imagem Docker N8N com Oracle

**Imagem:** \`${DOCKER_IMAGE}:${TAG}\`

### 📋 Funcionalidades
- ✅ N8N versão ${TAG}
- ✅ Suporte completo ao Oracle Database
- ✅ Drivers Oracle pré-instalados
- ✅ Otimizada para produção

### 🚀 Como usar
\`\`\`bash
# Baixar e extrair
wget https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/v${TAG}/${TAR_NAME}
docker load -i ${TAR_NAME}

# Executar
docker run -d -p 5678:5678 ${DOCKER_IMAGE}:${TAG}
\`\`\`

### 📊 Informações
- **Tamanho:** ${TAR_SIZE_MB}MB
- **Data:** $(date '+%Y-%m-%d %H:%M:%S')
"

CREATE_JSON=$(cat <<EOF
{
  "tag_name": "v${TAG}",
  "target_commitish": "${MAIN_BRANCH}",
  "name": "🚀 N8N Oracle v${TAG}",
  "body": $(echo "$CHANGELOG" | jq -Rs .),
  "draft": false,
  "prerelease": false
}
EOF
)

RESPONSE=$(curl -s -H "Authorization: token ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$CREATE_JSON" \
    "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases")

# Extrai URL de upload
UPLOAD_URL=$(echo "$RESPONSE" | jq -r '.upload_url // empty' | cut -d'{' -f1)

if [ -z "$UPLOAD_URL" ]; then
    log_error "Erro ao criar release no GitHub."
    echo "Resposta da API:"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    rm -f "${TAR_NAME}"
    exit 1
fi

log_success "Release criada com sucesso!"

# UPLOAD DO ARQUIVO TAR
log_info "Fazendo upload do arquivo ${TAR_NAME}..."
log_info "Isso pode demorar alguns minutos dependendo da sua conexão..."

if curl --fail --progress-bar \
    -H "Authorization: token ${TOKEN}" \
    -H "Content-Type: application/x-tar" \
    --data-binary @"${TAR_NAME}" \
    "${UPLOAD_URL}?name=${TAR_NAME}"; then
    
    log_success "Upload concluído com sucesso!"
else
    log_error "Falha no upload do arquivo TAR."
    rm -f "${TAR_NAME}"
    exit 1
fi

# LIMPEZA
rm -f "${TAR_NAME}"

# RESUMO FINAL
echo
echo "🎉 =================================="
log_success "Release v${TAG} criada com sucesso!"
echo "🔗 URL: https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/tag/v${TAG}"
echo "📦 Imagem: ${DOCKER_IMAGE}:${TAG}"
echo "💾 Tamanho: ${TAR_SIZE_MB}MB"
echo "===================================="