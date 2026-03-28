# =========================
# BASE (sua imagem base)
# =========================
FROM bhcosta90/test-digital-ocean:0 as app

WORKDIR /var/www/html

COPY . .

RUN composer install \
    --no-dev \
    --prefer-dist \
    --no-interaction \
    --no-scripts \
    --optimize-autoloader

RUN chmod +x ./entrypoint.sh

EXPOSE 80

ENTRYPOINT ["./entrypoint.sh"]