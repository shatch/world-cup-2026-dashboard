# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

A single self-contained `index.html` — a static, zero-dependency dashboard listing all 104 FIFA World Cup 2026 matches (June 11 – July 19, 2026) with kickoff times (Eastern), English/Spanish TV channels, streaming options, filtering, and `.ics` calendar export. No build step, no package manager, no tests, no backend.

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

- **Streaming is per-language, not per-match** — identical for every game (FOX One = English, Peacock = Spanish, Fubo = all), so it's stated once rather than stored per row. Only the linear TV channel (FOX/FS1, Telemundo/Universo) varies per match.
- **`state` + `passes(m)` + `render()`** — `state` holds all active filters; `passes` decides visibility; `render` regroups visible matches by day and builds HTML via `card(m)`. Re-render is full-innerHTML on every control change.
- **`.ics` export** — `buildICS` (one event per match) and `buildPartyICS` (one event per day, grouped) generate calendar files; the "Watch party" toggle switches between them. Export only includes matches that pass current filters and aren't full-time.

## Editing notes

- To change schedule/scores, edit objects in the `M` array. Adding a team requires a matching `FLAGS` entry or it falls back to ⚽.
- `sk` controls ordering within a day and the post-midnight rollover — keep it consistent with `t`. Half-hour kickoffs (`:30`) and post-midnight (`sk>=24`) are special-cased in both `matchStatus` and `startUTC`; update both if you touch that logic.
- The whole UI is keyed off `M` and `state`; there is no framework, so new filters mean: add to `state`, handle in `passes`, wire a control listener, and reset it in the `#clear` handler.
- **No persistent storage.** `localStorage`/`sessionStorage` are intentionally avoided — the page must run inside a sandboxed artifact frame where storage is blocked. Keep all state in memory unless the page is rehosted elsewhere.
- **Knockout matchups are not resolved from results** — `desc` shows seeding (`1C`, `2F`, `3rd (A/B/C/D/F)`) and stays static; there's no logic to fill in teams from group standings yet.
- The 4 completed June 11–12 openers use `t:"FT"` with a `res` score and have no stored kickoff time — fine because `.ics` export always skips finished games.
