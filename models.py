from datetime import datetime
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, JSON, String, Text
from sqlalchemy.orm import relationship
from database import Base


class Survey(Base):
    __tablename__ = "surveys"

    id = Column(Integer, primary_key=True, index=True)
    slug = Column(String(200), unique=True, index=True, nullable=False)
    title = Column(String(300), nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    questions = relationship(
        "Question", back_populates="survey",
        order_by="Question.order", cascade="all, delete-orphan"
    )
    responses = relationship("Response", back_populates="survey", cascade="all, delete-orphan")


class Question(Base):
    __tablename__ = "questions"

    id = Column(Integer, primary_key=True, index=True)
    survey_id = Column(Integer, ForeignKey("surveys.id"), nullable=False)
    # Tipos: text, textarea, radio, checkbox, scale, select
    type = Column(String(50), nullable=False)
    label = Column(String(500), nullable=False)
    # radio/checkbox/select → ["Op1","Op2",...] | scale → {"min":1,"max":5,"min_label":"","max_label":""}
    options = Column(JSON, nullable=True)
    required = Column(Boolean, default=False)
    order = Column(Integer, nullable=False)

    survey = relationship("Survey", back_populates="questions")
    answers = relationship("Answer", back_populates="question", cascade="all, delete-orphan")


class Response(Base):
    __tablename__ = "responses"

    id = Column(Integer, primary_key=True, index=True)
    survey_id = Column(Integer, ForeignKey("surveys.id"), nullable=False)
    submitted_at = Column(DateTime, default=datetime.utcnow)

    survey = relationship("Survey", back_populates="responses")
    answers = relationship("Answer", back_populates="response", cascade="all, delete-orphan")


class Answer(Base):
    __tablename__ = "answers"

    id = Column(Integer, primary_key=True, index=True)
    response_id = Column(Integer, ForeignKey("responses.id"), nullable=False)
    question_id = Column(Integer, ForeignKey("questions.id"), nullable=False)
    # Texto libre o JSON para listas (checkbox)
    value = Column(Text, nullable=True)

    response = relationship("Response", back_populates="answers")
    question = relationship("Question", back_populates="answers")
