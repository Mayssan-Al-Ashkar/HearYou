import os
import time
import requests
import sounddevice as sd
import numpy as np
import tensorflow as tf
import tensorflow_hub as hub
from datetime import datetime

# -------------------------------
# Load YAMNet model from TensorFlow Hub
# -------------------------------
print("🔄 Loading YAMNet model...")
yamnet_model = hub.load("https://tfhub.dev/google/yamnet/1")
print("✅ Model loaded!")

# Load class map
class_map_path = yamnet_model.class_map_path().numpy().decode("utf-8")
class_names = []
with open(class_map_path, "r") as f:
    next(f)  # skip header
    for line in f:
        parts = line.strip().split(",")
        if len(parts) >= 3:
            class_names.append(parts[2])

# -------------------------------
# Settings
# -------------------------------
SAMPLE_RATE = 16000   # YAMNet requires 16 kHz audio
DURATION = 1.0        # seconds per recording chunk
CONF_THRESHOLD = 0.3  # minimum confidence to consider a prediction
COOLDOWN_SECONDS = 120.0  # minimum seconds between same event (2 minutes)
HISTORY_LEN = 5       # number of past chunks to consider for smoothing

# Backend API
API_BASE = os.getenv("API_BASE", "http://localhost:5000")

# Tokens of interest (loose matching against model labels)
BABY_TOKENS = ["baby", "infant", "cry", "crying", "whimper", "wail", "scream", "sob"]
DOOR_TOKENS = ["door", "doorbell", "door bell", "knock", "knocking"]

# -------------------------------
# Functions
# -------------------------------
def record_audio(duration, sample_rate):
    """Record a short chunk of audio."""
    audio = sd.rec(
        int(duration * sample_rate),
        samplerate=sample_rate,
        channels=1,
        dtype="float32"
    )
    sd.wait()
    return np.squeeze(audio)

def predict(audio_data):
    """Run YAMNet prediction and return top class + confidence."""
    scores, embeddings, spectrogram = yamnet_model(audio_data)
    mean_scores = np.mean(scores.numpy(), axis=0)
    top_index = np.argmax(mean_scores)
    return class_names[top_index], mean_scores[top_index]

def post_event(title: str, event_dt: float):
    """Send event to backend API."""
    try:
        iso_time = datetime.utcfromtimestamp(event_dt).isoformat()
        resp = requests.post(
            f"{API_BASE}/events/",
            json={"title": title, "eventAt": iso_time},
            timeout=5,
        )
        if resp.status_code not in (200, 201):
            print(f"[❌] Failed to post event: {resp.status_code} {resp.text}")
    except Exception as exc:
        print(f"[⚠️] Error posting event: {exc}")

# -------------------------------
# Main loop
# -------------------------------
print("🎤 Starting continuous audio detection... Press Ctrl+C to stop.")

# Cooldowns to prevent duplicate events
last_sent = {"baby crying": 0.0, "doorbell": 0.0}

def classify_title(label_lc: str) -> str | None:
    if any(tok in label_lc for tok in BABY_TOKENS):
        return "baby crying"
    if any(tok in label_lc for tok in DOOR_TOKENS):
        return "doorbell"
    return None

try:
    while True:
        audio_chunk = record_audio(DURATION, SAMPLE_RATE)
        audio_tensor = tf.convert_to_tensor(audio_chunk, dtype=tf.float32)

        class_name, confidence = predict(audio_tensor)
        lc = class_name.lower()
        now_ts = time.time()

        # Print live detection
        print(f"Detected: {class_name} | Confidence: {confidence:.2f}")

        # Simple trigger: if top label matches, confidence high enough, and 2-minute gap
        if confidence >= CONF_THRESHOLD:
            title = classify_title(lc)
            if title is not None:
                if now_ts - last_sent.get(title, 0) > COOLDOWN_SECONDS:
                    post_event(title, now_ts)
                    print(f"✅ Event saved: {title}")
                    last_sent[title] = now_ts

        time.sleep(0.1)  # avoid flooding the terminal

except KeyboardInterrupt:
    print("\n🛑 Stopped by user.")
