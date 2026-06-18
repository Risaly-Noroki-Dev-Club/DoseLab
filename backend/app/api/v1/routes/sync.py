from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()


class SyncPayload(BaseModel):
    version: int
    exported_at: str
    drugs: list[dict]


@router.post("/push")
async def push(payload: SyncPayload) -> dict:
    """Accept the same JSON envelope produced by the Flutter WebDAV
    sync helper, so users can mirror to either backend or WebDAV."""
    # TODO: persist per-user; for now echo back so the client can
    # detect a 200 response and treat sync as successful.
    return {"received": len(payload.drugs)}


@router.get("/pull")
async def pull() -> dict:
    return {"version": 1, "drugs": []}
