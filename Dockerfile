# =========================
# BASE (sua imagem base)
# =========================
FROM bhcosta90/test-digital-ocean:0 AS base

WORKDIR /var/www/html

# =========================
# DEPENDENCIES (CACHE)
# =========================
FROM base AS vendor

COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --prefer-dist \
    --no-interaction \
    --no-scripts \
    --optimize-autoloader

# =========================
# APP
# =========================
FROM base AS app

COPY --from=vendor /var/www/html/vendor /var/www/html/vendor
COPY . .

RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 storage bootstrap/cache

# =========================
# FINAL
# =========================
FROM base

COPY --from=app /var/www/html /var/www/html

WORKDIR /var/www/html

# =========================
# ENTRYPOINT
# =========================
RUN cat <<'EOF' > /entrypoint.sh
#!/bin/sh

echo "🚀 Iniciando ambiente..."

# Garantir permissões em runtime (necessário para logs/cache)
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

echo "🚀 Subindo PHP-FPM..."
php-fpm -D

echo "⏳ Aguardando PHP-FPM estabilizar..."
# Loop de verificação rápida do PHP-FPM
for i in $(seq 1 10); do
    if netstat -an | grep :9000 > /dev/null; then
        echo "✅ PHP-FPM pronto!"
        break
    fi
    echo "..."
    sleep 1
done

echo "🚀 Rodando migrations (pode demorar na primeira vez)..."
php artisan migrate --force --no-interaction || echo "⚠️ Alerta: Migrations falharam, mas continuando..."

echo "⚡ Cacheando configurações..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "🚀 Subindo Nginx..."
# Testar config antes de subir
nginx -t

# Subir Nginx em background para podermos monitorar se ele morre
nginx

echo "✅ Container pronto e rodando!"

# Manter o container vivo e logando
tail -f /var/log/nginx/access.log /var/log/nginx/error.log
EOF

RUN chmod +x /entrypoint.sh

# =========================
# START
# =========================
EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]