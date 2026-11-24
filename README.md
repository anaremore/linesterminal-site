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

Then check the deploy: the script waits until the live page matches your local `index.html` (the old container keeps serving for a minute or two after Clank reports "active"), then requires HTTP 200 for every referenced asset:

```sh
scripts/check-assets.sh                    # https://linesterminal.com
scripts/check-assets.sh http://localhost:8080
```

Error responses are sent with `Cache-Control: no-store` (see `Caddyfile`), so a 404 seen during a rolling deploy is never cached by Cloudflare.

## Updating the site

With each `lines` release:

- **Roadmap:** refresh the block marked `<!-- ROADMAP -->` in `index.html` (Shipped / In progress / Next) to match the release notes.
- **Version:** nothing to change. The page script fills in the newest release's version and download links from the GitHub API; without JS the page says "Download" / "Latest release" and links to the releases page (`/releases/latest`, which GitHub redirects to the list while every release is a pre-release).
- **Screenshots:** if the UI changed noticeably, replace the PNGs in `assets/` and regenerate the `.webp` copies and `og.png`. Synthetic data only (decision 0010 in `lines`): sessions from `lines`' `synth_natural` example (`--seed 7 --depth`), shot with `--at 2026-11-05T20:15:00Z`, the README workspaces in `lines` `docs/img/*.json` with the outer split ratio at 0.75 (a narrower DOM) and the paper script `buy 2 @ 6060.50 bracket 8/16; ack; buy 1 @ 6056.00; ack` (recipe: `lines` `docs/architecture.md`, "README images"). `hero-mobile` is a 624x312 crop of the hero rendered with `--ui-zoom 125`; `og.png` is the hero scaled to 1200 wide and cropped to 630 tall. PNGs are quantized to 256 colors; WebPs are lossless.
- **Cache-busting:** asset links in `index.html` carry `?v=YYYYMMDD` (assets are cached for a day, and Cloudflare caches them too). Whenever an image or icon changes, bump it on every asset link at once, e.g. `sed -i 's/?v=20261124/?v=YYYYMMDD/g' index.html`, so nothing keeps serving the old copy.
