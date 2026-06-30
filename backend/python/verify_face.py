from deepface import DeepFace
import json
import sys
import numpy as np

THRESHOLD = 0.85

image_path = sys.argv[1]
embedding_file = sys.argv[2]

try:
    # Membaca embedding user yang tersimpan
    with open(embedding_file, "r") as f:
        stored_embedding = json.load(f)

    # Mengambil embedding dari foto baru
    new_embedding = DeepFace.represent(
        img_path=image_path,
        model_name="Facenet512",
        enforce_detection=True
    )[0]["embedding"]

    # Hitung cosine similarity
    a = np.array(stored_embedding, dtype=np.float32)
    b = np.array(new_embedding, dtype=np.float32)

    similarity = float(
        np.dot(a, b) /
        (np.linalg.norm(a) * np.linalg.norm(b))
    )

    result = {
        "success": True,
        "similarity": similarity,
        "threshold": THRESHOLD,
        "match": bool(similarity >= THRESHOLD)
    }

except Exception as e:
    result = {
        "success": False,
        "message": str(e)
    }

# Pastikan output hanya SATU JSON
print(json.dumps(result))
