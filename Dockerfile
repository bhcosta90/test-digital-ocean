# =========================
# BASE (sua imagem base)
# =========================
FROM bhcosta90/test-digital-ocean:0 as app

WORKDIR /var/www/html

COPY . .

RUN chmod +X ./entrypoint.sh

EXPOSE 80

ENTRYPOINT ["./entrypoint.sh"]