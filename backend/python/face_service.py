import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

import logging
from flask import Flask, request, jsonify
from deepface import DeepFace
import numpy as np

app = Flask(__name__)

# ==========================================================
# Logger khusus kalibrasi anti-spoofing.
# ==========================================================
# Tujuannya: kumpulkan antispoof_score untuk SETIAP percobaan verifikasi
# (baik yang lolos maupun yang kena flag spoof), supaya kita bisa lihat
# sebaran score wajah ASLI (dari kamera depan HP staf/guru) di kondisi
# nyata sekolah, sebelum menentukan SPOOF_CONFIDENCE_THRESHOLD final.
# Cek isi log ini secara berkala di logs/antispoof_calibration.log.
calibration_logger = logging.getLogger("antispoof_calibration")
calibration_logger.setLevel(logging.INFO)
_log_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "logs")
os.makedirs(_log_dir, exist_ok=True)
_handler = logging.FileHandler(os.path.join(_log_dir, "antispoof_calibration.log"))
_handler.setFormatter(logging.Formatter("%(asctime)s %(message)s"))
calibration_logger.addHandler(_handler)

# ==========================================================
# Ambang batas confidence untuk anggap foto benar-benar spoof.
# ==========================================================
# `is_real` dari DeepFace adalah hasil argmax internal MiniFASNet --
# BUKAN threshold yang bisa kita atur lewat parameter publik. Model ini
# dilatih dengan dataset yang mayoritas foto "asli"-nya diambil dari
# kamera belakang dengan jarak & pencahayaan tertentu, sehingga selfie
# dari kamera depan HP (jarak dekat, cahaya datar/dari layar sendiri)
# punya karakteristik yang kadang mirip pola foto-dari-layar -> false
# positive ke wajah asli.
#
# Solusinya: pakai antispoof_score (confidence, 0.0-1.0) sebagai sinyal
# tambahan, bukan cuma is_real mentah. Kalau is_real == False TAPI
# confidence-nya di bawah threshold ini, anggap masih ambigu -> JANGAN
# tolak (lebih baik false negative -- lolos padahal agak mencurigakan --
# daripada false positive yang bikin staf/guru asli tidak bisa absen).
#
# NILAI INI SUDAH DIKALIBRASI berdasarkan data logs/antispoof_calibration.log
# (12 percobaan, 10 wajah asli + 2 percobaan spoof beneran):
#   - Wajah ASLI (raw_is_real=True semua): antispoof_score berkisar
#     0.5431 - 0.9712 (variasi kondisi terang, gelap modal cahaya HP, dst)
#   - SPOOF beneran (foto dari layar HP lain, raw_is_real=False semua):
#     antispoof_score = 0.9999 pada kedua percobaan
#
# Ada celah aman di antara skor wajah asli tertinggi (~0.97) dan skor
# spoof (0.9999). Threshold 0.98 diletakkan di celah ini, supaya:
#   - Kalau raw_is_real salah jadi False untuk wajah asli (score masih
#     di rentang 0.54-0.97 yang sudah teramati) -> TETAP DILOLOSKAN
#     (verdict "ambiguous_allowed")
#   - Kalau score mendekati 1.0 (pola foto-dari-layar/print sungguhan)
#     -> TETAP DITOLAK sebagai spoof
#
# Threshold lama (0.85) ternyata kurang tepat: karena 0.85 < 0.85 selalu
# False, kasus wajah asli dengan score 0.85-0.97 (jelas ada di rentang
# normal) TIDAK akan pernah tertolong oleh jaring pengaman "ambigu" ini
# kalau raw_is_real kebetulan salah.
#
# Tetap pantau logs/antispoof_calibration.log secara berkala -- kalau
# nanti ada kasus spoof sungguhan dengan score < 0.98, atau wajah asli
# dengan score > 0.98, sesuaikan lagi angka ini.
SPOOF_CONFIDENCE_THRESHOLD = 0.98

# ==========================================================
# Warm-up: load model + anti-spoofing sekali saat service start
# ==========================================================
# extract_faces dengan anti_spoofing=True akan otomatis mengunduh &
# meng-cache model MiniFASNet (dipakai untuk deteksi print/replay
# attack) selain RetinaFace yang dipakai untuk deteksi wajah.
DeepFace.represent(
    img_path=np.zeros((160, 160, 3), dtype='uint8'),
    model_name="Facenet512",
    enforce_detection=False
)

DeepFace.extract_faces(
    img_path=np.zeros((160, 160, 3), dtype='uint8'),
    detector_backend="retinaface",
    anti_spoofing=True,
    enforce_detection=False
)

print("Model loaded, service ready.")


def _check_liveness(image_path):
   
    try:
        faces = DeepFace.extract_faces(
            img_path=image_path,
            detector_backend="retinaface",
            anti_spoofing=True,
            enforce_detection=True
        )
    except Exception as e:
        return False, 0.0, str(e), None

    if not faces:
        return False, 0.0, "Wajah tidak terdeteksi.", None

    face = faces[0]
    raw_is_real = bool(face.get("is_real", False))
    antispoof_score = float(face.get("antispoof_score", 0.0))
    cropped_face = face.get("face")

    if raw_is_real:
        final_is_real = True
        verdict = "real"
    elif antispoof_score < SPOOF_CONFIDENCE_THRESHOLD:
        # Ambigu -> jangan blok, tapi tetap ditandai di log sebagai
        # "ambiguous" supaya kelihatan berapa banyak kasus begini terjadi.
        final_is_real = True
        verdict = "ambiguous_allowed"
    else:
        final_is_real = False
        verdict = "spoof"

    calibration_logger.info(
        "raw_is_real=%s antispoof_score=%.4f threshold=%.2f verdict=%s",
        raw_is_real, antispoof_score, SPOOF_CONFIDENCE_THRESHOLD, verdict
    )

    return final_is_real, antispoof_score, None, cropped_face


@app.route('/represent', methods=['POST'])
def represent():
    image_path = request.json.get('image_path')
    try:
        embedding = DeepFace.represent(
            img_path=image_path,
            model_name="Facenet512",
            enforce_detection=True,
            detector_backend="retinaface"
        )[0]["embedding"]
        return jsonify({"success": True, "embedding": embedding})
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 200


@app.route('/verify', methods=['POST'])
def verify():
    image_path = request.json.get('image_path')
    stored_embeddings = request.json.get('stored_embeddings')  # list of list
    threshold = request.json.get('threshold', 0.78)

    try:
        # ==========================
        # 1. Cek liveness dulu SEBELUM face matching.
        #    Kalau ini foto-dari-foto (spoof), tolak di sini tanpa
        #    perlu buang waktu menghitung similarity segala.
        #
        #    ✅ OPTIMASI: cropped_face dari sini langsung dipakai lagi
        #    di langkah 2 (represent), jadi RetinaFace cuma jalan 1x
        #    per request, bukan 2x seperti sebelumnya.
        # ==========================
        is_real, antispoof_score, liveness_error, cropped_face = _check_liveness(image_path)

        if liveness_error:
            return jsonify({
                "success": False,
                "message": liveness_error
            }), 200

        if not is_real:
            return jsonify({
                "success": True,
                "match": False,
                "spoof_detected": True,
                "antispoof_score": antispoof_score,
                "message": "Terdeteksi kemungkinan foto tidak asli (bukan wajah langsung dari kamera)."
            })

        # ==========================
        # 2. Baru lanjut ke face matching seperti biasa.
        #    Pakai wajah yang SUDAH di-crop dari langkah 1 di atas
        #    (cropped_face), bukan deteksi ulang dari image_path.
        #    detector_backend="skip" + enforce_detection=False supaya
        #    DeepFace tidak menjalankan RetinaFace lagi.
        # ==========================
        new_embedding = DeepFace.represent(
            img_path=cropped_face,
            model_name="Facenet512",
            enforce_detection=False,
            detector_backend="skip"
        )[0]["embedding"]

        b = np.array(new_embedding, dtype=np.float32)
        best_similarity = -1.0

        for stored in stored_embeddings:
            a = np.array(stored, dtype=np.float32)
            sim = float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))
            if sim > best_similarity:
                best_similarity = sim

        return jsonify({
            "success": True,
            "similarity": best_similarity,
            "threshold": threshold,
            "match": bool(best_similarity >= threshold),
            "spoof_detected": False,
            "antispoof_score": antispoof_score
        })
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 200


if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5001)
