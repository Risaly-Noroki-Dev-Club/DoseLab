# Agent Notes

- This repository is currently documentation-only: `README.md`, `docs/PRODUCT.md`, `docs/ROADMAP.md`, and `docs/FDA_API.md`. There is no app skeleton, manifest, CI, lockfile, or test command yet.
- Product intent: local-first, cross-platform medication self-observation with PK concentration visualization, dose logs, therapeutic windows, transparent model parameters, FDA medication reference data, and JSON import/export.
- Safety constraint: never frame features, UI copy, or model output as medical advice, diagnosis, treatment, prescribing, or dosage adjustment. Preserve the disclaimer stance from `README.md`.
- MVP direction from docs: Flutter skeleton, Material 3 light/dark theme, local database, FDA medication reference data retrieval, medication/dose-log CRUD, half-life concentration curve, therapeutic window overlays, peak/trough markers, custom thresholds, responsive layout, and JSON import/export.
- FDA API direction is documented in `docs/FDA_API.md`: start with openFDA `drug/ndc` for medication lookup/product metadata and `drug/label` for SPL label sections.
- FDA data must stay source-transparent: retain request URL without API key, retrieval time, endpoint/query, `meta.last_updated`, terms/license/disclaimer when present, update status, and graceful handling for unavailable, stale, incomplete, ambiguous, or unmatched data.
- MVP non-goals: automatic dose adjustment, diagnosis/treatment recommendations, mandatory cloud accounts, and full clinical interaction database.
- If adding the first implementation, add executable setup/verify commands to this file once the toolchain exists.
