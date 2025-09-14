# import cv2
# import mediapipe as mp
# import numpy as np
# import time

# mp_holistic = mp.solutions.holistic
# mp_drawing = mp.solutions.drawing_utils

# MOVEMENT_THRESHOLD = 10      # pixels per landmark
# ALARM_DURATION = 5          # seconds
# GRACE_PERIOD = 0.5           # seconds to ignore brief pauses

# video_path = r"C:\Users\Ahmad1\Downloads\istockphoto-1437019503-640_adpp_is.mp4"
# cap = cv2.VideoCapture(video_path)

# prev_landmarks = None
# movement_start_time = None
# last_movement_time = None

# with mp_holistic.Holistic(
#         static_image_mode=False,
#         model_complexity=1,
#         min_detection_confidence=0.5,
#         min_tracking_confidence=0.5) as holistic:

#     while cap.isOpened():
#         ret, frame = cap.read()
#         if not ret:
#             break

#         frame = cv2.flip(frame, 1)
#         rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
#         results = holistic.process(rgb_frame)
#         h, w, c = frame.shape

#         box_color = (0, 255, 0)

#         if results.pose_landmarks:
#             curr_landmarks = [(int(lm.x * w), int(lm.y * h)) for lm in results.pose_landmarks.landmark]

#             xs, ys = zip(*curr_landmarks)
#             x_min, x_max = min(xs), max(xs)
#             y_min, y_max = min(ys), max(ys)

#             moved = False
#             if prev_landmarks:
#                 moved = any(
#                     np.sqrt((cx - px)**2 + (cy - py)**2) > MOVEMENT_THRESHOLD
#                     for (cx, cy), (px, py) in zip(curr_landmarks, prev_landmarks)
#                 )

#             prev_landmarks = curr_landmarks

#             current_time = time.time()

#             if moved:
#                 if movement_start_time is None:
#                     movement_start_time = current_time
#                 last_movement_time = current_time
#                 box_color = (0, 0, 255)
#             else:
#                 # Check if grace period passed without movement
#                 if last_movement_time and current_time - last_movement_time > GRACE_PERIOD:
#                     movement_start_time = None
#                     box_color = (0, 255, 0)
#                 else:
#                     # still in grace period
#                     box_color = (0, 0, 255)

#             # Show alarm if movement lasted long enough
#             if movement_start_time and current_time - movement_start_time >= ALARM_DURATION:
#                 cv2.putText(frame, "ALARM: Baby moving too long!", (50, 50),
#                             cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)

#             cv2.rectangle(frame, (x_min - 10, y_min - 10), (x_max + 10, y_max + 10), box_color, 2)
#             mp_drawing.draw_landmarks(frame, results.pose_landmarks, mp_holistic.POSE_CONNECTIONS)

#         cv2.imshow('Full Body Tracker', frame)
#         if cv2.waitKey(1) & 0xFF == 27:
#             break

# cap.release()
# cv2.destroyAllWindows()


# import cv2
# import mediapipe as mp
# import numpy as np
# import time

# mp_holistic = mp.solutions.holistic
# mp_drawing = mp.solutions.drawing_utils

# MOVEMENT_THRESHOLD = 10      # pixels per landmark
# ALARM_DURATION = 5           # seconds of continuous movement before alarm
# GRACE_PERIOD = 0.5           # seconds to ignore brief pauses
# MOVEMENT_FRAMES_REQUIRED = 3 # consecutive frames to confirm movement

# video_path = r"C:\Users\Ahmad1\Downloads\istockphoto-981037294-640_adpp_is.mp4"
# cap = cv2.VideoCapture(video_path)

# prev_landmarks = None
# movement_start_time = None
# last_movement_time = None
# movement_frame_count = 0   # counter for consecutive movement frames

# with mp_holistic.Holistic(
#         static_image_mode=False,
#         model_complexity=1,
#         min_detection_confidence=0.5,
#         min_tracking_confidence=0.5) as holistic:

#     while cap.isOpened():
#         ret, frame = cap.read()
#         if not ret:
#             break

#         frame = cv2.flip(frame, 1)
#         rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
#         results = holistic.process(rgb_frame)
#         h, w, c = frame.shape

#         # default: green
#         box_color = (0, 255, 0)

#         if results.pose_landmarks:
#             curr_landmarks = [(int(lm.x * w), int(lm.y * h)) for lm in results.pose_landmarks.landmark]

#             xs, ys = zip(*curr_landmarks)
#             x_min, x_max = min(xs), max(xs)
#             y_min, y_max = min(ys), max(ys)

#             moved = False
#             if prev_landmarks:
#                 moved = any(
#                     np.sqrt((cx - px)**2 + (cy - py)**2) > MOVEMENT_THRESHOLD
#                     for (cx, cy), (px, py) in zip(curr_landmarks, prev_landmarks)
#                 )

#             prev_landmarks = curr_landmarks
#             current_time = time.time()

#             if moved:
#                 movement_frame_count += 1
#                 if movement_frame_count >= MOVEMENT_FRAMES_REQUIRED:
#                     if movement_start_time is None:
#                         movement_start_time = current_time
#                     last_movement_time = current_time
#                     box_color = (0, 0, 255)  # RED
#             else:
#                 movement_frame_count = 0  # reset counter
#                 if last_movement_time and current_time - last_movement_time > GRACE_PERIOD:
#                     movement_start_time = None
#                     box_color = (0, 255, 0)  # GREEN
#                 else:
#                     box_color = (0, 255, 0)  # still green

#             # Show alarm if movement lasted too long
#             if movement_start_time and current_time - movement_start_time >= ALARM_DURATION:
#                 cv2.putText(frame, "ALARM: Baby moving too long!", (50, 50),
#                             cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)

#             # Draw box and skeleton
#             cv2.rectangle(frame, (x_min - 10, y_min - 10), (x_max + 10, y_max + 10), box_color, 2)
#             mp_drawing.draw_landmarks(frame, results.pose_landmarks, mp_holistic.POSE_CONNECTIONS)

#         cv2.imshow('Full Body Tracker', frame)
#         if cv2.waitKey(1) & 0xFF == 27:
#             break

# cap.release()
# cv2.destroyAllWindows()

# py -3.9 -m venv baby_env
# baby_env\Scripts\activate
# pip install opencv-python mediapipe numpy


import cv2
import mediapipe as mp
import numpy as np
import time
import math
import os
import requests
from datetime import datetime, timezone
from pymongo import MongoClient

mp_holistic = mp.solutions.holistic
mp_drawing = mp.solutions.drawing_utils

# thresholds
MOVEMENT_THRESHOLD = 10        # pixels per landmark (distance)
ANGLE_THRESHOLD = 15           # degrees change to count as movement
ALARM_DURATION = 5             # seconds
GRACE_PERIOD = 0.5             # seconds to ignore brief pauses
COOLDOWN_WINDOW_SECONDS = 300.0 # 5 minutes window to dedupe events

video_path = r"C:\Users\QSC20\HearYou\HearYou\Server\istockphoto-981037294-640_adpp_is.mp4"
cap = cv2.VideoCapture(video_path)

prev_landmarks = None
prev_angles = None
movement_start_time = None
last_movement_time = None
last_published_ts = 0.0  # epoch seconds of last saved event

API_BASE = os.getenv("API_BASE", "http://127.0.0.1:5000")

# MongoDB configuration (defaults to the requested DB name: HearYou)
MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
DB_NAME = os.getenv("DB_NAME", "HearYou")

# Initialize Mongo client/collection early; if it fails, we fallback to API only
try:
    _mongo_client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=2000)
    _db = _mongo_client[DB_NAME]
    _events_coll = _db["events"]
except Exception:
    _mongo_client = None
    _events_coll = None

def post_event_to_backend(title: str, description: str) -> bool:
    try:
        now_iso = datetime.now(timezone.utc).isoformat()
        payload = {
            "title": title,
            "isImportant": False,
            "eventAt": now_iso,
        }
        resp = requests.post(f"{API_BASE}/events/", json=payload, timeout=3)
        return resp.status_code in (200, 201)
    except Exception:
        return False


def save_event_to_mongo(title: str, description: str) -> None:
    if _events_coll is None:
        return
    try:
        now_dt = datetime.now(timezone.utc)
        doc = {
            "title": title,
            "isImportant": False,
            "eventAt": now_dt,
            "createdAt": now_dt,
        }
        _events_coll.insert_one(doc)
    except Exception:
        # Silent fallback; this script is primarily for local detection
        pass

# function to compute angle between three points
def calculate_angle(a, b, c):
    """Returns the angle at point b in degrees given points a, b, c."""
    a = np.array(a)
    b = np.array(b)
    c = np.array(c)

    ba = a - b
    bc = c - b

    cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-6)
    angle = np.degrees(np.arccos(np.clip(cosine_angle, -1.0, 1.0)))
    return angle

# joints to track their angles
ANGLE_JOINTS = {
    "left_elbow": (11, 13, 15),   # shoulder, elbow, wrist
    "right_elbow": (12, 14, 16),
    "left_knee": (23, 25, 27),    # hip, knee, ankle
    "right_knee": (24, 26, 28),
    "left_shoulder": (13, 11, 23), # elbow, shoulder, hip
    "right_shoulder": (14, 12, 24)
}

with mp_holistic.Holistic(
        static_image_mode=False,
        model_complexity=1,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5) as holistic:

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        frame = cv2.flip(frame, 1)
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = holistic.process(rgb_frame)
        h, w, c = frame.shape

        box_color = (0, 255, 0)  # start green

        if results.pose_landmarks:
            curr_landmarks = [(int(lm.x * w), int(lm.y * h)) for lm in results.pose_landmarks.landmark]

            xs, ys = zip(*curr_landmarks)
            x_min, x_max = min(xs), max(xs)
            y_min, y_max = min(ys), max(ys)

            moved = False

            # Distance check
            if prev_landmarks:
                moved_distance = any(
                    np.sqrt((cx - px)**2 + (cy - py)**2) > MOVEMENT_THRESHOLD
                    for (cx, cy), (px, py) in zip(curr_landmarks, prev_landmarks)
                )
                moved = moved or moved_distance

            # Angle check
            curr_angles = {}
            for name, (a, b, c_idx) in ANGLE_JOINTS.items():
                curr_angles[name] = calculate_angle(
                    curr_landmarks[a], curr_landmarks[b], curr_landmarks[c_idx]
                )

            if prev_angles:
                moved_angle = any(
                    abs(curr_angles[name] - prev_angles[name]) > ANGLE_THRESHOLD
                    for name in ANGLE_JOINTS
                )
                moved = moved or moved_angle

            prev_landmarks = curr_landmarks
            prev_angles = curr_angles

            current_time = time.time()

            if moved:
                if movement_start_time is None:
                    movement_start_time = current_time
                last_movement_time = current_time
                box_color = (0, 0, 255)  # red
            else:
                if last_movement_time and current_time - last_movement_time > GRACE_PERIOD:
                    movement_start_time = None
                    box_color = (0, 255, 0)
                else:
                    box_color = (0, 0, 255)

            # Alarm
            if movement_start_time and current_time - movement_start_time >= ALARM_DURATION:
                cv2.putText(frame, "ALARM: Baby moving too long!", (50, 50),
                            cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
                # Publish at most once every COOLDOWN_WINDOW_SECONDS, even if multiple movements occur
                if current_time - last_published_ts >= COOLDOWN_WINDOW_SECONDS:
                    published = post_event_to_backend(
                        title="baby movement",
                        description="Detected continuous baby movement for threshold duration",
                    )
                    if not published:
                        save_event_to_mongo(
                            title="baby movement",
                            description="Detected continuous baby movement for threshold duration",
                        )
                    last_published_ts = current_time

            cv2.rectangle(frame, (x_min - 10, y_min - 10),
                          (x_max + 10, y_max + 10), box_color, 2)
            mp_drawing.draw_landmarks(frame, results.pose_landmarks, mp_holistic.POSE_CONNECTIONS)

        cv2.imshow('Full Body Tracker (Hybrid)', frame)
        if cv2.waitKey(1) & 0xFF == 27:  # ESC to quit
            break

cap.release()
cv2.destroyAllWindows()
