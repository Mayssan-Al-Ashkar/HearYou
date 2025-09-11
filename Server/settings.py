from flask import Blueprint, current_app, jsonify, request


settings_bp = Blueprint("settings_bp", __name__)


DEFAULT_COLORS = {
    "baby_crying": "blue",
    "door_knocking": "green",
    "phone_call": "red",
    "baby_movement": "yellow",
}


@settings_bp.route("/", methods=["GET"])  # GET /settings/
def get_settings():
    """Get global settings
    ---
    tags: [Settings]
    responses:
      200: {description: Settings returned}
    """
    db = current_app.config.get("DB")
    doc = db["settings"].find_one({"_id": "global"}) or {}
    return jsonify({
        "ok": True,
        "settings": {
            "colors": doc.get("colors", DEFAULT_COLORS),
            "vibration": bool(doc.get("vibration", False)),
        },
    })


@settings_bp.route("/", methods=["POST"])  # POST /settings/
def save_settings():
    """Save global settings
    ---
    tags: [Settings]
    consumes:
      - application/json
    parameters:
      - in: body
        name: body
        schema:
          type: object
          properties:
            colors: {type: object}
            vibration: {type: boolean}
    responses:
      200: {description: Saved}
      400: {description: Invalid payload}
    """
    db = current_app.config.get("DB")
    data = request.get_json(force=True, silent=True) or {}
    colors = data.get("colors") or {}
    vibration = bool(data.get("vibration", False))

    if not isinstance(colors, dict):
        return jsonify({"ok": False, "message": "colors must be an object"}), 400

    db["settings"].update_one(
        {"_id": "global"},
        {"$set": {"colors": colors, "vibration": vibration}},
        upsert=True,
    )
    return jsonify({"ok": True})


