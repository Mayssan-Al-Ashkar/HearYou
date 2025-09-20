from datetime import datetime, timezone

from flask import Blueprint, current_app, jsonify, request
from bson import ObjectId
import os
import requests
import json


events_bp = Blueprint("events_bp", __name__)


def _format_date_time(dt: datetime) -> tuple[str, str]:
    # Match Flutter UI expectations: MM/dd/yyyy and HH:mm
    return dt.strftime("%m/%d/%Y"), dt.strftime("%H:%M")


def _serialize_event(doc: dict) -> dict:
    event_at: datetime = doc.get("eventAt") or doc.get("createdAt") or datetime.now(timezone.utc)
    if isinstance(event_at, str):
        try:
            event_at = datetime.fromisoformat(event_at)
        except Exception:
            event_at = datetime.now(timezone.utc)
    # Ensure timezone-aware (Mongo returns naive datetimes by default)
    try:
        if event_at.tzinfo is None or event_at.tzinfo.utcoffset(event_at) is None:
            event_at = event_at.replace(tzinfo=timezone.utc)
    except Exception:
        event_at = datetime.now(timezone.utc)
    date_str, time_str = _format_date_time(event_at.astimezone())
    return {
        "id": str(doc.get("_id")),
        "title": doc.get("title", ""),
        # Do not expose description going forward; keep empty for UI compatibility
        "description": "",
        "date": date_str,
        "time": time_str,
        "eventAt": event_at.isoformat(),
        "isImportant": bool(doc.get("isImportant", False)),
    }


def _normalize_event_key(title: str) -> str:
    t = (title or "").strip().lower()
    mapping = {
        "baby crying": "baby_crying",
        "baby movement": "baby_movement",
        "door knocking": "door_knocking",
        "phone call": "phone_call",
    }
    if t in mapping:
        return mapping[t]
    return t.replace(" ", "_")


def _is_within_quiet_hours(quiet: dict | None) -> bool:
    if not isinstance(quiet, dict):
        return False
    start = (quiet.get("start") or "").strip()
    end = (quiet.get("end") or "").strip()
    try:
        now = datetime.now().time()
        if not start or not end or len(start) != 5 or len(end) != 5:
            return False
        sh, sm = int(start[:2]), int(start[3:])
        eh, em = int(end[:2]), int(end[3:])
        start_t = now.replace(hour=sh, minute=sm, second=0, microsecond=0)
        end_t = now.replace(hour=eh, minute=em, second=0, microsecond=0)
        # If window crosses midnight
        if start_t <= end_t:
            return start_t <= now <= end_t
        else:
            return now >= start_t or now <= end_t
    except Exception:
        return False

@events_bp.route("/", methods=["GET"])  # GET /events/
def list_events():
    """List events
    ---
    tags: [Events]
    responses:
      200:
        description: List of events
    """
    db = current_app.config.get("DB")
    coll = db["events"]
    # Optional user scoping: /events/?uid=<firebase_uid>
    uid = (request.args.get("uid") or "").strip()
    q = {"uid": uid} if uid else {}
    items = list(coll.find(q).sort("eventAt", -1))
    return jsonify({"ok": True, "events": [_serialize_event(x) for x in items]})


@events_bp.route("/", methods=["POST"])  # POST /events/
def create_event():
    """Create an event
    ---
    tags: [Events]
    consumes:
      - application/json
    parameters:
      - in: body
        name: body
        schema:
          type: object
          required: [title]
          properties:
            title: {type: string}
            description: {type: string}
            isImportant: {type: boolean}
            eventAt: {type: string, format: date-time}
            source: {type: string}
    responses:
      201:
        description: Created
    """
    db = current_app.config.get("DB")
    coll = db["events"]
    data = request.get_json(force=True, silent=True) or {}
    title = (data.get("title") or "").strip()
    uid = (data.get("uid") or "").strip()  # firebase uid or app user id (string)
    # Ignore description/source in new events
    description = ""
    is_important = bool(data.get("isImportant", False))
    event_at_iso = data.get("eventAt")

    if not title:
        return jsonify({"ok": False, "message": "Missing title"}), 400

    try:
        event_at = datetime.fromisoformat(event_at_iso) if event_at_iso else datetime.now(timezone.utc)
    except Exception:
        event_at = datetime.now(timezone.utc)

    # Auto-prioritize if not explicitly set and a priority exists in settings
    try:
        settings_coll = db["settings"]
        settings_doc = settings_coll.find_one({"_id": "global"}) or {}
        if not data.get("isImportant"):
            key = _normalize_event_key(title)
            priorities = settings_doc.get("priorities") or {}
            if isinstance(priorities, dict):
                is_important = bool(priorities.get(key, False))
    except Exception:
        pass

    doc = {
        "title": title,
        # intentionally omitting description
        "isImportant": is_important,
        "eventAt": event_at,
        "createdAt": datetime.now(timezone.utc),
        # intentionally omitting source
        **({"uid": uid} if uid else {}),
    }
    inserted = coll.insert_one(doc)
    created = coll.find_one({"_id": inserted.inserted_id})

    # Send FCM push notification if configured (skip during quiet hours)
    try:
        server_key = os.getenv("FCM_SERVER_KEY")
        if server_key:
            db = current_app.config.get("DB")
            users_coll = db["users"]
            settings_doc = (db["settings"].find_one({"_id": "global"}) or {})
            if _is_within_quiet_hours(settings_doc.get("quietHours")):
                raise Exception("Within quiet hours; skipping FCM")
            # Collect tokens: if uid provided, target that user only; else fall back to all
            tokens = set()
            if uid:
                # Try both string _id and ObjectId
                for query in ([{"_id": uid}], [{"_id": ObjectId(uid)}] if len(uid) == 24 else []):
                    try:
                        user_doc = users_coll.find_one(*query)
                        if user_doc:
                            for t in user_doc.get("fcmTokens", []) or []:
                                if isinstance(t, str) and len(t) > 20:
                                    tokens.add(t)
                            break
                    except Exception:
                        pass
            if not tokens:
                for user in users_coll.find({}, {"fcmTokens": 1}):
                    for t in user.get("fcmTokens", []) or []:
                        if isinstance(t, str) and len(t) > 20:
                            tokens.add(t)

            if tokens:
                headers = {
                    "Authorization": f"key={server_key}",
                    "Content-Type": "application/json",
                }
                payload = {
                    "registration_ids": list(tokens),
                    "notification": {
                        "title": doc.get("title", "Event"),
                        "body": doc.get("description", "New event"),
                    },
                    "data": {
                        "eventId": str(inserted.inserted_id),
                        "source": doc.get("source", "ml"),
                        "eventAt": doc.get("eventAt").isoformat() if doc.get("eventAt") else "",
                        "uid": uid,
                    },
                    "android": {"priority": "high"},
                    "apns": {"headers": {"apns-priority": "10"}},
                }
                requests.post("https://fcm.googleapis.com/fcm/send", json=payload, headers=headers, timeout=5)
    except Exception:
        pass

    # Update Firebase Realtime Database Notifications/message if configured
    try:
        rtdb_url = os.getenv("FIREBASE_RTDB_URL")  # e.g., https://hearyou-XXXX-default-rtdb.firebaseio.com
        if rtdb_url:
            message_value = doc.get("title", "Event")
            # Write to /Notifications/message
            requests.patch(
                f"{rtdb_url}/Notifications.json",
                data=json.dumps({"message": message_value}),
                timeout=5,
            )
    except Exception:
        pass
    return jsonify({"ok": True, "event": _serialize_event(created)}), 201


@events_bp.route("/<event_id>", methods=["PATCH"])  # PATCH /events/<id>
def update_event(event_id: str):
    """Update an event
    ---
    tags: [Events]
    consumes:
      - application/json
    parameters:
      - in: path
        name: event_id
        required: true
        type: string
      - in: body
        name: body
        schema:
          type: object
          properties:
            title: {type: string}
            description: {type: string}
            isImportant: {type: boolean}
    responses:
      200: {description: Updated}
      400: {description: Invalid id or payload}
      404: {description: Not found}
    """
    db = current_app.config.get("DB")
    coll = db["events"]
    try:
        oid = ObjectId(event_id)
    except Exception:
        return jsonify({"ok": False, "message": "Invalid id"}), 400

    data = request.get_json(force=True, silent=True) or {}
    update = {}
    if "isImportant" in data:
        update["isImportant"] = bool(data.get("isImportant"))
    if "title" in data:
        update["title"] = (data.get("title") or "").strip()
    if "description" in data:
        update["description"] = (data.get("description") or "").strip()

    if not update:
        return jsonify({"ok": False, "message": "Nothing to update"}), 400

    coll.update_one({"_id": oid}, {"$set": update})
    after = coll.find_one({"_id": oid})
    if not after:
        return jsonify({"ok": False, "message": "Not found"}), 404
    return jsonify({"ok": True, "event": _serialize_event(after)})


