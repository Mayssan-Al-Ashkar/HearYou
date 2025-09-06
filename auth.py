import os
import time
from datetime import datetime, timedelta

from flask import Flask, jsonify, request
from flask_cors import CORS
from pymongo import MongoClient
import bcrypt
import jwt
from bson import ObjectId
from events import events_bp
from settings import settings_bp


def create_app():
    app = Flask(__name__)
    CORS(app)

    app.config["JWT_SECRET"] = os.getenv("JWT_SECRET", "dev-secret-change-me")
    app.config["MONGODB_URI"] = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
    app.config["DB_NAME"] = os.getenv("DB_NAME", "hearyou")

    mongo_client = MongoClient(app.config["MONGODB_URI"])  # noqa: S106 (local, dev only)
    db = mongo_client[app.config["DB_NAME"]]
    users = db["users"]
    # expose db to blueprints
    app.config["DB"] = db

    def generate_jwt(payload: dict, expires_minutes: int = 60 * 24) -> str:
        to_encode = payload.copy()
        to_encode["exp"] = datetime.utcnow() + timedelta(minutes=expires_minutes)
        return jwt.encode(to_encode, app.config["JWT_SECRET"], algorithm="HS256")

    def verify_password(plain_password: str, hashed_password: bytes) -> bool:
        try:
            return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password)
        except Exception:
            return False

    def hash_password(plain_password: str) -> bytes:
        return bcrypt.hashpw(plain_password.encode("utf-8"), bcrypt.gensalt())

    @app.route("/health", methods=["GET"])
    def health():
        return jsonify({"ok": True, "service": "auth", "ts": int(time.time())})

    @app.route("/db/health", methods=["GET"])
    def db_health():
        try:
            # Ping the deployment to confirm a successful connection
            mongo_client.admin.command("ping")
            return jsonify({"ok": True, "message": "MongoDB connection is healthy"})
        except Exception as exc:
            return jsonify({"ok": False, "message": str(exc)}), 500

    @app.route("/auth/signup", methods=["POST"])
    def signup():
        data = request.get_json(force=True, silent=True) or {}
        name = (data.get("name") or "").strip()
        email = (data.get("email") or "").strip().lower()
        password = data.get("password") or ""

        if not name or not email or not password:
            return jsonify({"ok": False, "message": "Missing fields"}), 400

        existing = users.find_one({"email": email})
        if existing:
            return jsonify({"ok": False, "message": "Email already in use"}), 409

        user_doc = {
            "name": name,
            "email": email,
            "password": hash_password(password),
            "photoURL": data.get("photoURL", ""),
            "emailVerified": False,
            "createdAt": datetime.utcnow(),
            "lastLogin": None,
        }
        inserted = users.insert_one(user_doc)

        # Create a verification token and log a link for development.
        verify_token = generate_jwt({"sub": str(inserted.inserted_id), "t": "email_verify"}, 60 * 24)
        verify_url = f"/auth/verify-email?token={verify_token}"
        print("[auth] Email verification link (dev):", verify_url)

        return jsonify({"ok": True, "message": "User created. Check email for verification link."})

    @app.route("/auth/login", methods=["POST"])
    def login():
        data = request.get_json(force=True, silent=True) or {}
        email = (data.get("email") or "").strip().lower()
        password = data.get("password") or ""

        user = users.find_one({"email": email})
        if not user or not verify_password(password, user.get("password", b"")):
            return jsonify({"ok": False, "message": "Invalid credentials"}), 401

        if not user.get("emailVerified", False):
            return jsonify({"ok": False, "message": "Email not verified", "emailVerified": False}), 403

        users.update_one({"_id": user["_id"]}, {"$set": {"lastLogin": datetime.utcnow()}})

        token = generate_jwt({"sub": str(user["_id"]), "email": user["email"], "t": "access"})
        profile = {
            "id": str(user["_id"]),
            "email": user["email"],
            "name": user.get("name"),
            "photoURL": user.get("photoURL", ""),
            "emailVerified": True,
        }
        return jsonify({"ok": True, "token": token, "user": profile})

    @app.route("/auth/password-reset", methods=["POST"])
    def password_reset():
        data = request.get_json(force=True, silent=True) or {}
        email = (data.get("email") or "").strip().lower()
        user = users.find_one({"email": email})
        if not user:
            # Return 200 to avoid email enumeration
            return jsonify({"ok": True, "message": "If the email exists, a reset link was sent."})

        reset_token = generate_jwt({"sub": str(user["_id"]), "t": "password_reset"}, 60)
        reset_url = f"/auth/reset-password?token={reset_token}"
        print("[auth] Password reset link (dev):", reset_url)

        return jsonify({"ok": True, "message": "Password reset link sent."})

    @app.route("/auth/reset-password", methods=["POST"])
    def reset_password():
        data = request.get_json(force=True, silent=True) or {}
        token = data.get("token")
        new_password = data.get("password") or ""
        if not token or not new_password:
            return jsonify({"ok": False, "message": "Missing token or password"}), 400

        try:
            decoded = jwt.decode(token, app.config["JWT_SECRET"], algorithms=["HS256"])  # noqa: S105
        except jwt.ExpiredSignatureError:
            return jsonify({"ok": False, "message": "Token expired"}), 400
        except Exception:
            return jsonify({"ok": False, "message": "Invalid token"}), 400

        if decoded.get("t") != "password_reset":
            return jsonify({"ok": False, "message": "Invalid token type"}), 400

        user_id = decoded.get("sub")
        try:
            users.update_one({"_id": ObjectId(user_id)}, {"$set": {"password": hash_password(new_password)}})
        except Exception:
            return jsonify({"ok": False, "message": "Failed to update password"}), 500

        return jsonify({"ok": True, "message": "Password updated"})

    @app.route("/auth/verify-email", methods=["GET"])  # Simple dev endpoint
    def verify_email():
        token = request.args.get("token")
        if not token:
            return "Missing token", 400
        try:
            decoded = jwt.decode(token, app.config["JWT_SECRET"], algorithms=["HS256"])  # noqa: S105
        except jwt.ExpiredSignatureError:
            return "Token expired", 400
        except Exception:
            return "Invalid token", 400

        if decoded.get("t") != "email_verify":
            return "Invalid token type", 400

        from bson import ObjectId
        try:
            users.update_one({"_id": ObjectId(decoded["sub"])}, {"$set": {"emailVerified": True}})
        except Exception:
            return "Failed to verify email", 500

        return "Email verified. You can close this page and login in the app.", 200

    @app.route("/auth/google", methods=["POST"])
    def google_login():
        # For prototype: trust the payload the mobile app sends (idToken optional).
        # In production, verify idToken with Google.
        data = request.get_json(force=True, silent=True) or {}
        email = (data.get("email") or "").strip().lower()
        name = (data.get("name") or "").strip() or email.split("@")[0]
        photo_url = data.get("photoURL", "")
        if not email:
            return jsonify({"ok": False, "message": "Missing email"}), 400

        user = users.find_one({"email": email})
        if not user:
            users.insert_one({
                "name": name,
                "email": email,
                "password": None,
                "photoURL": photo_url,
                "emailVerified": True,
                "createdAt": datetime.utcnow(),
                "lastLogin": datetime.utcnow(),
                "provider": "google",
            })
            user = users.find_one({"email": email})
        else:
            users.update_one({"_id": user["_id"]}, {"$set": {"lastLogin": datetime.utcnow(), "photoURL": photo_url}})

        token = generate_jwt({"sub": str(user["_id"]), "email": user["email"], "t": "access"})
        profile = {
            "id": str(user["_id"]),
            "email": user["email"],
            "name": user.get("name"),
            "photoURL": user.get("photoURL", ""),
            "emailVerified": True,
        }
        return jsonify({"ok": True, "token": token, "user": profile})

    @app.route("/auth/register-fcm", methods=["POST"])
    def register_fcm():
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

    # Register blueprints
    app.register_blueprint(events_bp, url_prefix="/events")
    app.register_blueprint(settings_bp, url_prefix="/settings")

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))


