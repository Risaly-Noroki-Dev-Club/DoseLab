from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column

from ..core.database import Base


class Drug(Base):
    __tablename__ = "drugs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE")
    )
    product_ndc: Mapped[str | None] = mapped_column(String(64))
    brand_name: Mapped[str] = mapped_column(String(255))
    generic_name: Mapped[str | None] = mapped_column(String(255))
    strength: Mapped[str | None] = mapped_column(String(255))
    dose_mg: Mapped[float] = mapped_column(Float, default=50)
    interval_hours: Mapped[float] = mapped_column(Float, default=24)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
