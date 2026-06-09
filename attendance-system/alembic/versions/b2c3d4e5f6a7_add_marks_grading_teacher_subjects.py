"""Add student_marks, grading_schemes, teacher_subjects tables

Revision ID: b2c3d4e5f6a7
Revises: a1b2c3d4e5f6
Create Date: 2026-04-23

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID
import uuid

revision = "b2c3d4e5f6a7"
down_revision = "a1b2c3d4e5f6"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "grading_schemes",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("min_score_percent", sa.DECIMAL(5, 2), nullable=False),
        sa.Column("grade", sa.String(5), nullable=False),
        sa.Column("is_active", sa.Boolean(), server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_table(
        "teacher_subjects",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column("teacher_id", UUID(as_uuid=True), sa.ForeignKey("teachers.id"), nullable=False),
        sa.Column("subject", sa.String(100), nullable=False),
        sa.Column("class_name", sa.String(100), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_table(
        "student_marks",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column("student_id", UUID(as_uuid=True), sa.ForeignKey("students.id"), nullable=False),
        sa.Column("teacher_id", UUID(as_uuid=True), sa.ForeignKey("teachers.id"), nullable=False),
        sa.Column("subject", sa.String(100), nullable=False),
        sa.Column("term", sa.String(50), nullable=False),
        sa.Column("score", sa.DECIMAL(5, 2), nullable=False),
        sa.Column("max_score", sa.DECIMAL(5, 2), nullable=False, server_default="100"),
        sa.Column("grade", sa.String(5)),
        sa.Column("remarks", sa.Text()),
        sa.Column("is_published", sa.Boolean(), server_default="false"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), onupdate=sa.func.now()),
    )

    # Seed default grading scheme (A-F)
    op.execute("""
        INSERT INTO grading_schemes (id, name, min_score_percent, grade, is_active)
        VALUES
            (gen_random_uuid(), 'Default', 80, 'A', true),
            (gen_random_uuid(), 'Default', 70, 'B', true),
            (gen_random_uuid(), 'Default', 60, 'C', true),
            (gen_random_uuid(), 'Default', 50, 'D', true),
            (gen_random_uuid(), 'Default',  0, 'F', true)
    """)


def downgrade():
    op.drop_table("student_marks")
    op.drop_table("teacher_subjects")
    op.drop_table("grading_schemes")
