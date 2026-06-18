from fastapi import APIRouter
from fastapi.responses import JSONResponse

router = APIRouter()


@router.post("/generate")
async def generate() -> JSONResponse:
    """Report PDF generation is performed client-side (pdf + printing
    packages). This endpoint is a placeholder for a future server-side
    rendering pipeline (e.g. WeasyPrint behind a Celery task)."""
    return JSONResponse(
        {"detail": "Report generation runs on the client for now"},
        status_code=501,
    )
