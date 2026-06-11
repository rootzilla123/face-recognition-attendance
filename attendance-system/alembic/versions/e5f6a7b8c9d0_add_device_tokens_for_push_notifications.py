"""add_device_tokens_for_push_notifications

Revision ID: e5f6a7b8c9d0
Revises: d4e5f6a7b8c9
Create Date: 2026-04-30 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'e5f6a7b8c9d0'
down_revision = 'd4e5f6a7b8c9'
branch_labels = None
depends_on = None


def upgrade():
    # Add device_tokens column to users table (JSONB array of tokens)
    op.add_column('users', sa.Column('device_tokens', postgresql.JSONB, nullable=True, server_default='[]'))
    
    # Add fcm_token columns to role-specific tables for backward compatibility
    op.add_column('parents', sa.Column('fcm_token', sa.String(500), nullable=True))
    op.add_column('teachers', sa.Column('fcm_token', sa.String(500), nullable=True))
    op.add_column('administrators', sa.Column('fcm_token', sa.String(500), nullable=True))


def downgrade():
    op.drop_column('users', 'device_tokens')
    op.drop_column('parents', 'fcm_token')
    op.drop_column('teachers', 'fcm_token')
    op.drop_column('administrators', 'fcm_token')
