# =========================
# BASE (sua imagem base)
# =========================
FROM bhcosta90/test-digital-ocean:base AS base

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
# ASSETS (NODE)
# =========================
FROM node:20-alpine AS node_builder

WORKDIR /var/www/html

COPY package.json package-lock.json* ./
RUN npm install

COPY . .
RUN npm run build

# =========================
# APP
# =========================
FROM base AS app

COPY --from=vendor /var/www/html/vendor /var/www/html/vendor
COPY --from=node_builder /var/www/html/public/build /var/www/html/public/build
COPY . .

RUN chmod +x ./entrypoint.sh

# Garantir que a estrutura de pastas do storage existe
RUN mkdir -p storage/framework/cache/data \
             storage/framework/sessions \
             storage/framework/views \
             storage/logs \
             bootstrap/cache

RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 storage bootstrap/cache

ENTRYPOINT ["./entrypoint.sh"]

# =========================
# DEV (for local development)
# =========================
FROM app AS dev
ENTRYPOINT ["/entrypoint.sh"]

# =========================
# FINAL
# =========================
FROM base

COPY --from=app /var/www/html /var/www/html

RUN chmod +x ./entrypoint.sh

WORKDIR /var/www/html

# =========================
# START
# =========================
EXPOSE 80

ENTRYPOINT ["./entrypoint.sh"]