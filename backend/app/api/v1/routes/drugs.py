import uuid

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ....core.database import get_db
from ....models.drug import Drug
from ....models.user import User
from ....schemas.drug import DrugCreate, DrugOut

router = APIRouter()
ANONYMOUS_USER_ID = "00000000-0000-0000-0000-000000000000"

@router.get("", response_model=list[DrugOut])
async def list_drugs(db: AsyncSession = Depends(get_db)) -> list[DrugOut]:
    rows = (await db.execute(select(Drug))).scalars().all()
    return [DrugOut.model_validate(r) for r in rows]


@router.post("", response_model=DrugOut)
async def create_drug(
    payload: DrugCreate, db: AsyncSession = Depends(get_db)
) -> DrugOut:
    anonymous = await db.get(User, ANONYMOUS_USER_ID)
    if anonymous is None:
        db.add(
            User(
                id=ANONYMOUS_USER_ID,
                email="anonymous@doselab.local",
                password_hash="",
            )
        )
    drug = Drug(
        id=str(uuid.uuid4()),
        user_id=ANONYMOUS_USER_ID,  # auth wiring will replace this
        product_ndc=payload.product_ndc,
        brand_name=payload.brand_name,
        generic_name=payload.generic_name,
        strength=payload.strength,
        dose_mg=payload.dose_mg,
        interval_hours=payload.interval_hours,
    )
    db.add(drug)
    await db.commit()
    await db.refresh(drug)
    return DrugOut.model_validate(drug)
