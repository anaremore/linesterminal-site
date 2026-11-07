FROM caddy:2-alpine
COPY index.html chart-orders-footprint.png tick-chart.png light.png /srv/
COPY Caddyfile /etc/caddy/Caddyfile
EXPOSE 80
