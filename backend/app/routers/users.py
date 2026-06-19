from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from supabase import Client

from app.database import get_supabase
from app.models import UserCreate, UserResponse

router = APIRouter(prefix="/api/users", tags=["Users"])


@router.post("/", response_model=UserResponse, status_code=201)
async def create_user(
    user: UserCreate,
    db: Client = Depends(get_supabase),
):
    """
    Create a Safe Hub user profile.
    The SA ID number is unique and is used for ID-only sign-in.
    """
    existing = (
        db.table("users")
        .select("*")
        .eq("id_number", user.id_number)
        .limit(1)
        .execute()
    )

    if existing.data:
        raise HTTPException(
            status_code=409,
            detail="A profile already exists for this ID number.",
        )

    payload = user.model_dump(mode="json", exclude_none=True)
    payload["id"] = str(user.id or uuid4())

    response = db.table("users").insert(payload).execute()

    if not response.data:
        raise HTTPException(status_code=500, detail="Failed to create user.")

    return response.data[0]


@router.get("/id-number/{id_number}", response_model=UserResponse)
async def get_user_by_id_number(
    id_number: str,
    db: Client = Depends(get_supabase),
):
    """Find an existing Safe Hub profile by South African ID number."""
    response = (
        db.table("users")
        .select("*")
        .eq("id_number", id_number)
        .limit(1)
        .execute()
    )

    if not response.data:
        raise HTTPException(
            status_code=404,
            detail="No profile was found for this ID number.",
        )

    return response.data[0]
