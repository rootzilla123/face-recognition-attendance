"""Add clip_path to attendance_records

Revision ID: a1b2c3d4e5f6
Revises: 7664bb61c746
Create Date: 2026-04-22

"""
from alembic import op
import sqlalchemy as sa

revision = "a1b2c3d4e5f6"
down_revision = "7664bb61c746"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "attendance_records",
        sa.Column("clip_path", sa.String(500), nullable=True),
    )


def downgrade():
    op.drop_column("attendance_records", "clip_path")
