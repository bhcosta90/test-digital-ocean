# =========================
# BASE (agora vem do Docker Hub)
# =========================
FROM bhcosta90/laravel-base:php-apache-8.4 AS base

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
# PRODUCTION
# =========================
FROM base AS prod

# Copia vendor já pronto
COPY --from=vendor /var/www/html/vendor /var/www/html/vendor

# Copia aplicação
COPY . .

# Otimizações Laravel
RUN php artisan config:clear \
    && php artisan route:clear \
    && php artisan view:clear \
    && php artisan optimize

# Permissões
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 storage bootstrap/cache

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]