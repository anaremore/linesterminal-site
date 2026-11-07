# linesterminal.com

Landing page for [Lines Terminal](https://github.com/anaremore/lines).

Static HTML and images served by Caddy (`caddy:2-alpine`) on port 80, deployed on Clank.

## Run locally

```sh
docker build -t linesterminal-site .
docker run --rm -p 8080:80 linesterminal-site
# open http://localhost:8080
```

## Files

- `index.html`: the page
- `*.png`: screenshots
- `Caddyfile`: static file server config (gzip, 1-day cache on PNGs)
- `Dockerfile`: image build
