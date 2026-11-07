FROM caddy:2-alpine
COPY index.html favicon.svg favicon.ico /srv/
COPY assets /srv/assets
COPY Caddyfile /etc/caddy/Caddyfile
EXPOSE 80
