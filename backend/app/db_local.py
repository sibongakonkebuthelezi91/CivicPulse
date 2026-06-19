import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).resolve().parent.parent / "dev.db"


def get_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    with get_connection() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                phone TEXT UNIQUE NOT NULL,
                name TEXT NOT NULL,
                id_number TEXT UNIQUE NOT NULL,
                alert_contacts TEXT NOT NULL DEFAULT '[]',
                role TEXT NOT NULL DEFAULT 'citizen',
                created_at TEXT NOT NULL
            )
            """
        )
