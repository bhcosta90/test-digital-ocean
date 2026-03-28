# =========================
# BASE (sua imagem base)
# =========================
FROM bhcosta90/test-digital-ocean:0 as app

WORKDIR /var/www/html

COPY . .

EXPOSE 80

ENTRYPOINT ["./entrypoint.sh"]