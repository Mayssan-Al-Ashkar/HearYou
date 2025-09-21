import os
import json
from datetime import datetime
from flask import Blueprint, request, jsonify, current_app
import requests


agent_bp = Blueprint("agent_bp", __name__)


SYSTEM_SCHEMA = {
    "intents": [
        {
            "name": "SetColor",
            "params": {"eventKey": "string", "color": "string"}
        },
        {"name": "SetVibration", "params": {"enabled": "boolean"}},
        {"name": "SetQuietHours", "params": {"start": "HH:MM", "end": "HH:MM"}},
        {"name": "SetPriority", "params": {"eventKey": "string", "important": "boolean"}},
    ],
    "eventKeys": ["baby_crying", "baby_movement", "door_knocking", "phone_call"],
    "colors": ["red", "green", "blue", "yellow", "white", "purple", "cyan", "orange"],
}


def normalize_event_key(text: str) -> str:
    t = (text or "").strip().lower()
    mapping = {
        "baby crying": "baby_crying",
        "baby movement": "baby_movement",
        "door knocking": "door_knocking",
        "phone call": "phone_call",
    }
    if t in mapping:
        return mapping[t]
    return t.replace(" ", "_")


def build_prompt(user_text: str) -> str:
    return (
        "You are an intent parser for HearYou. "
        "Extract exactly one intent from the user's text and output ONLY a JSON object with keys 'intent' and 'params'. Output must be valid minified JSON with no code fences or commentary.\n"
        f"Supported intents and schema: {json.dumps(SYSTEM_SCHEMA)}\n"
        "Rules: \n"
        "- If color mentioned, map to a simple color word.\n"
        "- Normalize event names to keys (e.g., 'door knocking' -> 'door_knocking').\n"
        "- Times must be 24h 'HH:MM'.\n"
        "- If ambiguous, choose the safest, most conservative interpretation.\n"
        "User text: " + user_text
    )


def call_gemini(prompt: str) -> str:
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise RuntimeError("Missing GOOGLE_API_KEY")
    url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    headers = {"Content-Type": "application/json", "x-goog-api-key": api_key}
    payload = {
        "generationConfig": {
            "response_mime_type": "application/json"
        },
        "contents": [
            {
                "role": "user",
                "parts": [{"text": prompt}]
            }
        ]
    }
    resp = requests.post(url, headers=headers, json=payload, timeout=30)
    resp.raise_for_status()
    data = resp.json()
    try:
        text = data["candidates"][0]["content"]["parts"][0]["text"]
    except Exception:
        text = "{}"
    return text or "{}"


def _parse_json_lenient(raw_text: str) -> dict:
    if not isinstance(raw_text, str):
        return {}
    text = (raw_text or "").strip()
    if text.startswith("```"):
        first_newline = text.find("\n")
        if first_newline != -1:
            text = text[first_newline + 1 :]
        if text.endswith("````"):
            text = text[:-4]
        elif text.endswith("```"):
            text = text[:-3]
        text = text.strip()
    try:
        return json.loads(text)
    except Exception:
        pass
    try:
        start = text.index("{")
        end = text.rindex("}")
        candidate = text[start : end + 1]
        return json.loads(candidate)
    except Exception:
        return {}


def apply_intent(db, intent: str, params: dict) -> str:
    coll = db["settings"]
    doc = coll.find_one({"_id": "global"}) or {"_id": "global"}
    update = {}
    intent = (intent or "").strip()

    if intent == "SetVibration":
        enabled = bool(params.get("enabled"))
        update = {"$set": {"vibration": enabled}}
        msg = f"Vibration {'enabled' if enabled else 'disabled'}."
    elif intent == "SetColor":
        event_key = normalize_event_key(params.get("eventKey", ""))
        color = (params.get("color") or "").strip().lower()
        if not event_key:
            return "Please specify which event (e.g., door knocking, baby crying)."
        if color not in SYSTEM_SCHEMA["colors"]:
            return "Please choose a basic color like red, green, blue, or white."
        update = {"$set": {f"colors.{event_key}": color}}
        msg = f"Set {event_key.replace('_',' ')} color to {color}."
    elif intent == "SetQuietHours":
        start = (params.get("start") or "").strip()
        end = (params.get("end") or "").strip()
        if not start or not end:
            return "Please provide quiet hours like '21:00' to '07:00'."
        update = {"$set": {"quietHours": {"start": start, "end": end}}}
        msg = f"Quiet hours set from {start} to {end}."
    elif intent == "SetPriority":
        event_key = normalize_event_key(params.get("eventKey", ""))
        important = bool(params.get("important", True))
        if not event_key:
            return "Please specify which event to prioritize."
        update = {"$set": {f"priorities.{event_key}": important}}
        msg = f"Priority for {event_key.replace('_',' ')} set to {important}."
    else:
        return "Sorry, I couldn't understand that change. Try: 'turn off vibration' or 'set door knocking color to blue'."

    if update:
        coll.update_one({"_id": "global"}, update, upsert=True)
    return msg


@agent_bp.route("/command", methods=["POST"])
def command():
    db = current_app.config["DB"]
    data = request.get_json(force=True, silent=True) or {}
    text = (data.get("question") or data.get("command") or "").strip()
    if not text:
        return jsonify({"ok": False, "message": "Missing question/command"}), 400

    try:
        prompt = build_prompt(text)
        raw = call_gemini(prompt)
        parsed = _parse_json_lenient(raw)
        if not isinstance(parsed, dict) or not parsed:
            raise ValueError("Model did not return valid JSON")
    except Exception as exc:
        return jsonify({"ok": False, "message": f"Parsing error: {exc}"}), 400

    intent = parsed.get("intent")
    params = parsed.get("params") or {}
    reply = apply_intent(db, intent, params)
    return jsonify({"ok": True, "answer": reply, "intent": intent, "params": params})


