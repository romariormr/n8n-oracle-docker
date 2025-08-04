#!/bin/bash
# filepath: /mnt/cleanup-large-files.sh

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

echo "🧹 Limpando Arquivos Grandes do Git"
echo "==================================="

# Verifica se há commits para desfazer
log_info "Verificando commits recentes..."
git log --oneline -5

echo
log_warning "O último commit contém arquivos grandes que impedem o push."
echo
echo "Opções:"
echo "1. Desfazer o último commit (mantém as alterações nos arquivos)"
echo "2. Desfazer e remover todas as alterações"
echo "3. Apenas remover arquivos .tar do commit"
echo "4. Sair sem alterações"
echo

read -p "Escolha uma opção (1-4): " choice

case $choice in
    1)
        log_info "Desfazendo último commit (mantendo alterações)..."
        git reset --soft HEAD~1
        log_success "Commit desfeito! Arquivos ainda estão em staging."
        
        # Remove arquivos .tar do staging
        log_info "Removendo arquivos .tar do staging..."
        git reset HEAD "*.tar" 2>/dev/null || true
        git reset HEAD "n8n-oracle-*.tar" 2>/dev/null || true
        
        # Remove os arquivos .tar fisicamente
        rm -f *.tar
        rm -f n8n-oracle-*.tar
        
        log_success "Arquivos .tar removidos!"
        ;;
    2)
        log_info "Desfazendo último commit e removendo alterações..."
        git reset --hard HEAD~1
        rm -f *.tar
        rm -f n8n-oracle-*.tar
        log_success "Commit e alterações removidos!"
        ;;
    3)
        log_info "Removendo apenas arquivos .tar do último commit..."
        
        # Desfaz o commit
        git reset --soft HEAD~1
        
        # Remove arquivos .tar do staging
        git reset HEAD "*.tar" 2>/dev/null || true
        git reset HEAD "n8n-oracle-*.tar" 2>/dev/null || true
        
        # Remove os arquivos .tar fisicamente
        rm -f *.tar
        rm -f n8n-oracle-*.tar
        
        # Adiciona .gitignore se não existir
        if [ ! -f .gitignore ]; then
            touch .gitignore
        fi
        
        # Atualiza .gitignore
        echo "*.tar" >> .gitignore
        echo "*.tar.gz" >> .gitignore
        echo "*.zip" >> .gitignore
        sort .gitignore | uniq > .gitignore.tmp && mv .gitignore.tmp .gitignore
        
        # Faz novo commit sem os arquivos .tar
        git add .
        git commit -m "feat: scripts de release (sem arquivos binários)"
        
        log_success "Commit refeito sem arquivos .tar!"
        ;;
    4)
        log_info "Saindo sem alterações..."
        exit 0
        ;;
    *)
        log_error "Opção inválida!"
        exit 1
        ;;
esac

# Atualiza .gitignore
log_info "Atualizando .gitignore..."
if [ ! -f .gitignore ]; then
    touch .gitignore
fi

cat >> .gitignore << 'EOF'
# Arquivos de imagem Docker
*.tar
*.tar.gz
*.zip

# Arquivos temporários
*.tmp
*.temp

# Logs
*.log
EOF

# Remove duplicatas no .gitignore
sort .gitignore | uniq > .gitignore.tmp && mv .gitignore.tmp .gitignore

git add .gitignore
if ! git diff --cached --quiet; then
    git commit -m "chore: atualiza .gitignore para excluir arquivos grandes"
    log_success ".gitignore atualizado!"
fi

# Tenta fazer push
log_info "Tentando fazer push..."
if git push origin master; then
    log_success "Push realizado com sucesso!"
else
    log_error "Falha no push. Pode haver outros conflitos."
    echo
    echo "Execute git status para mais informações."
fi

echo
log_success "✨ Limpeza concluída!"
echo
echo "Agora você pode executar:"
echo "./release-imagem.sh 1.104.3"