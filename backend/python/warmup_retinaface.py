from deepface import DeepFace
import numpy as np

print("Downloading & caching RetinaFace + Facenet512 weight...")

DeepFace.represent(
    img_path=np.zeros((160, 160, 3), dtype='uint8'),
    model_name="Facenet512",
    enforce_detection=False,
    detector_backend="retinaface"
)

print("Downloading & caching anti-spoofing (MiniFASNet) weight...")

DeepFace.extract_faces(
    img_path=np.zeros((160, 160, 3), dtype='uint8'),
    detector_backend="retinaface",
    anti_spoofing=True,
    enforce_detection=False
)

print("Done. Semua weight sudah tersimpan di cache lokal.")
