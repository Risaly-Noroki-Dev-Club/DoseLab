# FDA API Integration Notes

DoseLab should start with openFDA drug endpoints as reference-data sources. Treat all FDA-sourced fields as user-reviewable reference data, not medical advice or dosage guidance.

## Base API

- Base URL: `https://api.fda.gov`
- API key parameter: `api_key=...`
- Unauthenticated limits verified from openFDA docs: 240 requests/minute/IP and 1,000 requests/day/IP.
- API-key limits verified from openFDA docs: 240 requests/minute/key and 120,000 requests/day/key.
- HTTPS is required by openFDA.

## Primary Endpoints

- `GET /drug/ndc.json`: use first for medication lookup and product metadata.
- `GET /drug/label.json`: use for SPL label sections and clinical/pharmacology text when needed.

## Useful `drug/ndc` Fields

- Product identity: `product_ndc`, `product_id`, `spl_id`, `brand_name`, `brand_name_base`, `generic_name`, `labeler_name`.
- Product classification: `product_type`, `marketing_category`, `application_number`, `finished`.
- Dose/form metadata: `dosage_form`, `route`, `active_ingredients`.
- Market dates: `marketing_start_date`, `marketing_end_date`, `listing_expiration_date`.
- Package identity: `packaging[].package_ndc`, `packaging[].description`.
- Harmonized IDs: `openfda.rxcui`, `openfda.spl_set_id`, `openfda.manufacturer_name`, `openfda.upc`.

## Useful `drug/label` Fields

- Label identity: `id`, `set_id`, `version`, `effective_time`.
- Name/identity: `openfda.brand_name`, `openfda.generic_name`, `openfda.product_ndc`, `openfda.package_ndc`, `openfda.route`, `openfda.substance_name`, `openfda.rxcui`.
- PK/model text candidates: `clinical_pharmacology`, `pharmacokinetics`, `pharmacodynamics`.
- Safety/reference text candidates: `warnings`, `boxed_warning`, `contraindications`, `drug_interactions`, `adverse_reactions`.
- Dose text exists as `dosage_and_administration`, but DoseLab must not convert it into recommendations or automatic dose adjustment.

## Query Patterns

- NDC product lookup by brand: `https://api.fda.gov/drug/ndc.json?search=brand_name:"Tylenol"&limit=1`
- Label lookup by brand: `https://api.fda.gov/drug/label.json?search=openfda.brand_name:"Tylenol"&limit=1`
- Exact matching is available on fields that support `.exact`; prefer it for deterministic local matching when practical.
- For user-entered names, search NDC first, then use stable identifiers such as `product_ndc`, `spl_id`, `openfda.spl_set_id`, or `openfda.rxcui` to connect to label records.

## Source Metadata To Store

- Request URL, excluding any API key.
- Retrieval timestamp from the device clock.
- Endpoint name and query parameters.
- Response `meta.last_updated`.
- Response `meta.disclaimer`, `meta.terms`, and `meta.license` when present.
- Matched FDA identifiers, especially `product_ndc`, package NDCs, `spl_id`, `set_id`, and RxCUI values.
- Local status: `fresh`, `stale`, `unmatched`, `partial`, or `error`.

## Product Constraints

- FDA NDC data is updated daily; drug label data is updated weekly according to openFDA docs.
- NDC Directory inclusion does not mean FDA approval and must not be displayed as approval.
- openFDA label content is reformatted and unvalidated by FDA; keep the openFDA disclaimer visible wherever raw label-derived content is shown.
- Missing fields are expected. The app should allow manual local entries and overrides when FDA data is unavailable, stale, incomplete, or ambiguous.
