from fastapi import HTTPException
from supabase import create_client, Client
from app.config import settings

# Initialize Supabase client
supabase_client: Client = None

if settings.SUPABASE_URL and settings.SUPABASE_KEY:
    supabase_client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)

def get_supabase() -> Client:
    """
    Dependency helper to retrieve the Supabase client.
    Raises ValueError if credentials are not configured.
    """
    if not supabase_client:
        raise HTTPException(
            status_code=500,
            detail=(
                "Supabase credentials are not configured. "
                "Please set SUPABASE_URL and SUPABASE_KEY in backend/.env or environment variables."
            ),
        )
    return supabase_client
