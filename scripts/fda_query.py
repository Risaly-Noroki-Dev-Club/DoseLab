"""
FDA openFDA query module for DoseLab.

Provides reusable functions for querying drug/ndc and drug/label endpoints
with source-metadata capture as specified in docs/FDA_API.md.
"""

import json
import time
import urllib.request
import urllib.parse
from datetime import datetime, timezone
from typing import Optional

OPENFDA_BASE = "https://api.fda.gov"
REQUEST_TIMEOUT = 30


def _build_url(endpoint: str, query: Optional[str] = None,
               limit: int = 100, skip: int = 0,
               api_key: Optional[str] = None) -> str:
    parts = [f"limit={limit}", f"skip={skip}"]
    if query:
        parts.append(f"search={urllib.parse.quote(query, safe='+')}")
    if api_key:
        parts.append(f"api_key={api_key}")
    return f"{OPENFDA_BASE}/{endpoint}?{'&'.join(parts)}"


def _safe_url(url: str, api_key: Optional[str] = None) -> str:
    if api_key:
        return url.replace(f"api_key={api_key}", "api_key=***")
    return url


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def query(endpoint: str, query: Optional[str] = None,
          limit: int = 100, skip: int = 0,
          api_key: Optional[str] = None) -> dict:
    """
    Query an openFDA endpoint and return a result envelope with source metadata.

    Returns:
        {
            "status": "fresh" | "error" | "empty",
            "retrieved_at": "<ISO-8601 UTC>",
            "request_url": "<full URL, API key redacted>",
            "endpoint": "<endpoint name>",
            "query": "<search query or null>",
            "limit": <int>,
            "skip": <int>,
            "meta": { ... }  (API response meta),
            "results": [ ... ] (API response results or [])
        }
    """
    url = _build_url(endpoint, query, limit, skip, api_key)
    envelope = {
        "status": "fresh",
        "retrieved_at": _now_iso(),
        "request_url": _safe_url(url, api_key),
        "endpoint": endpoint,
        "query": query,
        "limit": limit,
        "skip": skip,
    }
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as resp:
            body = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        envelope["status"] = "error"
        envelope["http_status"] = e.code
        envelope["error"] = str(e)
        return envelope
    except Exception as e:
        envelope["status"] = "error"
        envelope["error"] = str(e)
        return envelope

    envelope["meta"] = body.get("meta", {})
    envelope["results"] = body.get("results", [])
    if not envelope["results"]:
        envelope["status"] = "empty"
    return envelope


def query_all_pages(endpoint: str, query: Optional[str] = None,
                    page_size: int = 100, max_results: int = 1000,
                    api_key: Optional[str] = None) -> dict:
    """
    Query with automatic pagination, merging all pages into a single envelope.

    Respects max_results to avoid exceeding rate limits.
    """
    merged = None
    skip = 0
    while skip < max_results:
        page = query(endpoint, query, limit=page_size, skip=skip, api_key=api_key)
        if page["status"] == "error":
            return page
        if merged is None:
            merged = page
            merged["results"] = list(page["results"])
        else:
            merged["results"].extend(page["results"])
        total = page.get("meta", {}).get("results", {}).get("total", 0)
        if skip + page_size >= total:
            break
        skip += page_size
        time.sleep(0.25)  # gentle throttle
    return merged


def search_ndc(name: str, limit: int = 10,
               api_key: Optional[str] = None) -> dict:
    """Search NDC by brand_name or generic_name."""
    q = f'brand_name:"{name}"+generic_name:"{name}"'
    return query("drug/ndc.json", q, limit=limit, api_key=api_key)


def get_ndc_by_spl_set_id(spl_set_id: str,
                          api_key: Optional[str] = None) -> dict:
    """Fetch all NDC records sharing the same SPL set ID."""
    q = f'openfda.spl_set_id:"{spl_set_id}"'
    return query_all_pages("drug/ndc.json", q, api_key=api_key)


def search_label(name: str, limit: int = 5,
                 api_key: Optional[str] = None) -> dict:
    """Search drug labels by brand_name."""
    q = f'openfda.brand_name:"{name}"'
    return query("drug/label.json", q, limit=limit, api_key=api_key)


def save_envelope(envelope: dict, filepath: str):
    """Persist query envelope to a JSON file."""
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(envelope, f, ensure_ascii=False, indent=2)
