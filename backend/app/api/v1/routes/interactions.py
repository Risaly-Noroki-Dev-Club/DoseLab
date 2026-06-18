from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()


class _CheckRequest(BaseModel):
    drug_names: list[str]


class _Hit(BaseModel):
    a: str
    b: str
    severity: str
    summary: str


_RULES: list[dict] = [
    {
        "a": "sertraline", "b": "tramadol", "severity": "severe",
        "summary": "SSRI + tramadol increases serotonin syndrome risk. Reference only.",
    },
    {
        "a": "warfarin", "b": "ibuprofen", "severity": "warning",
        "summary": "NSAID can increase bleeding risk with warfarin. Reference only.",
    },
    {
        "a": "fluoxetine", "b": "tramadol", "severity": "severe",
        "summary": "SSRI + tramadol increases serotonin syndrome risk. Reference only.",
    },
    {
        "a": "lithium", "b": "ibuprofen", "severity": "warning",
        "summary": "NSAIDs can raise lithium levels. Reference only.",
    },
    {
        "a": "aspirin", "b": "ibuprofen", "severity": "warning",
        "summary": "Multiple NSAIDs increase GI bleed risk. Reference only.",
    },
    {
        "a": "methotrexate", "b": "ibuprofen", "severity": "severe",
        "summary": "NSAIDs can increase methotrexate levels. Reference only.",
    },
    {
        "a": "omeprazole", "b": "clopidogrel", "severity": "warning",
        "summary": "PPI may reduce clopidogrel activation. Reference only.",
    },
]


@router.post("/check", response_model=list[_Hit])
async def check(req: _CheckRequest) -> list[_Hit]:
    """Conservative interaction check. The MVP intentionally avoids
    claiming clinical completeness (see docs/PRODUCT.md non-goals)."""
    names = [n.lower() for n in req.drug_names]
    hits: list[_Hit] = []
    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            for r in _RULES:
                if (r["a"] in names[i] and r["b"] in names[j]) or (
                    r["b"] in names[i] and r["a"] in names[j]
                ):
                    hits.append(
                        _Hit(
                            a=names[i],
                            b=names[j],
                            severity=r["severity"],
                            summary=r["summary"],
                        )
                    )
    return hits
