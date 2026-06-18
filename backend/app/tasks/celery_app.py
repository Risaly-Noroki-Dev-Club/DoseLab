from celery import Celery

from ..core.config import get_settings

settings = get_settings()

celery_app = Celery(
    "doselab",
    broker=settings.celery_broker_url,
    backend=settings.celery_result_backend,
    include=["app.tasks.fda_refresh"],
)
celery_app.conf.update(task_track_started=True)
