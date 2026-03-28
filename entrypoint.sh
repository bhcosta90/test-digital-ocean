#!/bin/sh

set -e

echo "🚀 Iniciando ambiente..."

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
    echo "⚡ Iniciando Worker..."
    exec php artisan queue:work --verbose --tries=3 --timeout=90
fi

echo "🚀 Rodando migrations (pode demorar na primeira vez)..."
php artisan migrate --force --no-interaction || echo "⚠️ Alerta: Migrations falharam, mas continuando..."

echo "⚡ Cacheando configurações..."
php artisan optimize || echo "⚠️ Alerta: optimize falhou, mas continuando..."

# Limpeza de caches antigos que podem travar a inicialização
rm -rf ./bootstrap/cache/*.php || echo "Não foi possível limpar cache do bootstrap"

echo "✅ Tarefas do Laravel concluídas!"

exec /usr/local/bin/docker-php-entrypoint-base.sh