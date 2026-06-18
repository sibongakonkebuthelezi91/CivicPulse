from fastapi import APIRouter, Depends, HTTPException, Query
from supabase import Client
from typing import Optional
from app.database import get_supabase
from app.models import QueueCreate, QueueUpdate, QueueResponse

router = APIRouter(prefix="/api/queues", tags=["Healthcare Queue"])

# Triage ordering: critical patients are always surfaced first.
TRIAGE_ORDER = {"critical": 0, "urgent": 1, "routine": 2}


def _compute_position(existing: list[dict]) -> int:
    """Return next queue position based on current waiting entries."""
    waiting = [e for e in existing if e["status"] == "waiting"]
    return len(waiting) + 1


@router.post("/", response_model=QueueResponse, status_code=201)
async def add_to_queue(
    patient: QueueCreate,
    db: Client = Depends(get_supabase),
):
    """
    Register a new patient in the healthcare queue.
    Automatically assigns the next queue position.
    Supabase Realtime broadcasts this INSERT to all Flutter listeners.
    """
    # Fetch current waiting list to compute position
    existing = db.table("queues").select("id,status").eq("status", "waiting").execute()
    position = _compute_position(existing.data or [])

    payload = patient.model_dump(mode="json")
    payload["queue_position"] = position

    response = db.table("queues").insert(payload).execute()

    if not response.data:
        raise HTTPException(status_code=500, detail="Failed to add patient to queue.")

    return response.data[0]


@router.get("/", response_model=list[QueueResponse])
async def get_queue(
    status: Optional[str] = Query(None, description="Filter by status: waiting, checked_in, completed"),
    db: Client = Depends(get_supabase),
):
    """
    Retrieve all patients in the queue, sorted by triage priority (critical first),
    then by queue position. Optionally filter by status.
    """
    query = db.table("queues").select("*")

    if status:
        query = query.eq("status", status)

    response = query.execute()
    data = response.data or []

    # Sort: critical → urgent → routine, then by position within each tier
    data.sort(key=lambda p: (TRIAGE_ORDER.get(p["triage_status"], 9), p["queue_position"]))

    return data


@router.get("/{queue_id}", response_model=QueueResponse)
async def get_queue_entry(
    queue_id: int,
    db: Client = Depends(get_supabase),
):
    """
    Fetch a single patient's queue entry by ID.
    """
    response = db.table("queues").select("*").eq("id", queue_id).execute()

    if not response.data:
        raise HTTPException(status_code=404, detail=f"Queue entry {queue_id} not found.")

    return response.data[0]


@router.put("/{queue_id}", response_model=QueueResponse)
async def update_queue_entry(
    queue_id: int,
    updates: QueueUpdate,
    db: Client = Depends(get_supabase),
):
    """
    Update a patient's queue state — triage level, position, or status.

    This triggers a Supabase Realtime UPDATE event, which is broadcast via
    WebSocket to all Flutter clients subscribed to the 'queues' channel.
    """
    payload = updates.model_dump(mode="json", exclude_none=True)

    if not payload:
        raise HTTPException(status_code=422, detail="No fields provided for update.")

    # Stamp the updated_at timestamp
    from datetime import datetime, timezone
    payload["updated_at"] = datetime.now(timezone.utc).isoformat()

    response = (
        db.table("queues")
        .update(payload)
        .eq("id", queue_id)
        .execute()
    )

    if not response.data:
        raise HTTPException(status_code=404, detail=f"Queue entry {queue_id} not found.")

    return response.data[0]


@router.delete("/{queue_id}", status_code=204)
async def remove_from_queue(
    queue_id: int,
    db: Client = Depends(get_supabase),
):
    """
    Remove a completed/discharged patient from the queue.
    """
    response = db.table("queues").delete().eq("id", queue_id).execute()

    if not response.data:
        raise HTTPException(status_code=404, detail=f"Queue entry {queue_id} not found.")
