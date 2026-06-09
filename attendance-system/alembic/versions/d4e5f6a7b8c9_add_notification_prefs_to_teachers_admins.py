"""Add notification_preferences and phone to teachers and administrators

Revision ID: d4e5f6a7b8c9
Revises: c3d4e5f6a7b8
Create Date: 2026-04-23

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = "d4e5f6a7b8c9"
down_revision = "c3d4e5f6a7b8"
branch_labels = None
depends_on = None

_DEFAULT_PREFS = '{"sms": true, "email": true, "in_app": true, "language": "en"}'


def upgrade():
    # administrators — add phone + notification_preferences
    op.add_column("administrators",
        sa.Column("phone", sa.String(20), nullable=True))
    op.add_column("administrators",
        sa.Column("notification_preferences", JSONB, server_default=_DEFAULT_PREFS, nullable=True))

    # teachers — add notification_preferences
    op.add_column("teachers",
        sa.Column("notification_preferences", JSONB, server_default=_DEFAULT_PREFS, nullable=True))

    # Backfill NULLs
    op.execute(f"UPDATE administrators SET notification_preferences = '{_DEFAULT_PREFS}' WHERE notification_preferences IS NULL")
    op.execute(f"UPDATE teachers SET notification_preferences = '{_DEFAULT_PREFS}' WHERE notification_preferences IS NULL")


def downgrade():
    op.drop_column("teachers", "notification_preferences")
    op.drop_column("administrators", "notification_preferences")
    op.drop_column("administrators", "phone")
