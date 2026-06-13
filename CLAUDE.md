# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

A static, zero-dependency dashboard listing all 104 FIFA World Cup 2026 matches (June 11 – July 19, 2026) with kickoff times (timezone-selectable, ET default), English/Spanish TV channels, streaming options, filtering, live scores, and `.ics` calendar export. No build step, no package manager, no tests, no backend. Effectively one file — `index.html` holds all markup/styles/data/logic — plus a single image asset, `hero.jpg` (header background, referenced relatively); the favicon is an inline SVG emoji. `deploy.sh` syncs both files to the blog.

See `HANDOFF.md` for the full build rationale, data provenance, and a detailed caveats list — read it before making non-trivial changes.

### Data provenance (source-of-truth hierarchy)

Match data is hardcoded, not fetched: there's no stable per-match World Cup API with US broadcast assignments. When updating data, preserve this hierarchy — English channel (FOX/FS1), kickoff times, and venues come from **FOX's published schedule** (the rights holder); the Spanish-language Telemundo/Universo split and the third-place match time come from a **secondary source** (FOX doesn't publish the Spanish split). Where sources disagree on English times/channels, **FOX wins**.

## Running / developing

Open `index.html` directly in a browser, or serve the folder (e.g. `python3 -m http.server`) and load it. There is nothing to build or install. Fonts load from Google Fonts over the network; everything else (CSS, JS, data) is inline.

## Architecture

Everything is in `index.html`: inline `<style>` for the dark theme (CSS custom properties in `:root`), markup for header/controls/board, and an inline `<script>` holding both the data and the app logic. Key pieces, in script order:

- **`M`** (the match array) — the single source of truth. Each match is a compact object: `d` (date `YYYY-MM-DD`), `t` (display time string, e.g. `"3:00 PM"`, or `"FT"`/`"TBD"`), `sk` (sort key: the kickoff hour 0–24; `24` means a post-midnight game listed under the prior day; fractional parts like `.1`/`.5` are tiebreakers for same-hour matches), `h`/`a` (home/away team, omitted for knockout placeholders), `res` (score, present ⇒ played), `grp` (round label, e.g. `"Group A"`, `"Round of 32"`, `"Final"`), `v` (venue), `tv` (English channel `"FOX"`/`"FS1"`), and `desc` (knockout matchup text like `"1C vs 2F"` when teams aren't known).
- **`FLAGS`** — team-name → emoji flag lookup.
- **Derived data** — on load, `M.forEach` sets `m._st` (live/up/ft status via `matchStatus`) and `m.es` (Spanish channel: `"Universo"` for the 12 games in the `UNIVERSO` set, else `"Telemundo"`).
- **Date/status helpers** — all times are hard-coded Eastern; `startUTC`/`matchStatus` assume **EDT = UTC−4** (summer-only, fine for this tournament). `etTodayStr()` computes "today" in `America/New_York`. Note: labels read "ET" and represent EDT; the user originally asked for "EST" but every broadcaster lists ET/EDT, so the clock math uses −4 (a deliberate, flagged decision). If literal EST is ever required, shift displayed labels by one hour and the `.ics` UTC math too.

- **Live-data layer (ESPN, client-side, offline-first)** — after the initial static render, `hydrate(dates)` fetches the unofficial ESPN `fifa.world/scoreboard` feed (`ESPN_BASE`, no key, CORS `*`) and `applyEvents` overlays it onto `M`: it matches each ESPN event to a match by **nearest `startUTC` instant (±90 min) plus team pair**, then sets `_st` (from ESPN `pre/in/post`), live `_scoreH`/`_scoreA`/`_detail`, and — for knockouts — resolved teams `_th`/`_ta` (skipping placeholder strings like "Group A 2nd Place"). `ESPN_NAME` maps the few naming differences (`United States`→USA, `Bosnia-Herzegovina`→…, `Congo DR`→DR Congo); unmapped names hit a `console.warn`. Startup does one full-range backfill; `schedulePoll` then polls a 3-day window, faster during live windows and paused when the tab is hidden (`visibilitychange`). **All fetches are `try/catch` — any failure silently keeps the static data.** The header `#fresh` indicator shows whether live data is connected.
- **Streaming is per-language, not per-match** — identical for every game (FOX One = English, Peacock = Spanish, Fubo = all), so it's stated once rather than stored per row. Only the linear TV channel (FOX/FS1, Telemundo/Universo) varies per match.
- **`state` + `passes(m)` + `render()`** — `state` holds all active filters; `passes` decides visibility; `render` regroups visible matches by day and builds HTML via `card(m)`. Re-render is full-innerHTML on every control change.
- **`.ics` export** — `buildICS` (one event per match) and `buildPartyICS` (one event per day, grouped) generate calendar files; the "Watch party" toggle switches between them. Export only includes matches that pass current filters and aren't full-time.

## Editing notes

- To change schedule/scores, edit objects in the `M` array. Adding a team requires a matching `FLAGS` entry or it falls back to ⚽.
- `sk` controls ordering within a day and the post-midnight rollover — keep it consistent with `t`. Half-hour kickoffs (`:30`) and post-midnight (`sk>=24`) are special-cased in both `matchStatus` and `startUTC`; update both if you touch that logic.
- The whole UI is keyed off `M` and `state`; there is no framework, so new filters mean: add to `state`, handle in `passes`, wire a control listener, and reset it in the `#clear` handler. `card(m)` reads the live overlay fields (`_scoreH`/`_scoreA`/`_th`/`_ta`/`_detail`) with fallback to the static `res`/`desc`, so it works identically whether or not the ESPN feed is reachable.
- **No persistent storage.** `localStorage`/`sessionStorage` are intentionally avoided — the page must run inside a sandboxed artifact frame where storage is blocked. Keep all state in memory unless the page is rehosted elsewhere.
- **Knockout teams resolve from the ESPN feed**, not from computed group standings — `desc` seeding (`1C`, `2F`, `3rd (A/B/C/D/F)`) shows until FIFA sets each fixture and the feed reports real teams (then `_th`/`_ta`). There is deliberately no client-side standings/third-place-table computation.
- **Timezone:** default "Eastern" preserves the broadcaster's exact `t` labels; other zones reformat via `fmtTime(m)` from `startUTC(m)`. Day-grouping always stays by tournament matchday (`m.d`/`sk`), and `.ics` stays absolute UTC — both intentional.
- The 4 completed June 11–12 openers use `t:"FT"` with a `res` score and no parseable kickoff time, so `startUTC` defaults them to 3 PM and they may not instant-match the ESPN feed — harmless, since their static `res` already shows. Real in-tournament games have parseable `t` and match fine.
