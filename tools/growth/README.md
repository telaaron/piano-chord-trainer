# Growth tooling (SEO / GEO / market data)

Vetted 15.10.2026, see `/mnt/project-files/growth/2026-10-15-growth-tools-bewertung.md` in the project.

## claude-seo (plugin, pinned)

`.claude/settings.json` enables `claude-seo@jazzchords-growth` from the local marketplace in
`.claude/growth-marketplace/`, which pins AgriciDaniel/claude-seo to commit `4b99de2` (v2.4.2, MIT).
Bump the `sha` only after reading the upstream diff. First use: `/seo setup` (creates an isolated
Python env in plugin data), then `/seo audit https://jazzchords.app`, `/seo geo …`, `/seo schema …`.

## connectors/ (vendored, Python stdlib only, no keys)

Copied from aaron-he-zhu/aaron-marketing-skills `scripts/connectors/` at commit `e1e56a1`
(Apache-2.0, see `connectors/LICENSE`). Only the helpers are vendored; the plugin itself is not
installed because its hooks run on every tool call.

Useful ones: `onpage.py`, `schema_lint.py`, `robots.py`, `sitemap.py`, `appstore.py` (ASO /
competitor apps), `suggest.py` (autocomplete ideas), `hn.py`, `psi.py` (PageSpeed, free key).
Run with `python3 -I tools/growth/connectors/<helper>.py …`.

Cloud sessions: the helpers resolve DNS themselves and bypass the egress proxy, so live fetches
fail there. Fetch the page another way (e.g. Vercel MCP `web_fetch_vercel_url`) and pass it with
`--html <file>`.
