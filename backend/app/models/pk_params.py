from datetime import datetime

from sqlalchemy import DateTime, Float, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from ..core.database import Base


class PkParams(Base):
    """Server-side cache of FDA-derived PK parameters per brand name."""

    __tablename__ = "pk_params"

    key: Mapped[str] = mapped_column(String(255), primary_key=True)
    brand_term: Mapped[str] = mapped_column(String(255))
    half_life_hours: Mapped[float | None] = mapped_column(Float)
    tmax_text: Mapped[str | None] = mapped_column(Text)
    steady_state: Mapped[str | None] = mapped_column(Text)
    source_url: Mapped[str | None] = mapped_column(Text)
    source_last_updated: Mapped[str | None] = mapped_column(String(64))
    fetched_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
