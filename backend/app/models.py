# pyrefly: ignore [missing-import]
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from uuid import UUID

# User Models
class UserBase(BaseModel):
    phone: str = Field(..., description="User phone number for notifications")
    name: str = Field(..., description="User's full name")
    role: str = Field("citizen", description="Role: citizen, doctor, driver, or volunteer")

class UserCreate(UserBase):
    id: UUID = Field(..., description="Authentication UUID from auth system")

class UserResponse(UserBase):
    id: UUID
    created_at: datetime

    class Config:
        from_attributes = True


# Report Models (potholes, lights, animals)
class ReportBase(BaseModel):
    type: str = Field(..., description="Type of report: 'pothole', 'traffic_light', 'animal'")
    description: Optional[str] = Field(None, description="Detailed description of the issue")
    latitude: float = Field(..., description="Latitude coordinate")
    longitude: float = Field(..., description="Longitude coordinate")
    status: str = Field("pending", description="Status: pending, in_progress, resolved")
    media_url: Optional[str] = Field(None, description="Optional attachment/image URL")

class ReportCreate(ReportBase):
    reporter_id: Optional[UUID] = Field(None, description="ID of the user who reported this")

class ReportResponse(ReportBase):
    id: int
    reporter_id: Optional[UUID] = None
    created_at: datetime

    class Config:
        from_attributes = True


# Healthcare Queue Models
class QueueBase(BaseModel):
    patient_name: str = Field(..., description="Patient's name")
    patient_phone: Optional[str] = Field(None, description="Patient's phone number for SMS status updates")
    symptoms: Optional[str] = Field(None, description="Brief symptom description")
    pain_level: Optional[int] = Field(None, ge=1, le=10, description="Pain level rating from 1 to 10")
    triage_status: str = Field("routine", description="Priority level: critical, urgent, routine")

class QueueCreate(QueueBase):
    pass

class QueueUpdate(BaseModel):
    patient_name: Optional[str] = None
    patient_phone: Optional[str] = None
    symptoms: Optional[str] = None
    pain_level: Optional[int] = Field(None, ge=1, le=10)
    triage_status: Optional[str] = None
    queue_position: Optional[int] = None
    status: Optional[str] = Field(None, description="Status: waiting, checked_in, completed")

class QueueResponse(QueueBase):
    id: int
    queue_position: int
    status: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# Walk Group Models
class WalkGroupBase(BaseModel):
    route_name: str = Field(..., description="Route descriptor, e.g., 'Station A to Community B'")
    start_latitude: float
    start_longitude: float
    end_latitude: float
    end_longitude: float
    departure_time: datetime
    status: str = Field("scheduled", description="Status: scheduled, active, completed")

class WalkGroupCreate(WalkGroupBase):
    creator_id: UUID = Field(..., description="ID of the citizen initiating the walking group")

class WalkGroupResponse(WalkGroupBase):
    id: int
    creator_id: UUID
    created_at: datetime

    class Config:
        from_attributes = True
