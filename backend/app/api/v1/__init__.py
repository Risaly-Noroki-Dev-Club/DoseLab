from fastapi import APIRouter

from .routes import auth, drugs, interactions, pk, reports, sync

router = APIRouter(prefix="/api/v1")
router.include_router(auth.router, prefix="/auth", tags=["auth"])
router.include_router(drugs.router, prefix="/drugs", tags=["drugs"])
router.include_router(pk.router, prefix="/pk", tags=["pk"])
router.include_router(
    interactions.router, prefix="/interactions", tags=["interactions"]
)
router.include_router(sync.router, prefix="/sync", tags=["sync"])
router.include_router(reports.router, prefix="/reports", tags=["reports"])
