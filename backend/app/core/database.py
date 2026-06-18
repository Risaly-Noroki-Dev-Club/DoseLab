"""Async SQLAlchemy engine + session factory and the FastAPI dependency."""

from collections.abc import AsyncIterator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from .config import get_settings

settings = get_settings()

engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,
    future=True,
)

SessionFactory = async_sessionmaker(
    engine,
    expire_on_commit=False,
    class_=AsyncSession,
)


class Base(DeclarativeBase):
    """Project-wide declarative base. All ORM models inherit from this."""


async def get_db() -> AsyncIterator[AsyncSession]:
    """FastAPI dependency: per-request session with automatic close."""
    async with SessionFactory() as session:
        yield session


async def init_models() -> None:
    """Create tables on startup. Replace with Alembic for production."""
    # Import here so SQLAlchemy sees the table metadata.
    from .. import models  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
