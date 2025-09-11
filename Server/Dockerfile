# syntax=docker/dockerfile:1
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# System deps (if needed later add libsndfile1 for audio, but keep CI light)
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy only API-related server files (exclude heavy ML scripts/media)
COPY api_server.py events.py settings.py weekly_reports.py ./

EXPOSE 5000

# Default command uses gunicorn to serve the Flask app factory
CMD ["gunicorn", "api_server:create_app()", "-b", "0.0.0.0:5000", "-w", "2", "--threads", "4"]
