#!/bin/sh

echo "🚀 Rodando migrations..."
php artisan migrate --force

echo "🧹 Limpando caches..."
php artisan config:clear
php artisan cache:clear

echo "🔥 Otimizando..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "✅ Subindo aplicação..."

exec "$@"