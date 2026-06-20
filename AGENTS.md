# Agent Notes

## Current state

Flutter + FastAPI app (migrated from a single-file PWA prototype that no longer exists). The canonical code lives in `lib/` (Flutter) and `backend/` (FastAPI). Generated code (`*.g.dart`, `*.freezed.dart`) is required before either will compile.

The `web/` directory is a Flutter-web PWA **shell** (bootstraps the Flutter engine, service worker, WASM for Drift on web, manifest). Do not add app logic there — it all lives in `lib/`.

`CLAUDE.md` is stale (still describes the old prototype). Trust this file instead.

## Run / verify

Flutter front end:

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift + Freezed + Riverpod codegen
flutter analyze                                           # also catches custom_lint / riverpod_lint
flutter test                                              # only pk_calculator_test.dart exists
flutter run -d chrome                                     # or -d <device>
```

Production web build (for Netlify or static serve):

```sh
flutter build web --no-wasm-dry-run \
  --dart-define=API_BASE_URL=http://localhost:8000/api/v1 \
  --dart-define=FDA_API_KEY=your_key_here
```

FastAPI back end:

```sh
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env          # defaults to SQLite; swap to PostgreSQL for production
uvicorn app.main:app --reload --port 8000
```

Celery worker (optional, for openFDA refresh tasks):

```sh
celery -A app.tasks.celery_app worker -l info
```

## Architecture map

- `lib/core/` — config (env), DI (Riverpod), router (go_router), Material 3 theme, Dio + JWT network layer, Drift SQLite, Freezed `Failure` union.
- `lib/core/storage/` — Drift database + tables. `local_db.dart` holds `schemaVersion` and `MigrationStrategy`. Web builds use `sql-wasm.js`/`sql-wasm.wasm` from `web/` (loaded via `local_db_connection_web.dart`).
- `lib/features/` — `auth`, `dashboard`, `drug_search`, `pk_engine`, `medication_schedule`, `interaction_check`, `sync`, `pdf_report`, `settings`.
- `lib/shared/` — reusable widgets, utils, constants, l10n (manual zh/en), extensions.
- `backend/app/` — FastAPI app, async SQLAlchemy (supports SQLite and PostgreSQL via config), JWT (python-jose + passlib), PK service, sync/report routes, Celery tasks.
- `backend/app/api/v1/routes/` — `auth`, `drugs`, `pk`, `interactions`, `sync`, `reports`.
- `web/` — Flutter-web bootstrap + PWA shell. **Service worker**: bump `CACHE_VERSION` in `service_worker.js` when cached assets change.
- `netlify.toml` — Netlify deploy config; builds with `flutter build web --release --web-renderer canvaskit`.

## Code style

From `analysis_options.yaml`:
- `prefer_const_constructors: true` — const constructors, const literals, and trailing commas are required.
- `avoid_print: true` — use `logger` package instead.
- Generated files (`*.g.dart`, `*.freezed.dart`) are excluded from analysis.
- `custom_lint` + `riverpod_lint` are enabled.

## Behaviour parity with the PWA

The Flutter and FastAPI code intentionally preserves the prototype's externally observable behaviour:

- openFDA envelope shape — `{results, meta, retrieved_at, request_url (redacted), endpoint, search_query}` — matches `scripts/fda_query.py`.
- `api_key` is redacted (`api_key=***`) from any stored or logged URL.
- Chinese drug name resolution still goes through `assets/data/zh_drug_map.json` mapper before any openFDA call. CJK strings are never sent to openFDA; if unmapped, the UI shows the `unmappedChinese` message.
- PK model is the same exponential decay sum: `C(t) = Σ dose_i * 0.5^((t − t_i) / half_life)`.
- Therapeutic band multipliers (`0.25× / 0.4× / 1.0× / 1.5×` of dose) are heuristic visual cues only, not clinical thresholds.

## Hard constraints

- Never frame features, UI copy, model output, PDF reports, or API responses as medical advice, diagnosis, treatment, prescribing, or dosage adjustment. Preserve the `disclaimer` stance from `README.md` and `docs/PRODUCT.md`.
- FDA data must stay source-transparent: keep the redacted request URL, retrieval time, endpoint/query, `meta.last_updated`, terms/license/disclaimer when present, and graceful handling for unavailable / stale / incomplete / ambiguous / unmatched results. The `DisclaimerBanner` must remain on any FDA-derived view.
- Do not bypass Chinese-name mapping by sending CJK strings to openFDA — it silently returns no results.
- MVP non-goals: automatic dose adjustment, diagnosis/treatment recommendations, mandatory cloud accounts, full clinical interaction database. The `interaction_check` feature stays explicitly non-clinical.

## When changing schemas

- Drift: bump `schemaVersion` in `lib/core/storage/local_db.dart` and add a `MigrationStrategy` step — there is no auto-migration framework.
- SQLAlchemy: Alembic is listed in `requirements.txt` but no `alembic/` directory exists yet (MVP scaffold). Once initialized, add revision scripts rather than editing models in place.
- openFDA envelope: `lib/features/drug_search/fda_client.dart` is the canonical path and queries openFDA directly. Keep any optional Python refresh task envelope compatible with it.
