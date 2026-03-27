# =========================
# BASE (sua imagem base)
# =========================
FROM bhcosta90/laravel-base:test-digital-ocean AS base

WORKDIR /var/www/html

# =========================
# CORREÇÃO PHP-FPM (ARQUIVO CERTO!)
# =========================
RUN sed -i 's|listen = .*|listen = 9000|' /usr/local/etc/php-fpm.d/docker.conf

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
# NGINX INLINE CONFIG
# =========================
RUN rm -f /etc/nginx/conf.d/default.conf && \
    cat <<'EOF' > /etc/nginx/conf.d/default.conf
server {
    listen 80;
    index index.php index.html;
    root /var/www/html/public;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include fastcgi.conf;
        fastcgi_pass 127.0.0.1:9000;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# =========================
# ENTRYPOINT
# =========================
RUN cat <<'EOF' > /entrypoint.sh
#!/bin/sh

echo "🚀 Subindo PHP-FPM..."
php-fpm -D

echo "⏳ Aguardando PHP-FPM..."
sleep 2

echo "🚀 Rodando migrations..."
php artisan migrate --force || true

echo "⚡ Cacheando Laravel..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "🚀 Subindo Nginx..."
nginx -g 'daemon off;'
EOF

RUN chmod +x /entrypoint.sh

# =========================
# START
# =========================
EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]