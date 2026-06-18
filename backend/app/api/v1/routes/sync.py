from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_db
from ....models.drug import Drug

router = APIRouter()


class SyncPayload(BaseModel):
    version: int
    exported_at: str
    drugs: list[dict]


@router.post("/push")
async def push(payload: SyncPayload, db: AsyncSession = Depends(get_db)) -> dict:
    """Accept the same JSON envelope produced by the Flutter WebDAV
    sync helper, so users can mirror to either backend or WebDAV."""
    for d in payload.drugs:
        existing = await db.get(Drug, d.get("id", ""))
        if existing is None:
            drug = Drug(
                id=d.get("id", ""),
                user_id="00000000-0000-0000-0000-000000000000",
                product_ndc=d.get("product_ndc"),
                brand_name=d.get("brand_name", ""),
                generic_name=d.get("generic_name"),
                strength=d.get("strength"),
                dose_mg=d.get("dose_mg", 50),
                interval_hours=d.get("interval_hours", 24),
            )
            db.add(drug)
        else:
            existing.dose_mg = d.get("dose_mg", existing.dose_mg)
            existing.interval_hours = d.get("interval_hours", existing.interval_hours)
    await db.commit()
    return {"received": len(payload.drugs)}


@router.get("/pull")
async def pull(db: AsyncSession = Depends(get_db)) -> dict:
    from sqlalchemy import select

    rows = (await db.execute(select(Drug))).scalars().all()
    return {
        "version": 1,
        "drugs": [
            {
                "id": r.id,
                "product_ndc": r.product_ndc,
                "brand_name": r.brand_name,
                "generic_name": r.generic_name,
                "strength": r.strength,
                "dose_mg": r.dose_mg,
                "interval_hours": r.interval_hours,
            }
            for r in rows
        ],
    }
