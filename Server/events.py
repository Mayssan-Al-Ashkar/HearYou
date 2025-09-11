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
    date_str, time_str = _format_date_time(event_at.astimezone())
    return {
        "id": str(doc.get("_id")),
        "title": doc.get("title", ""),
        "description": doc.get("description", ""),
        "date": date_str,
        "time": time_str,
        "eventAt": event_at.isoformat(),
        "isImportant": bool(doc.get("isImportant", False)),
    }


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
    items = list(coll.find({}).sort("eventAt", -1))
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
    description = (data.get("description") or "").strip()
    is_important = bool(data.get("isImportant", False))
    event_at_iso = data.get("eventAt")

    if not title:
        return jsonify({"ok": False, "message": "Missing title"}), 400

    try:
        event_at = datetime.fromisoformat(event_at_iso) if event_at_iso else datetime.now(timezone.utc)
    except Exception:
        event_at = datetime.now(timezone.utc)

    doc = {
        "title": title,
        "description": description,
        "isImportant": is_important,
        "eventAt": event_at,
        "createdAt": datetime.now(timezone.utc),
        "source": data.get("source", "ml"),
    }
    inserted = coll.insert_one(doc)
    created = coll.find_one({"_id": inserted.inserted_id})

    # Send FCM push notification if configured
    try:
        server_key = os.getenv("FCM_SERVER_KEY")
        if server_key:
            db = current_app.config.get("DB")
            users_coll = db["users"]
            # Collect unique tokens
            tokens = set()
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


