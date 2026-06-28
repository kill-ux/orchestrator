import os


class Config:
    """Base configuration."""
    DB_USER = os.getenv("INVENTORY_DB_USER")
    DB_PASS = os.getenv("INVENTORY_DB_PASS")
    DB_NAME = os.getenv("INVENTORY_DB_NAME")
    
    SQLALCHEMY_DATABASE_URI = f"postgresql://{DB_USER}:{DB_PASS}@inventory-db:5432/{DB_NAME}"
    