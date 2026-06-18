# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

DoseLab is an early-stage, local-first PWA for medication self-observation: dose logging, reminders, half-life-based concentration curves, and openFDA reference data lookup. The roadmap mentioned a Flutter app in `docs/`, but current implementation is a web PWA only — Flutter has not been started.

## Run / develop

No build step, no package manager, no test suite. The entire web app is static files under `web/`.

```sh
python3 -m http.server 2280 -d web
# then open http://localhost:2280
```

Notifications and full PWA install require HTTPS in production.

Experimental Python query scripts (separate from the web app) live under `scripts/`. They write to `/data/` which is gitignored:

```sh
python3 scripts/query_sertraline.py
```

## Architecture

### The web app is one HTML file

`web/index.html` (~950 lines) contains the entire app: CSS, the i18n `I` dictionary, IndexedDB helpers, "my meds" state, FDA fetch, PK parser, canvas chart, and mobile tab layout. There is no module system, no bundler, and no framework. Splitting this file is on the roadmap but has not happened — when editing, expect to scroll through one file and use `selectedMed`, `pkParams`, `myMeds`, `schedule`, `simHours`, `doseMg`, `intervalHours` as the implicit globals.

### Service worker invariants

`web/sw.js` uses a versioned cache (`CACHE = 'doselab-vN'`). Old caches are deleted on `activate`. **When you change cached assets in `ASSETS` or ship a meaningful update, bump the version string** — otherwise installed PWAs will keep serving stale files. Requests to `api.fda.gov` are explicitly bypassed (never cached by the SW; the app caches parsed label data in IndexedDB instead).

### IndexedDB schema

Database `doselab`, version 1, two stores:
- `meds` (keyPath `id`): user's "my meds" entries — `{id, product_ndc, brand_name, dose_mg, interval_h, notify, last_dose, ...}`
- `labels` (keyPath `key`): parsed PK params cached per brand name with `key: 'label:<term>'`, TTL 24h

If you add a store, increment the IDB version in `idb()` and handle the upgrade — there is no migration framework.

### Chinese drug name resolution

openFDA cannot be queried in Chinese. Search flow:
1. If input contains CJK (`CJK` regex), call `resolveQuery()`.
2. `matchZh()` searches `CORE_ZH_MAP` (inline in `index.html`, ~30 psychiatric/neuro drugs) first, then `zhMap` loaded from `web/data/zh_drug_map.json`.
3. If unmapped: show `unmappedChinese` message — **never send the raw Chinese term to openFDA**.
4. If mapped: query openFDA with the English canonical name.

`docs/DRUG_NAME_MAPPING.md` describes the planned broader mapping pipeline (Wikidata + RxNorm + PubChem + manual curation, target ~3,000 entries).

### openFDA usage

`fdaFetch()` redacts `api_key` before storing the URL and returns an envelope with `retrieved_at`, `request_url`, `endpoint`, `search_query`. The Python `scripts/fda_query.py` mirrors this envelope shape for offline experiments. Endpoints used:
- `drug/ndc.json` — product lookup (called first)
- `drug/label.json` — PK text, parsed for half-life / Tmax / steady state via regex in `parsePK()`

Rate limits and field choices are documented in `docs/FDA_API.md`. Preserve source metadata (URL, retrieval time, `meta.last_updated`, disclaimer) wherever FDA-derived data is shown.

### PK model

Pure exponential decay summed over doses: `C(t) = Σ dose_i * 0.5^((t - t_i) / half_life)`, computed in `concentration()`. Therapeutic / warning / toxic bands are heuristic multiples of `doseMg` (0.4×, 1.0×, 1.5×) — not clinically derived. The chart is rendered directly to `<canvas>` with DPR scaling in `drawChart()`; a prior fix (commit 055fa7a) corrected coordinate-space scaling, so keep `ctx.setTransform(dpr,0,0,dpr,0,0)` before drawing.

### Mobile layout

Below 750px the three panels (list / detail / chart) become tabs (`switchTab`); above 750px they render side-by-side. Resize listener re-runs `drawChart` because canvas dimensions are tied to the live container size.

## Hard constraints

- **Never present output as medical advice, diagnosis, treatment, or dose-adjustment guidance.** This is enforced in copy throughout `index.html` (`disclaimer` strings) and called out in `AGENTS.md` and `docs/PRODUCT.md`. New features must preserve the disclaimer stance.
- **Do not bypass the Chinese-name mapping step** by sending CJK strings to openFDA — it silently returns no results and confuses users.
- **FDA data is reference, not approval.** NDC inclusion ≠ FDA approval; label content is openFDA-reformatted and unvalidated. Keep source metadata visible.
- MVP non-goals (`docs/PRODUCT.md`): automatic dose adjustment, diagnosis/treatment recommendations, mandatory cloud accounts, full interaction database.

## Doc map

- `README.md` — user-facing intro in Chinese; current prototype status
- `AGENTS.md` — agent constraints and MVP direction
- `docs/PRODUCT.md` — positioning, MVP scope, non-goals
- `docs/ROADMAP.md` — phased plan
- `docs/FDA_API.md` — openFDA endpoint and field reference
- `docs/DRUG_NAME_MAPPING.md` — multilingual mapping strategy
