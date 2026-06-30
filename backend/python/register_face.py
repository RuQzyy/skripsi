import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

from deepface import DeepFace
import json
import sys

image_path = sys.argv[1]

embedding = DeepFace.represent(
    img_path=image_path,
    model_name="Facenet512",
    enforce_detection=True
)

print(json.dumps(
    embedding[0]["embedding"]
))
