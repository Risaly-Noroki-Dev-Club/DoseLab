from datetime import datetime

from pydantic import BaseModel, ConfigDict


class DrugCreate(BaseModel):
    product_ndc: str | None = None
    brand_name: str
    generic_name: str | None = None
    strength: str | None = None
    dose_mg: float = 50
    interval_hours: float = 24


class DrugOut(DrugCreate):
    model_config = ConfigDict(from_attributes=True)
    id: str
    created_at: datetime
