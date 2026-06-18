from fastapi import APIRouter, Depends, HTTPException, Query
from supabase import Client
from typing import Optional
from app.database import get_supabase
from app.models import ReportCreate, ReportResponse

router = APIRouter(prefix="/api/reports", tags=["Infrastructure Reports"])


@router.post("/", response_model=ReportResponse, status_code=201)
async def create_report(
    report: ReportCreate,
    db: Client = Depends(get_supabase),
):
    """
    Submit a new infrastructure report.
    Types accepted: 'pothole', 'traffic_light', 'animal'
    """
    valid_types = {"pothole", "traffic_light", "animal"}
    if report.type not in valid_types:
        raise HTTPException(
            status_code=422,
            detail=f"Invalid report type '{report.type}'. Must be one of: {', '.join(valid_types)}",
        )

    payload = report.model_dump(mode="json")

    response = db.table("reports").insert(payload).execute()

    if not response.data:
        raise HTTPException(status_code=500, detail="Failed to create report.")

    return response.data[0]


@router.get("/", response_model=list[ReportResponse])
async def get_reports(
    type: Optional[str] = Query(None, description="Filter by type: pothole, traffic_light, animal"),
    status: Optional[str] = Query(None, description="Filter by status: pending, in_progress, resolved"),
    limit: int = Query(50, ge=1, le=200, description="Max number of results"),
    db: Client = Depends(get_supabase),
):
    """
    Retrieve all infrastructure reports, with optional filters by type and/or status.
    """
    query = db.table("reports").select("*").order("created_at", desc=True).limit(limit)

    if type:
        query = query.eq("type", type)
    if status:
        query = query.eq("status", status)

    response = query.execute()
    return response.data or []


@router.get("/nearby", response_model=list[ReportResponse])
async def get_nearby_reports(
    lat: float = Query(..., description="Centre latitude"),
    lon: float = Query(..., description="Centre longitude"),
    radius_km: float = Query(1.0, description="Search radius in kilometres"),
    db: Client = Depends(get_supabase),
):
    """
    Retrieve reports within an approximate bounding box around the given coordinates.
    Uses a simple degree-based bounding box (1° ≈ 111 km) for zero-dependency speed.
    """
    delta = radius_km / 111.0

    response = (
        db.table("reports")
        .select("*")
        .gte("latitude", lat - delta)
        .lte("latitude", lat + delta)
        .gte("longitude", lon - delta)
        .lte("longitude", lon + delta)
        .order("created_at", desc=True)
        .execute()
    )
    return response.data or []


@router.patch("/{report_id}", response_model=ReportResponse)
async def update_report_status(
    report_id: int,
    status: str = Query(..., description="New status: pending, in_progress, resolved"),
    db: Client = Depends(get_supabase),
):
    """
    Update the status of an existing report (e.g., mark pothole as resolved).
    """
    valid_statuses = {"pending", "in_progress", "resolved"}
    if status not in valid_statuses:
        raise HTTPException(
            status_code=422,
            detail=f"Invalid status '{status}'. Must be one of: {', '.join(valid_statuses)}",
        )

    response = (
        db.table("reports")
        .update({"status": status})
        .eq("id", report_id)
        .execute()
    )

    if not response.data:
        raise HTTPException(status_code=404, detail=f"Report {report_id} not found.")

    return response.data[0]
