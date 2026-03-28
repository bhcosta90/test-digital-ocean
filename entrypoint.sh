#!/bin/sh

set -e

echo "🚀 Iniciando ambiente..."

# Criar pastas caso não existam (importante para o comando view:cache)
mkdir -p /var/www/html/storage/framework/cache/data \
         /var/www/html/storage/framework/sessions \
         /var/www/html/storage/framework/views \
         /var/www/html/storage/logs \
         /var/www/html/bootstrap/cache

# Garantir permissões em runtime (necessário para logs/cache)
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

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
rm -rf /var/www/html/bootstrap/cache/*.php || echo "Não foi possível limpar cache do bootstrap"

echo "✅ Tarefas do Laravel concluídas!"

exec /usr/local/bin/docker-php-entrypoint-base.sh