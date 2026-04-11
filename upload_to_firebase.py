"""
Encode ISL sign images as Base64 and store directly in Firestore.
No Firebase Storage or Blaze plan needed!
Stores 3 images (0.jpg, 1.jpg, 2.jpg) per sign (A-Z, 1-9) in 'sign_images' collection.
"""

import os
import json
import base64
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from google.cloud import firestore

# --- Configuration ---
PROJECT_ID = "kairo-ai-041828"
ASSETS_DIR = os.path.join(os.path.dirname(__file__), "assets", "Indian")
IMAGES_PER_FOLDER = 3  # 0.jpg, 1.jpg, 2.jpg

FIREBASE_CONFIG_PATH = os.path.join(
    os.path.expanduser("~"), ".config", "configstore", "firebase-tools.json"
)


def get_credentials():
    """Get credentials from Firebase CLI config."""
    with open(FIREBASE_CONFIG_PATH, "r") as f:
        config = json.load(f)

    tokens = config.get("tokens", {})
    creds = Credentials(
        token=tokens.get("access_token"),
        refresh_token=tokens.get("refresh_token"),
        token_uri="https://oauth2.googleapis.com/token",
        client_id="563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com",
        client_secret="j9iVZfS8kkCEFUPaAeJV0sAi",
    )
    creds.refresh(Request())
    return creds


def upload_images():
    print("=" * 60)
    print("Firestore Image Encoder (Base64)")
    print("=" * 60)

    # Auth
    print("\n[1/3] Authenticating...")
    creds = get_credentials()
    db = firestore.Client(project=PROJECT_ID, credentials=creds)
    print(f"  ✓ Connected to Firestore: {PROJECT_ID}")

    # Find folders
    folders = sorted([
        d for d in os.listdir(ASSETS_DIR)
        if os.path.isdir(os.path.join(ASSETS_DIR, d))
    ])
    total = len(folders) * IMAGES_PER_FOLDER
    print(f"\n[2/3] Found {len(folders)} sign folders, encoding {IMAGES_PER_FOLDER} images each = {total} total")

    # Encode and upload
    print(f"\n[3/3] Encoding images and writing to Firestore...")
    success = 0
    errors = 0

    for folder in folders:
        folder_path = os.path.join(ASSETS_DIR, folder)
        base64_images = []

        for i in range(IMAGES_PER_FOLDER):
            img_path = os.path.join(folder_path, f"{i}.jpg")
            if not os.path.exists(img_path):
                print(f"  ✗ Missing: {folder}/{i}.jpg")
                errors += 1
                continue

            with open(img_path, "rb") as f:
                img_bytes = f.read()

            b64 = base64.b64encode(img_bytes).decode("utf-8")
            base64_images.append(b64)
            size_kb = len(img_bytes) / 1024
            success += 1

        if base64_images:
            doc_ref = db.collection("sign_images").document(folder)
            doc_ref.set({
                "sign": folder,
                "images": base64_images,
                "imageCount": len(base64_images),
                "updatedAt": firestore.SERVER_TIMESTAMP,
            })
            total_kb = sum(len(base64.b64decode(b)) for b in base64_images) / 1024
            print(f"  ✓ {folder}: {len(base64_images)} images ({total_kb:.0f} KB)")
        else:
            print(f"  ✗ {folder}: No images found!")

    print(f"\n{'=' * 60}")
    print(f"✓ Done! {success} images encoded into {len(folders)} Firestore docs")
    print(f"  Collection: sign_images")
    print(f"  Errors: {errors}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    try:
        upload_images()
    except Exception as e:
        print(f"\n✗ Error: {e}")
        raise
