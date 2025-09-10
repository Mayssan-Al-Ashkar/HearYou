from datetime import datetime, timezone

from flask import Blueprint, current_app, jsonify, request
from bson import ObjectId


weekly_reports_bp = Blueprint("weekly_reports_bp", __name__)


def _serialize_report(doc: dict) -> dict:
    # Align with provided schema: summary, recommendations[], generatedAt, weekStartIso, weekEndIso
    created_at = (
        doc.get("generatedAt")
        or doc.get("createdAt")
        or datetime.now(timezone.utc)
    )
    if isinstance(created_at, str):
        try:
            created_at = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
        except Exception:
            created_at = datetime.now(timezone.utc)
    recs = doc.get("recommendations") or []
    # Ensure recommendations are simple dicts with title/detail/order
    norm_recs = []
    for r in recs:
        try:
            norm_recs.append({
                "title": (r.get("title") or "").strip(),
                "detail": (r.get("detail") or "").strip(),
                "order": int(r.get("order") or 0),
            })
        except Exception:
            pass
    norm_recs.sort(key=lambda x: x.get("order", 0))

    return {
        "id": str(doc.get("_id")),
        "userId": str(doc.get("userId", "")),
        "email": doc.get("email", ""),
        "summary": doc.get("summary", ""),
        "recommendations": norm_recs,
        "generatedAt": created_at.isoformat(),
        "weekStartIso": doc.get("weekStartIso", ""),
        "weekEndIso": doc.get("weekEndIso", ""),
        "source": doc.get("source", ""),
    }


@weekly_reports_bp.route("/", methods=["GET"])  # GET /weekly_reports/
def list_weekly_reports():
    """List weekly reports
    ---
    tags: [Weekly Reports]
    parameters:
      - in: query
        name: userId
        type: string
      - in: query
        name: email
        type: string
    responses:
      200: {description: List returned}
    """
    db = current_app.config.get("DB")
    coll = db["weekly_reports"]
    user_id = request.args.get("userId", "").strip()
    email = request.args.get("email", "").strip().lower()

    query = {}
    ors = []
    if user_id:
        ors.append({"userId": user_id})
        ors.append({"uid": user_id})
        ors.append({"user_id": user_id})
        # Try ObjectId variants
        try:
            oid = ObjectId(user_id)
            ors.append({"userId": oid})
            ors.append({"uid": oid})
            ors.append({"user_id": oid})
        except Exception:
            pass
    if email:
        ors.append({"email": email})

    if ors:
        query = {"$or": ors}

    items = list(coll.find(query).sort("createdAt", -1))
    if not items:
        # Fallback: return latest reports regardless of user linkage
        items = list(coll.find({}).sort("createdAt", -1).limit(20))
    return jsonify({"ok": True, "reports": [_serialize_report(x) for x in items]})


