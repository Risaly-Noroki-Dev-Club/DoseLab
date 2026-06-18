"""Pure-Python PK engine. Server-side counterpart of the Dart calculator
under lib/features/pk_engine/. Kept in sync so a stateless backend
endpoint can recompute curves when the client is offline storage-only."""

from math import pow


def concentration_at(t: float, half_life: float, schedule: list[tuple[float, float]]) -> float:
    if half_life <= 0:
        return 0.0
    c = 0.0
    for dose_time, amount in schedule:
        if t < dose_time:
            continue
        c += amount * pow(0.5, (t - dose_time) / half_life)
    return c


def simulate(
    half_life_hours: float,
    dose_mg: float,
    interval_hours: float,
    sim_hours: float = 72,
    step_hours: float = 0.5,
) -> dict:
    schedule = [
        (i * interval_hours, dose_mg)
        for i in range(int(sim_hours // interval_hours) + 1)
        if i * interval_hours < sim_hours
    ]
    times: list[float] = []
    values: list[float] = []
    peak_v = 0.0
    peak_t = 0.0
    t = 0.0
    while t <= sim_hours:
        c = concentration_at(t, half_life_hours, schedule)
        times.append(round(t, 3))
        values.append(round(c, 4))
        if c > peak_v:
            peak_v = c
            peak_t = t
        t += step_hours
    return {
        "times": times,
        "concentrations": values,
        "peak_value": peak_v,
        "peak_hour": peak_t,
    }
