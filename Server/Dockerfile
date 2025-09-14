# syntax=docker/dockerfile:1
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy only API files (keeps image small)
COPY api_server.py events.py settings.py weekly_reports.py agent.py ./

EXPOSE 5000
CMD ["gunicorn", "api_server:create_app()", "-b", "0.0.0.0:5000", "-w", "2", "--threads", "4"]