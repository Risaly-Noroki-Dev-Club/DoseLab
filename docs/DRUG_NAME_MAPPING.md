# Drug Name Mapping Strategy

DoseLab queries openFDA, but openFDA only supports English-oriented FDA fields. Chinese drug names must be resolved locally before any FDA request.

## Recommended Data Model

Store a local mapping table with one canonical English ingredient/product search term and many aliases.

```json
{
  "id": "sertraline",
  "en": "sertraline",
  "zh": ["舍曲林", "盐酸舍曲林", "左洛复"],
  "rxnorm": ["312941", "312940", "312938"],
  "pubchem_cid": "68617",
  "wikidata": "Q407617",
  "category": "ssri",
  "sources": ["manual", "wikidata", "rxnorm", "pubchem"]
}
```

## Source Roles

- openFDA: FDA product/label data and source metadata. Not suitable for Chinese search terms.
- RxNorm/RxNav: English medication normalization, RxCUI identifiers, US clinical drug forms.
- PubChem: compound synonyms, PubChem CID, international non-Chinese synonyms. Good bridge for ingredient identity.
- Wikidata: best public source for multilingual labels and aliases, including Chinese names when available.
- Manual curation: required for Chinese brand names, regional usage, salt/form naming, and psychiatric medication priority.

## Practical Pipeline

1. Start from a curated psychiatric medication seed list.
2. For each English ingredient, fetch RxNorm concepts and PubChem synonyms.
3. Query Wikidata by English name, RxCUI/PubChem/DrugBank identifiers where possible.
4. Extract Chinese labels/aliases from Wikidata.
5. Merge manual Chinese aliases and brand names.
6. Export a compact JSON file for the PWA.
7. Load JSON into IndexedDB on first run; keep the JSON cached by the service worker.

## Runtime Behavior

- If input contains Chinese characters, DoseLab must not send the raw term to openFDA.
- First resolve Chinese aliases locally.
- If mapped, query openFDA with the English canonical term.
- If unmapped, show a local "not mapped yet" message and invite manual English search.

## Why Not Use a Server First

The mapping database can be small enough for offline PWA use. A 3,000-entry JSON file with aliases and identifiers is likely under a few MB and can be cached locally. Server-side search can be added later if fuzzy search, analytics, or collaborative curation become necessary.
