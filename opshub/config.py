import os

def target_containers() -> list[str]:
    env = os.getenv("OPS_TARGET_CONTAINERS", "")
    return [c.strip() for c in env.split(",") if c.strip()]

RETENTION_ACTIVE_DAYS = int(os.getenv("OPS_RETENTION_ACTIVE_DAYS", 7))
RETENTION_ARCHIVE_DAYS = int(os.getenv("OPS_RETENTION_ARCHIVE_DAYS", 30))
RETENTION_PURGE_DAYS   = int(os.getenv("OPS_RETENTION_PURGE_DAYS", 90))
LOG_BASE = "/data/logs"
