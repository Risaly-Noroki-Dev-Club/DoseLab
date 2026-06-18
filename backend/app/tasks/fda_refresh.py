"""Celery task that refreshes cached openFDA label data for a brand.

Run with:
    celery -A app.tasks.celery_app worker -l info

Schedule with celery beat or trigger from an API handler when the
cached entry's TTL has expired.
"""

from __future__ import annotations

import asyncio

from .celery_app import celery_app
from ..services.fda import query_openfda


@celery_app.task(name="fda.refresh_label")
def refresh_label(brand_term: str) -> dict:
    """Synchronous Celery entrypoint that runs the async FDA fetch."""

    async def _go() -> dict:
        return await query_openfda(
            "drug/label.json",
            search=f'openfda.brand_name:"{brand_term}"',
            limit=1,
        )

    return asyncio.run(_go())
