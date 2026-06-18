from fastapi import APIRouter

from ....schemas.pk import PkRequest, PkResponse
from ....services.pk_calculator import simulate

router = APIRouter()


@router.post("/compute", response_model=PkResponse)
async def compute(req: PkRequest) -> PkResponse:
    """Stateless PK simulation. Useful for clients that don't want to
    ship the Dart engine (e.g. a future browser-only embed)."""
    result = simulate(
        half_life_hours=req.half_life_hours,
        dose_mg=req.dose_mg,
        interval_hours=req.interval_hours,
        sim_hours=req.sim_hours,
        step_hours=req.step_hours,
    )
    return PkResponse(**result)
