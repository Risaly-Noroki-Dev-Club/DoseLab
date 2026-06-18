# Agent Notes

## Current state

The project has migrated from a single-file PWA prototype (`web/index.html`) to a Flutter + FastAPI scaffold. The PWA is gone; the canonical code now lives in `lib/` (Flutter app) and `backend/` (FastAPI service). Both are scaffolded end-to-end but require generated code (`*.g.dart`, `*.freezed.dart`) before they will compile.

## Run / verify

Flutter front end:

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift + Freezed codegen
flutter analyze
flutter run -d chrome                                      # or -d <device>
```

FastAPI back end:

```sh
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload --port 8000
```

Celery worker (optional, for openFDA refresh tasks):

```sh
celery -A app.tasks.celery_app worker -l info
```

## Architecture map

- `lib/core/` — config, DI (Riverpod), router (go_router), Material 3 theme, Dio + JWT network layer, Drift SQLite, Freezed `Failure` union.
- `lib/features/` — `auth`, `dashboard`, `drug_search`, `pk_engine`, `medication_schedule`, `interaction_check`, `sync`, `pdf_report`, `settings`.
- `lib/shared/` — reusable widgets, utils, constants, l10n, extensions.
- `backend/app/` — FastAPI app, async SQLAlchemy, JWT, PK service, sync/report routes, Celery tasks.

## Behaviour parity with the PWA

The Flutter and FastAPI code intentionally preserves the prototype's externally observable behaviour:

- openFDA envelope shape — `{results, meta, retrieved_at, request_url (redacted), endpoint, search_query}` — matches `scripts/fda_query.py` and the old `fdaFetch()`.
- `api_key` is redacted (`api_key=***`) from any stored or logged URL.
- Chinese drug name resolution still goes through the `zh_drug_map.json` mapper before any openFDA call. CJK strings are never sent to openFDA; if unmapped, the UI shows the `unmappedChinese` message.
- PK model is the same exponential decay sum: `C(t) = Σ dose_i * 0.5^((t − t_i) / half_life)`.
- Therapeutic band multipliers (`0.25× / 0.4× / 1.0× / 1.5×` of dose) are heuristic visual cues only, not clinical thresholds.

## Hard constraints

- Never frame features, UI copy, model output, PDF reports, or API responses as medical advice, diagnosis, treatment, prescribing, or dosage adjustment. Preserve the `disclaimer` stance from `README.md` and `docs/PRODUCT.md`.
- FDA data must stay source-transparent: keep the redacted request URL, retrieval time, endpoint/query, `meta.last_updated`, terms/license/disclaimer when present, and graceful handling for unavailable / stale / incomplete / ambiguous / unmatched results. The `DisclaimerBanner` must remain on any FDA-derived view.
- Do not bypass Chinese-name mapping by sending CJK strings to openFDA — it silently returns no results.
- MVP non-goals: automatic dose adjustment, diagnosis/treatment recommendations, mandatory cloud accounts, full clinical interaction database. The `interaction_check` feature stays explicitly non-clinical.

## When changing schemas

- Drift: bump `schemaVersion` in `lib/core/storage/local_db.dart` and add a `MigrationStrategy` step — there is no auto-migration framework.
- SQLAlchemy: add an Alembic revision rather than editing models in place once the project is past the MVP scaffold.
- openFDA envelope: `features/drug_search/fda_client.dart` is the canonical app path and queries openFDA directly. Keep any optional Python refresh task envelope compatible with it.
