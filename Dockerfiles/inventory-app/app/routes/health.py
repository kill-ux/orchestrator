from flask import Blueprint
from ..models import db
from sqlalchemy import text

health_bp = Blueprint("health_bp", __name__, url_prefix="/health")
SERVICE_UNAVAILABLA_CODE = 503


@health_bp.route("/")
def health_check():
    health_status = {"status": "UP", "services": {"database": "DOWN"}}
    try:
        db.session.execute(text("SELECT 1"))
        health_status["services"]["database"] = "UP"
        status_code = 200
    except Exception as e:
        health_status["status"] = "DEGRADED"
        health_status["error"] = str(e)
        status_code = SERVICE_UNAVAILABLA_CODE
    return health_status, status_code
