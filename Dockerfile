# =========================
# BASE
# =========================
FROM php:8.4-apache AS base

# Instala dependências do sistema + extensões PHP
RUN apt-get update && apt-get install -y \
    git unzip curl \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        pdo \
        pdo_mysql \
        mbstring \
        bcmath \
        gd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Apache config
RUN a2enmod rewrite
RUN sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf

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

# Copia dependências já instaladas
COPY --from=vendor /var/www/html/vendor /var/www/html/vendor

# Copia aplicação
COPY . .

# Otimizações Laravel (sem depender de DB)
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