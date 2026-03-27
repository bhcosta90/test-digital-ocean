# BASE
FROM php:8.3-apache AS base

RUN apt-get update && apt-get install -y \
    git unzip curl libpng-dev \
    && docker-php-ext-install pdo pdo_mysql mbstring bcmath gd

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

RUN a2enmod rewrite
RUN sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf

# DEV
FROM base AS dev

COPY composer.json composer.lock ./
RUN composer install

# PROD
FROM base AS prod

COPY . .
RUN composer install --no-dev --optimize-autoloader

RUN chown -R www-data:www-data /var/www/html