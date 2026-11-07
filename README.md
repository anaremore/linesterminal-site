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
- `assets/`: screenshots (WebP + PNG), icon, favicons, OG image
- `favicon.svg`, `favicon.ico`: from the `lines` app icon
- `Caddyfile`: static file server config (compression, /health for Clank, 1-day cache on assets)
- `Dockerfile`: image build

## Deploying

Pushes to `main` auto-deploy on Clank (service `linesterminal`). To deploy by hand:

```sh
clank deploy 5a6719bf-0584-4f31-b786-0de822bf5dde --no-follow --wait
```

Then check that every referenced asset is served:

```sh
scripts/check-assets.sh                    # https://linesterminal.com
scripts/check-assets.sh http://localhost:8080
```

Error responses are sent with `Cache-Control: no-store` (see `Caddyfile`), so a 404 seen during a rolling deploy is never cached by Cloudflare.

## Updating the site

With each `lines` release:

- **Roadmap:** refresh the block marked `<!-- ROADMAP -->` in `index.html` (Shipped / In progress / Next) to match the release notes.
- **Version:** the page script fills in the newest release's version and download links from the GitHub API, but update the `vX.Y.Z` fallbacks in `index.html` (hero button, "Latest release", the three download links) so the page is right without JS.
- **Screenshots:** if the UI changed noticeably, replace the PNGs in `assets/` and regenerate the `.webp` copies and `og.png`.
