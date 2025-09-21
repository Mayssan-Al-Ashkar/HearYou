import os
import json
import time
import threading
from datetime import datetime, timezone

import serial  # pyserial
from pymongo import MongoClient
from pymongo.errors import PyMongoError
import requests


API_BASE = os.getenv("API_BASE", "http://127.0.0.1:5000")
MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017")
MONGO_DB = os.getenv("MONGO_DB", "hearyou")
EVENTS_COLLECTION = os.getenv("MONGO_EVENTS_COLLECTION", "events")
SETTINGS_COLLECTION = os.getenv("MONGO_SETTINGS_COLLECTION", "settings")

SERIAL_PORT = os.getenv("BRACELET_COM", "COM3")
SERIAL_BAUD = int(os.getenv("BRACELET_BAUD", "9600"))
VIBRATION_MS = int(os.getenv("BRACELET_VIB_MS", "800"))


class BraceletSerial:
    def __init__(self, port: str, baud: int):
        self.port = port
        self.baud = baud
        self.ser = None
        self.lock = threading.Lock()

    def connect(self):
        self.ser = serial.Serial(self.port, self.baud, timeout=1)
        time.sleep(2.0)
        self.ser.reset_input_buffer()

    def close(self):
        try:
            if self.ser:
                self.ser.close()
        except Exception:
            pass

    def send_command(self, color: str | None = None, vibrate: int | None = None, off: bool = False):
        payload: dict[str, object] = {}
        if off:
            payload = {"off": 1}
        else:
            if color is not None:
                payload["color"] = color
            if vibrate is not None:
                payload["vibrate"] = int(max(0, min(255, vibrate)))
        line = json.dumps(payload)
        try:
            print(f"[BRACELET] SEND {line}")
        except Exception:
            pass
        with self.lock:
            self.ser.write((line + "\n").encode("utf-8"))

    def iter_lines(self):
        while True:
            try:
                raw = self.ser.readline()
                if not raw:
                    yield None
                    continue
                yield raw.decode("utf-8", errors="ignore").strip()
            except Exception:
                yield None


def event_title_to_key(title: str) -> str:
    t = (title or "").strip().lower()
    mapping = {
        "baby crying": "baby_crying",
        "baby movement": "baby_movement",
        "phone call": "phone_call",
        "phone calling": "phone_call",
        "door knocking": "door_knocking",
        "door knocking ": "door_knocking",
    }
    if t in mapping:
        return mapping[t]
    return t.replace(" ", "_")


class SettingsCache:
    def __init__(self, db):
        self.col = db[SETTINGS_COLLECTION]
        self.colors: dict[str, str] = {}
        self.vibration: bool = False
        self.quiet_hours: dict | None = None
        self.lock = threading.Lock()
        self.reload()

    def reload(self):
        doc = self.col.find_one({"_id": "global"}) or {}
        colors = (doc.get("colors") or {})
        vibration = bool(doc.get("vibration", False))
        quiet = doc.get("quietHours") if isinstance(doc.get("quietHours"), dict) else None
        with self.lock:
            self.colors = {str(k): str(v) for k, v in colors.items()}
            self.vibration = vibration
            self.quiet_hours = quiet
        try:
            print(f"[SETTINGS] colors={self.colors or '{defaults}'} vibration={self.vibration}")
        except Exception:
            pass

    def get_color_for_event(self, title: str) -> str:
        key = event_title_to_key(title)
        # Fallback defaults if not set in DB
        defaults = {
            "baby_crying": "blue",
            "door_knocking": "green",
            "phone_call": "red",
            "baby_movement": "yellow",
        }
        with self.lock:
            return self.colors.get(key, defaults.get(key, "white"))

    def get_vibrate_intensity(self) -> int:
        with self.lock:
            try:
                if self._is_within_quiet_hours_locked():
                    return 0
            except Exception:
                pass
            return 255 if self.vibration else 0

    def _is_within_quiet_hours_locked(self) -> bool:
        if not self.quiet_hours:
            return False
        try:
            start = (self.quiet_hours.get("start") or "").strip()
            end = (self.quiet_hours.get("end") or "").strip()
            if not start or not end or len(start) != 5 or len(end) != 5:
                return False
            now = datetime.now().time()
            sh, sm = int(start[:2]), int(start[3:])
            eh, em = int(end[:2]), int(end[3:])
            start_t = now.replace(hour=sh, minute=sm, second=0, microsecond=0)
            end_t = now.replace(hour=eh, minute=em, second=0, microsecond=0)
            if start_t <= end_t:
                return start_t <= now <= end_t
            else:
                return now >= start_t or now <= end_t
        except Exception:
            return False


def watch_settings_changes(settings: SettingsCache, stop_event: threading.Event):
    # Try change stream; fall back to polling
    try:
        with settings.col.watch([{"$match": {"documentKey._id": "global"}}]) as stream:
            for change in stream:
                if stop_event.is_set():
                    break
                settings.reload()
    except PyMongoError:
        while not stop_event.is_set():
            settings.reload()
            time.sleep(5)


def handle_event_doc(doc: dict, settings: SettingsCache, bracelet: BraceletSerial):
    title = doc.get("title", "")
    color = settings.get_color_for_event(title)
    vibrate = settings.get_vibrate_intensity()
    try:
        print(f"[EVENT] '{title}' -> color={color} vibrate={vibrate}")
    except Exception:
        pass
    bracelet.send_command(color=color, vibrate=vibrate)
    if vibrate > 0:
        def stop_vib():
            time.sleep(VIBRATION_MS / 1000.0)
            bracelet.send_command(vibrate=0)

        threading.Thread(target=stop_vib, daemon=True).start()


def watch_events(db, settings: SettingsCache, bracelet: BraceletSerial, stop_event: threading.Event):
    col = db[EVENTS_COLLECTION]
    try:
        with col.watch([{"$match": {"operationType": "insert"}}]) as stream:
            for change in stream:
                if stop_event.is_set():
                    break
                full = change.get("fullDocument", {})
                handle_event_doc(full, settings, bracelet)
    except PyMongoError:
        # Fallback: poll by createdAt increasing
        last_ts = datetime.now(timezone.utc)
        while not stop_event.is_set():
            try:
                for d in col.find({"createdAt": {"$gt": last_ts}}).sort("createdAt", 1):
                    last_ts = d.get("createdAt", last_ts)
                    handle_event_doc(d, settings, bracelet)
            except Exception:
                pass
            time.sleep(1.0)


def post_door_knocking_event():
    try:
        now_iso = datetime.now(timezone.utc).isoformat()
        payload = {
            "title": "door knocking",
            "isImportant": False,
            "eventAt": now_iso,
        }
        requests.post(f"{API_BASE}/events/", json=payload, timeout=3)
    except Exception:
        pass


def listen_button(bracelet: BraceletSerial, stop_event: threading.Event):
    for line in bracelet.iter_lines():
        if stop_event.is_set():
            break
        if not line:
            continue
        if line.startswith("BTN:DOWN"):
            post_door_knocking_event()


def main():
    mongo = MongoClient(MONGO_URI)
    db = mongo[MONGO_DB]

    bracelet = BraceletSerial(SERIAL_PORT, SERIAL_BAUD)
    bracelet.connect()

    settings = SettingsCache(db)

    stop_event = threading.Event()

    threads = [
        threading.Thread(target=watch_settings_changes, args=(settings, stop_event), daemon=True),
        threading.Thread(target=watch_events, args=(db, settings, bracelet, stop_event), daemon=True),
        threading.Thread(target=listen_button, args=(bracelet, stop_event), daemon=True),
    ]
    for t in threads:
        t.start()

    print("Bracelet bridge running. Press Ctrl+C to stop.")
    try:
        while True:
            time.sleep(0.5)
    except KeyboardInterrupt:
        pass
    finally:
        stop_event.set()
        bracelet.close()


if __name__ == "__main__":
    main()


