from datetime import datetime

from pydantic import BaseModel, Field


class DataRow(BaseModel):
    id: str
    preceding: str | None
    target: str
    following: str | None
    A1_Score: int
    A2_Score: int
    A3_Score: int
    principle_id: str
    llm_justification: str | None
    llm_evidence_quote: str | None
    expert_opinion: str | None

    # FIXED: Use 'alias' instead of 'serialization_alias' to handle INPUT and OUTPUT
    is_revised: bool = Field(alias="isRevised")
    reviser_name: str | None = Field(default=None, alias="reviserName")
    revision_timestamp: datetime | None = Field(default=None, alias="revisionTimestamp")

    class Config:
        populate_by_name = True
