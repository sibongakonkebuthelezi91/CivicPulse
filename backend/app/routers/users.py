import json
from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, HTTPException

from app.db_local import get_connection, init_db
from app.models import UserCreate, UserResponse

router = APIRouter(prefix="/api/users", tags=["Users"])

init_db()


def _row_to_user(row) -> dict:
    return {
        "id": row["id"],
        "phone": row["phone"],
        "name": row["name"],
        "id_number": row["id_number"],
        "alert_contacts": json.loads(row["alert_contacts"]),
        "role": row["role"],
        "created_at": row["created_at"],
    }


@router.post("/", response_model=UserResponse, status_code=201)
async def create_user(user: UserCreate):
    """
    Create a Safe Hub user profile.
    The SA ID number is unique and is used for ID-only sign-in.
    """
    with get_connection() as conn:
        existing = conn.execute(
            "SELECT 1 FROM users WHERE id_number = ?", (user.id_number,)
        ).fetchone()

        if existing:
            raise HTTPException(
                status_code=409,
                detail="A profile already exists for this ID number.",
            )

        user_id = str(user.id or uuid4())
        created_at = datetime.now(timezone.utc).isoformat()

        conn.execute(
            """
            INSERT INTO users (id, phone, name, id_number, alert_contacts, role, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                user_id,
                user.phone,
                user.name,
                user.id_number,
                json.dumps(user.alert_contacts),
                user.role,
                created_at,
            ),
        )
        conn.commit()

        row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()

    return _row_to_user(row)


@router.get("/id-number/{id_number}", response_model=UserResponse)
async def get_user_by_id_number(id_number: str):
    """Find an existing Safe Hub profile by South African ID number."""
    with get_connection() as conn:
        row = conn.execute(
            "SELECT * FROM users WHERE id_number = ?", (id_number,)
        ).fetchone()

    if not row:
        raise HTTPException(
            status_code=404,
            detail="No profile was found for this ID number.",
        )

    return _row_to_user(row)
