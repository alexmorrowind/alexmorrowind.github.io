#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$ROOT_DIR/fintech_new/my_payment_project"
FRONTEND_DIR="$ROOT_DIR/fintech_new/front"

cleanup() {
  kill "$BACKEND_PID" "$FRONTEND_PID" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

echo "Starting Django backend: http://127.0.0.1:8000"
(cd "$BACKEND_DIR" && python3 manage.py runserver 127.0.0.1:8000) &
BACKEND_PID=$!

echo "Starting frontend: http://127.0.0.1:8765/index.html"
(cd "$FRONTEND_DIR" && python3 -m http.server 8765) &
FRONTEND_PID=$!

echo ""
echo "Open: http://127.0.0.1:8765/index.html"
echo "Stop both servers with Ctrl+C"

wait "$BACKEND_PID" "$FRONTEND_PID"
