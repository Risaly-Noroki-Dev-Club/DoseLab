from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from ..core.database import Base


class DoseLog(Base):
    __tablename__ = "dose_logs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    drug_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("drugs.id", ondelete="CASCADE")
    )
    dose_mg: Mapped[float] = mapped_column(Float)
    taken_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    note: Mapped[str | None] = mapped_column(Text)
