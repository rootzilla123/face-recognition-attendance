"""
Run this once to create PocketBase collections.
Usage: python setup_pocketbase.py --email admin@school.com --password yourpassword
"""
import requests
import argparse
import json

PB_URL = "http://localhost:8091"

def get_admin_token(email, password):
    # PocketBase v0.23+ uses _superusers collection
    r = requests.post(f"{PB_URL}/api/collections/_superusers/auth-with-password",
                      json={"identity": email, "password": password})
    r.raise_for_status()
    return r.json()["token"]

def create_collection(token, schema):
    headers = {"Authorization": f"Bearer {token}"}
    r = requests.post(f"{PB_URL}/api/collections", json=schema, headers=headers)
    if r.status_code in [400, 409]:
        resp = r.json()
        # Check if it's a duplicate name error
        if "unique" in str(resp).lower() or "exists" in str(resp).lower():
            print(f"  Collection '{schema['name']}' already exists, skipping")
            return
    r.raise_for_status()
    print(f"  Created collection: {schema['name']}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--email", required=True)
    parser.add_argument("--password", required=True, nargs='+')
    args = parser.parse_args()

    token = get_admin_token(args.email, args.password[0] if isinstance(args.password, list) else args.password)
    print("Authenticated with PocketBase admin")

    # users collection (auth type)
    create_collection(token, {
        "name": "users",
        "type": "auth",
        "schema": [
            {"name": "role", "type": "select", "required": True,
             "options": {"maxSelect": 1, "values": ["admin","teacher","student","parent"]}},
            {"name": "profile_id", "type": "text"},
            {"name": "phone", "type": "text"},
            {"name": "avatar", "type": "file", "options": {"maxSelect": 1, "mimeTypes": ["image/jpeg","image/png","image/webp"]}},
        ],
        "options": {"allowEmailAuth": True, "allowUsernameAuth": False, "requireEmail": True}
    })

    # announcements
    create_collection(token, {
        "name": "announcements",
        "type": "base",
        "schema": [
            {"name": "title", "type": "text", "required": True},
            {"name": "content", "type": "editor", "required": True},
            {"name": "author", "type": "relation", "options": {"collectionId": "_pb_users_auth_", "maxSelect": 1}},
            {"name": "target_roles", "type": "json"},
            {"name": "is_published", "type": "bool"},
        ]
    })

    # notifications
    create_collection(token, {
        "name": "notifications",
        "type": "base",
        "schema": [
            {"name": "recipient", "type": "relation", "options": {"collectionId": "_pb_users_auth_", "maxSelect": 1}},
            {"name": "title", "type": "text"},
            {"name": "message", "type": "text", "required": True},
            {"name": "type", "type": "select", "options": {"maxSelect": 1, "values": ["in_app","sms","email"]}},
            {"name": "is_read", "type": "bool"},
            {"name": "related_student_id", "type": "text"},
        ]
    })

    # parent_students
    create_collection(token, {
        "name": "parent_students",
        "type": "base",
        "schema": [
            {"name": "parent", "type": "relation", "required": True, "options": {"collectionId": "_pb_users_auth_", "maxSelect": 1}},
            {"name": "student_id", "type": "text", "required": True},
            {"name": "student_name", "type": "text"},
        ]
    })

    # teacher_cameras
    create_collection(token, {
        "name": "teacher_cameras",
        "type": "base",
        "schema": [
            {"name": "teacher", "type": "relation", "required": True, "options": {"collectionId": "_pb_users_auth_", "maxSelect": 1}},
            {"name": "camera_id", "type": "number", "required": True},
            {"name": "camera_name", "type": "text"},
        ]
    })

    print("\nAll collections created successfully!")
    print("You can now use PocketBase for auth at http://localhost:8091/_/")

if __name__ == "__main__":
    main()
