from __future__ import annotations
from datetime import datetime
from typing import Any, Optional
from pydantic import BaseModel


class QuestionCreate(BaseModel):
    type: str
    label: str
    options: Optional[Any] = None
    required: bool = False
    order: int


class SurveyCreate(BaseModel):
    title: str
    description: Optional[str] = None
    questions: list[QuestionCreate]


class QuestionOut(BaseModel):
    id: int
    type: str
    label: str
    options: Optional[Any] = None
    required: bool
    order: int

    model_config = {"from_attributes": True}


class SurveyOut(BaseModel):
    id: int
    slug: str
    title: str
    description: Optional[str] = None
    is_active: bool
    created_at: datetime
    questions: list[QuestionOut] = []

    model_config = {"from_attributes": True}


class AnswerIn(BaseModel):
    question_id: int
    value: str


class ResponseCreate(BaseModel):
    answers: list[AnswerIn]
