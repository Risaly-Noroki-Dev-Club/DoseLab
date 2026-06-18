"""Server-side openFDA client. Provides a uniform envelope shape
that matches the Dart client (`lib/features/drug_search/fda_envelope.dart`)
and the experimental Python script (`scripts/fda_query.py`)."""

from datetime import datetime, timezone
from typing import Any
from urllib.parse import urlencode

import httpx

from ..core.config import get_settings


def _safe_url(url: str, api_key: str | None) -> str:
    if api_key:
        return url.replace(f"api_key={api_key}", "api_key=***")
    return url


async def query_openfda(
    endpoint: str,
    search: str | None = None,
    limit: int = 20,
    skip: int = 0,
) -> dict[str, Any]:
    settings = get_settings()
    params: dict[str, Any] = {"limit": limit, "skip": skip}
    if search:
        params["search"] = search
    if settings.fda_api_key:
        params["api_key"] = settings.fda_api_key

    url = f"{settings.fda_base_url}/{endpoint}?{urlencode(params)}"
    envelope: dict[str, Any] = {
        "endpoint": endpoint,
        "search_query": search,
        "request_url": _safe_url(url, settings.fda_api_key),
        "retrieved_at": datetime.now(timezone.utc).isoformat(),
    }

    async with httpx.AsyncClient(timeout=20) as client:
        try:
            resp = await client.get(url)
        except httpx.HTTPError as e:
            envelope["status"] = "error"
            envelope["error"] = str(e)
            envelope["results"] = []
            envelope["meta"] = {}
            return envelope

    if resp.status_code == 404:
        envelope["status"] = "empty"
        envelope["results"] = []
        envelope["meta"] = {"results": {"total": 0}}
        return envelope
    if resp.status_code >= 400:
        envelope["status"] = "error"
        envelope["error"] = resp.text
        envelope["results"] = []
        envelope["meta"] = {}
        return envelope

    body = resp.json()
    envelope["status"] = "fresh"
    envelope["results"] = body.get("results", [])
    envelope["meta"] = body.get("meta", {})
    return envelope
