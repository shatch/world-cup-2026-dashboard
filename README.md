# World Cup 2026 — Where & When to Watch

A single-file, zero-dependency dashboard that answers one question for a US viewer: **for every 2026 FIFA World Cup match, when does it kick off (Eastern), what channel is it on, and where can I stream it?**

All 104 matches, June 11 – July 19, 2026, hosted across the USA, Canada, and Mexico.

![Status](https://img.shields.io/badge/matches-104-1FB87A) ![Dependencies](https://img.shields.io/badge/dependencies-0-2DE89A) ![Build](https://img.shields.io/badge/build-none-F0B33A)

## Highlights

- **Every match, grouped by day** with sticky date headers; auto-scrolls to today on load.
- **English & Spanish TV** per match — FOX/FS1 and Telemundo/Universo chips on every row.
- **Streaming** stated once (it's the same for all games): FOX One (English), Peacock (Spanish), Fubo (all).
- **Search** across team, venue, and round.
- **Filters** — round, team, and FOX-vs-FS1 dropdowns.
- **Toggles** — Today, Upcoming, and Watch Party mode.
- **Quick-pick chips** — one-tap host (🇺🇸 USA / 🇲🇽 Mexico / 🇨🇦 Canada) and contender (Brazil, Argentina, France, England, Spain, Germany, Portugal, Netherlands) filters (tap again to clear).
- **Live scores & status** — hydrates real scores, live clock, and Live/FT/Upcoming state from a free public feed (client-side, no backend), with a graceful fallback to the static schedule when offline.
- **Dynamic bracket** — knockout matchups fill in real team names as FIFA sets them (showing seeding placeholders like `1C vs 2F` until then).
- **Timezone selector** — view kickoff times in Eastern (default), your local zone, or other presets; the calendar export stays absolute.
- **Calendar export (`.ics`)** — download upcoming matches that match your current filters, in two modes.
- **Social share** — one-tap X / Facebook / LinkedIn / WhatsApp / copy-link buttons with viral, filter-aware pre-filled copy (sharing while filtered to a team yields "Every USA match…").
- **Responsive** down to mobile, with a quiet dark aesthetic.

## Quick start

There is nothing to build or install. Either:

```bash
# Open directly
open index.html            # macOS

# …or serve the folder
python3 -m http.server
# then visit http://localhost:8000
```

Markup, styles, data, and logic are all inline in `index.html`; the only local asset is `hero.jpg` (the header background, referenced relatively), and the only network dependencies are Google Fonts and the live-score feed. The favicon is an inline SVG soccer emoji (no file).

## Calendar export

Click **⤓ Add to calendar** to download a standard `.ics` file. The export always **excludes finished games** and **respects your active filters** — so filtering to USA and exporting yields only their remaining fixtures. Two modes, switched by the **Watch party** toggle:

- **Per-match** — one 2-hour event per game, with the venue as the location and both-language channels in the description.
- **Watch party** — one event per day spanning the first kickoff to the last match end, with every game that day listed in the description. Bundles a matchday into a single calendar block.

> If the in-frame download does nothing (sandboxed preview), open the page in its own browser tab.

## How it works

Everything lives in `index.html`: an inline `<style>` (dark theme via CSS custom properties), the markup, and an inline `<script>` that holds **both the data and the logic**.

- **`M`** — the match array, the single source of truth. Each entry is a compact object: `d` (date), `t` (display time, e.g. `"3:00 PM"` or `"FT"`), `sk` (intra-day sort key — the hour in 24h; `24` = post-midnight game listed under the prior day; fractional parts are tiebreakers, **not** minutes), `h`/`a` (teams, omitted for unresolved knockouts), `res` (score), `grp` (round), `v` (venue), `tv` (`"FOX"`/`"FS1"`), and `desc` (knockout matchup like `"1C vs 2F"`).
- **Derived at load** — `_st` (live/up/ft status) and `es` (Spanish channel: a hardcoded set of 12 group-stage games on Universo, the rest on Telemundo).
- **`state` → `passes(m)` → `render()`** — `state` holds all filters, `passes` decides visibility, `render` regroups visible matches by day and builds HTML via `card(m)`. Every control change triggers a full re-render.
- **Live-data layer (client-side, offline-first)** — after the static render, `hydrate()` fetches the unofficial ESPN `fifa.world/scoreboard` feed (no key, CORS-enabled), matches events to `M` by absolute kickoff instant (`startUTC`) + team pair, and overlays live status/score (`_scoreH`/`_scoreA`/`_detail`) and resolved knockout teams (`_th`/`_ta`). A name map handles the few ESPN naming differences. Polling is visibility-aware (faster during live windows, paused when the tab is hidden); any failure falls back silently to the static schedule.

### Time handling

All kickoff labels are **Eastern**. The clock math assumes **EDT (UTC−4)** because the tournament runs in summer; "today" is resolved in `America/New_York` so highlighting and auto-scroll are correct regardless of the viewer's timezone. Midnight (`12:00 AM ET`) games are shown under the prior matchday — matching FOX — but their real datetime rolls to the next calendar day in the `.ics` export.

## Data & provenance

Match data is **hardcoded**, not fetched — there's no stable, free per-match World Cup API with US broadcast assignments, and the schedule is fixed. The source-of-truth hierarchy:

- English channel (FOX vs FS1), kickoff times, and venues come from **FOX's published schedule** (the rights holder). Where sources disagree on English times/channels, FOX wins.
- The Spanish-language Telemundo/Universo split and the third-place match time come from a **secondary source** (FOX doesn't publish the Spanish split).

To update the schedule or scores, edit the objects in the `M` array. Adding a team requires a matching entry in `FLAGS` or it falls back to ⚽.

## Known limitations

- **Unofficial live feed** — live scores/status and knockout teams come from ESPN's *unofficial* `fifa.world` endpoint, which can change or break without notice. The app degrades gracefully to the static `M` data; the freshness indicator in the header shows whether live data is connected.
- **Default ET, EDT under the hood** — labels read "ET" and mean EDT. The timezone selector reformats other zones from each match's absolute instant, but **day-grouping stays by tournament matchday** (a late ET game keeps its matchday even if it shows a next-day local time).
- **Spanish channel split** is from a secondary source — re-verify the 12-game Universo set if the network revises it.
- **No persistent storage** — `localStorage` is intentionally avoided (blocked in sandboxed previews); all state, including the timezone choice, is in memory.

## Deploying

It's a static page — host it anywhere that serves files: GitHub Pages, Netlify,
Vercel, Cloudflare Pages, an S3 bucket, or any web server. Just publish
`index.html` and `hero.jpg` together (the page references `hero.jpg` with a
relative path). No build step, no environment variables, no server-side code.

The share links use the page's own URL automatically, so they work on whatever
domain you deploy to.

## Possible next steps

- A group-standings table derived from results.
- Goal-scorer / match-detail expansion per card (the ESPN feed carries more than score + status).
- Per-zone day-grouping when a non-Eastern timezone is selected.

## Contributing

Issues and pull requests are welcome. The whole app is one `index.html`, so
changes are easy to make and review — open it in a browser and you're developing.

## License

[MIT](./LICENSE) © Steve Hatch. Built with [Claude](https://claude.com/claude-code).

---

See [`CLAUDE.md`](./CLAUDE.md) for guidance when working in this repo with Claude Code.
