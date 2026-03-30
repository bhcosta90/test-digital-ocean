#!/bin/sh

set -e

echo "🚀 Iniciando ambiente para $APP_NAME..."
echo "🔍 REDIS_PREFIX: $REDIS_PREFIX"

# Criar pastas caso não existam (importante para o comando view:cache)
mkdir -p ./storage/framework/cache/data \
         ./storage/framework/sessions \
         ./storage/framework/views \
         ./storage/logs \
         ./bootstrap/cache

# Garantir permissões em runtime (necessário para logs/cache)
chown -R www-data:www-data ./storage ./bootstrap/cache
chmod -R 775 ./storage ./bootstrap/cache

# Se o primeiro argumento for 'worker', rodar o worker e sair
if [ "$1" = "worker" ]; then
    echo "⏸️  Checking Horizon status..."
    # Usar || true para evitar que o set -e quebre o script se o Redis estiver inacessível
    php artisan horizon:pause || echo "⚠️  Horizon pause falhou (pode ser o primeiro deploy)"

    echo "⏳  Waiting for running jobs to finish..."
    while php artisan horizon:status 2>/dev/null | grep -q running; do
      echo "⏳  Still processing jobs... waiting 5s"
      sleep 5
    done

    echo "♻️  Restarting Horizon..."
    php artisan horizon:terminate || echo "⚠️  Horizon terminate falhou"

    echo "▶️  Starting Horizon..."
    exec php artisan horizon
fi

echo "📂 Verificando .env em $(ls -la ./.env 2>/dev/null || echo 'NÃO ENCONTRADO')"

# --- GERENCIAMENTO DE ENV ---
# Se existir a pasta ./envs, tentamos encontrar o .env correto
if [ -d "./envs" ]; then
    echo "📁 Pasta de configurações encontrada. Configurando .env..."
    
    # Prioridade 1: Linkar .env se existir
    if [ -f "./envs/.env" ]; then
        ln -sf ./envs/.env ./.env
        echo "🔗 Linkado ./envs/.env -> ./.env"
    fi

    # Prioridade 2: Linkar arquivo específico de PR (.env-BRANCH)
    # Tenta extrair a branch do REDIS_PREFIX (ex: repo-branch- -> branch)
    # Usamos sed para pegar o texto entre o primeiro '-' e o último '-'
    BRANCH_EXTRACTED=$(echo $REDIS_PREFIX | sed 's/^[^-]*-//;s/-$//')
    
    if [ -f "./envs/.env-$BRANCH_EXTRACTED" ]; then
        ln -sf ./envs/.env-$BRANCH_EXTRACTED ./.env
        echo "🔗 Linkado ./envs/.env-$BRANCH_EXTRACTED -> ./.env"
    fi
    
    # Se ainda não existe .env, pega o primeiro que encontrar na pasta
    if [ ! -f "./.env" ]; then
        FIRST_ENV=$(ls ./envs/.env* 2>/dev/null | head -n 1)
        if [ -n "$FIRST_ENV" ]; then
            ln -sf "$FIRST_ENV" ./.env
            echo "🔗 Linkado $FIRST_ENV -> ./.env (fallback)"
        fi
    fi
fi

echo "🚀 Rodando migrations (pode demorar na primeira vez)..."
php artisan migrate --force --no-interaction || echo "⚠️ Alerta: Migrations falharam, mas continuando..."

echo "⚡ Cacheando configurações..."
php artisan optimize || echo "⚠️ Alerta: optimize falhou, mas continuando..."

# Limpeza de caches antigos que podem travar a inicialização
rm -rf ./bootstrap/cache/*.php || echo "Não foi possível limpar cache do bootstrap"

echo "✅ Tarefas do Laravel concluídas!"

exec /usr/local/bin/docker-php-entrypoint-base.sh