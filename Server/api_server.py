import os
import time
from datetime import datetime

from flask import Flask, jsonify, request
from flask_cors import CORS
from pymongo import MongoClient
from bson import ObjectId
from events import events_bp
from settings import settings_bp
from weekly_reports import weekly_reports_bp
from agent import agent_bp
from flasgger import Swagger


def create_app():
    app = Flask(__name__)
    CORS(app)

    app.config["SWAGGER"] = {
        "title": "HearYou API",
        "uiversion": 3,
    }
    Swagger(app)

    app.config["MONGODB_URI"] = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
    app.config["DB_NAME"] = os.getenv("DB_NAME", "hearyou")

    mongo_client = MongoClient(app.config["MONGODB_URI"])
    db = mongo_client[app.config["DB_NAME"]]
    users = db["users"]
    app.config["DB"] = db

    @app.route("/health", methods=["GET"])
    def health():
        """Service healthcheck
        ---
        tags: [System]
        responses:
          200:
            description: OK
        """
        return jsonify({"ok": True, "service": "auth", "ts": int(time.time())})

    @app.route("/db/health", methods=["GET"])
    def db_health():
        """MongoDB connection health
        ---
        tags: [System]
        responses:
          200:
            description: Healthy
          500:
            description: DB not reachable
        """
        try:
            mongo_client.admin.command("ping")
            return jsonify({"ok": True, "message": "MongoDB connection is healthy"})
        except Exception as exc:
            return jsonify({"ok": False, "message": str(exc)}), 500

    @app.route("/auth/register-fcm", methods=["POST"])
    def register_fcm():
        """Register an FCM token for a user
        ---
        tags: [Auth]
        consumes:
          - application/json
        parameters:
          - in: body
            name: body
            schema:
              type: object
              required: [uid, token]
              properties:
                uid: {type: string}
                token: {type: string}
        responses:
          200: {description: Registered}
          400: {description: Missing fields}
          500: {description: DB error}
        """
        data = request.get_json(force=True, silent=True) or {}
        uid = (data.get("uid") or "").strip()
        token = (data.get("token") or "").strip()
        if not uid or not token:
            return jsonify({"ok": False, "message": "Missing uid or token"}), 400

        try:
            users.update_one(
                {"_id": ObjectId(uid)},
                {"$addToSet": {"fcmTokens": token}},
            )
            return jsonify({"ok": True})
        except Exception as exc:
            return jsonify({"ok": False, "message": str(exc)}), 500

    app.register_blueprint(events_bp, url_prefix="/events")
    app.register_blueprint(settings_bp, url_prefix="/settings")
    app.register_blueprint(weekly_reports_bp, url_prefix="/weekly_reports")
    app.register_blueprint(agent_bp, url_prefix="/agent")

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))


