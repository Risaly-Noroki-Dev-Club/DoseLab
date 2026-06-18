from pydantic import BaseModel, Field


class PkRequest(BaseModel):
    half_life_hours: float = Field(gt=0)
    dose_mg: float = Field(gt=0)
    interval_hours: float = Field(gt=0)
    sim_hours: float = Field(default=72, gt=0)
    step_hours: float = Field(default=0.5, gt=0)


class PkResponse(BaseModel):
    times: list[float]
    concentrations: list[float]
    peak_value: float
    peak_hour: float
