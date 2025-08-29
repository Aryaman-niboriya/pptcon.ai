#!/usr/bin/env bash
set -euo pipefail

# Render build script: build frontend and install backend deps
# Working directory is repository root on Render, but service root is backend/
# We will assume this script is called from backend/ via: bash render-build.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 1) Build frontend (Vite) and copy to backend/static
if command -v node >/dev/null 2>&1; then
  echo "Node already installed: $(node -v)"
else
  echo "Node not found; please ensure Node 18+ is available in the Render environment"
fi

pushd "$REPO_ROOT/frontend" >/dev/null
  echo "Installing frontend deps..."
  npm ci || npm install
  echo "Building frontend (client only)..."
  if npm run build:client; then
    echo "Client build succeeded."
  else
    echo "Client build failed." >&2
    exit 1
  fi
popd >/dev/null

# Ensure backend/static exists and copy build output
mkdir -p "$SCRIPT_DIR/static"
# Clean previous assets (keep directory)
find "$SCRIPT_DIR/static" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
if [ -d "$REPO_ROOT/frontend/dist/spa" ]; then
  cp -r "$REPO_ROOT/frontend/dist/spa"/* "$SCRIPT_DIR/static"/
else
  cp -r "$REPO_ROOT/frontend/dist"/* "$SCRIPT_DIR/static"/
fi

# 2) Install backend Python dependencies (robust pip detection)
if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN=python3
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN=python
else
  echo "Python not found. Please install Python 3." >&2
  exit 1
fi

if "$PYTHON_BIN" -m pip --version >/dev/null 2>&1; then
  "$PYTHON_BIN" -m pip install -r "$SCRIPT_DIR/requirements.txt"
elif command -v pip3 >/dev/null 2>&1; then
  pip3 install -r "$SCRIPT_DIR/requirements.txt"
elif command -v pip >/dev/null 2>&1; then
  pip install -r "$SCRIPT_DIR/requirements.txt"
else
  echo "pip not found. Please ensure pip is installed." >&2
  exit 1
fi

echo "Build completed: frontend assets copied to backend/static and Python deps installed."
