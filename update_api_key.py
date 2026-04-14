#!/usr/bin/env python3
"""
Script to update CompreFace API key in .env file
"""

import sys

if len(sys.argv) != 2:
    print("Usage: python update_api_key.py <new-api-key>")
    sys.exit(1)

new_api_key = sys.argv[1]

# Read .env file
with open('attendance-system/.env', 'r') as f:
    lines = f.readlines()

# Update API key line
updated_lines = []
for line in lines:
    if line.startswith('COMPREFORE_API_KEY='):
        updated_lines.append(f'COMPREFORE_API_KEY={new_api_key}\n')
    else:
        updated_lines.append(line)

# Write back
with open('attendance-system/.env', 'w') as f:
    f.writelines(updated_lines)

print(f"✓ API key updated to: {new_api_key}")
print("✓ Please restart your backend for changes to take effect")
