# World Cup 2026 Watch Dashboard — Build Handoff

## What this is
A single self-contained file — `index.html` — that answers one question for a US viewer: **for every 2026 FIFA World Cup match, when does it kick off (Eastern), what channel is it on, and where can I stream it.** All 104 matches, June 11 – July 19, 2026.

No build step, no framework, no package install. Vanilla HTML/CSS/JS in one file. Only external dependency is Google Fonts (Barlow Condensed / Inter / Roboto Mono) loaded via `<link>`. It renders as an artifact but is a plain static page — open it in any browser.

## Why it's built this way
- **Single file, no deps:** the deliverable is a thing you hand to a non-technical person or host yourself in seconds. A React/bundler setup would add friction for zero benefit at this scope.
- **Data is hardcoded, not fetched:** there's no free, stable per-match World Cup API with US broadcast assignments. The schedule is fixed; channel assignments rarely change. A baked-in array is more reliable than a flaky live call and works offline.
- **Source of truth hierarchy:** English channel (FOX vs FS1), kickoff times, and venues come from FOX's own published schedule (the rights holder, most recently updated). The Spanish-language split and the third-place match time come from a secondary outlet (The Big Lead). Where sources disagreed on EN times/channels, FOX wins.

## Data model
All match data lives in one array, `M`, near the top of the `<script>`. Each entry:

| field | meaning |
|---|---|
| `d` | display date, `YYYY-MM-DD` |
| `t` | kickoff label, e.g. `"3:00 PM"`, `"12:00 AM"`, or `"FT"` for completed games |
| `sk` | numeric sort key within a day (hour in 24h; `24` = post-midnight; fractional like `.1` are tiebreakers for simultaneous kickoffs — **not** minutes) |
| `h` / `a` | home / away team (omitted for knockout games with unknown teams) |
| `res` | score string for completed games, e.g. `"2-0"` |
| `grp` | round: `"Group A"`…`"Group L"`, `"Round of 32"`, `"Round of 16"`, `"Quarterfinal"`, `"Semifinal"`, `"Third place"`, `"Final"` |
| `v` | venue (FIFA's tournament-rebranded names, e.g. `"New York New Jersey Stadium"`) |
| `tv` | English TV channel: `"FOX"` or `"FS1"` |
| `desc` | knockout matchup descriptor when teams are TBD, e.g. `"1C vs 2F"`, `"1E vs 3rd (A/B/C/D/F)"` |

Two fields are computed at load in a single `M.forEach`:
- `_st` — status (`"ft"` / `"live"` / `"up"`) from `matchStatus()`.
- `es` — Spanish channel. A hardcoded `UNIVERSO` Set holds the 12 group-stage games on Universo (the second simultaneous match in each doubled slot, Jun 24–27); everything else is Telemundo. 12 + 92 = 104, matching the published split.

Streaming is **not** per-match — it's per-language and identical for all games, so it's stated once: FOX One (English), Peacock (Spanish), Fubo (all). Only the linear TV channel varies, which is why FOX/FS1 + Telemundo/Universo are the per-row chips.

## Time handling (the part most likely to bite an editor)
- Labels say **"ET"** and represent **EDT (UTC−4)** because the tournament runs in summer. The user asked for "EST" but every broadcaster lists ET/EDT; clock math uses −4. Flagged to the user.
- `matchStatus()` compares match start (built with an explicit `-04:00` offset) to `now`; a game is `live` within a ~2.25h window, else `ft`/`up`. The 4 completed openers carry `res` and force `ft`.
- "Today" is resolved in `America/New_York` via `Intl.DateTimeFormat`, so the highlight + auto-scroll are correct regardless of the viewer's own timezone.
- Midnight (`12:00 AM ET`, `sk:24`) games are displayed under the prior matchday (matching FOX) but their actual datetime rolls to the next calendar day. `startUTC()` handles the `+1 day` offset.

## Features
- **Search** across team / venue / round.
- **Filters:** round dropdown, team dropdown, FOX-vs-FS1 dropdown.
- **Toggles:** Today, Upcoming.
- **Host quick-pick chips:** one-tap USA / Mexico / Canada; tap again to clear; stays in sync with the team dropdown.
- **Status:** Live (pulsing), Full time (with score), Upcoming.
- **Grouped by date** with sticky day headers; auto-scrolls to today on load.
- **Responsive** to mobile; keyboard-focus styles; respects the quiet/dark aesthetic.

### Calendar export (`.ics`)
- Standard iCalendar, triggered via a `data:` URL anchor (more sandbox-tolerant than Blob). Filenames: `world-cup-2026.ics` / `world-cup-2026-watch-parties.ics`.
- **Always excludes finished games** and **respects active filters** — so "filter to USA → export" yields only their remaining fixtures.
- **Two modes**, switched by the "Watch party" toggle:
  - *Per-match* (`buildICS`): one 2-hour `VEVENT` per game, with venue as `LOCATION` and both-language channels in `DESCRIPTION`.
  - *Watch party* (`buildPartyICS`): one `VEVENT` per day spanning first kickoff → last match end, with every game for that day listed in the `DESCRIPTION`. Bundles a matchday into a single calendar block.
- `startUTC()` converts ET→UTC (`+4`); verified across afternoon, noon, midnight-rollover, and half-hour kickoffs.

## Known limitations / caveats
1. **EDT vs EST** — see above. If literal EST is ever required, subtract one hour from displayed labels (UTC math in the `.ics` would also shift).
2. **Per-match Spanish channel** comes from a secondary source; FOX doesn't publish the Telemundo/Universo split. The 12-game Universo set is hardcoded — re-verify if the network revises it.
3. **Knockout matchups** show seeding (`1C`, `2F`, `3rd (…)`) until teams are confirmed; there's no logic to resolve them from group results yet.
4. **Completed games** (the 4 June 11–12 openers) have `t:"FT"` with scores but no stored kickoff time — fine because the export skips finished games.
5. **`sk` overloads sorting and time** — the `.ics` correctly parses the `t` string for real kickoff time, not `sk`. Don't use `sk` for time math.
6. **Sandboxed download** — if the in-frame export does nothing, open the page in its own tab.

## Suggested next steps
- Resolve knockout bracket teams from entered group results (would make `desc` dynamic).
- Optional live-score hydration from an API (currently static).
- A timezone selector (convert labels client-side; keep `.ics` absolute).
- Second tier of "contender" quick chips (Brazil/Argentina/England/etc.).
- Smarter watch-party windows (e.g., only bundle games after a chosen hour so lunchtime kickoffs don't bloat the block).
- Note: browser storage (localStorage) is intentionally avoided — it's blocked in the artifact sandbox. Use in-memory state only unless rehosted elsewhere.
