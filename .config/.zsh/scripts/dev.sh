#!/usr/bin/env bash
set -e

# a script to run a project with a single command depending on what project it is (nodejs, python, rust, etc.)

# Helper: Check if command exists in package.json scripts
function npm_has_script() {
  local script_name="$1"
  jq -e --arg name "$script_name" '.scripts[$name]?' package.json >/dev/null 2>&1
}

# Node.js (package.json)
if [ -f package.json ]; then
  if ! command -v jq >/dev/null; then
    echo "Error: jq is required to parse package.json" >&2
    exit 1
  fi

  if npm_has_script "start:dev"; then
    echo "Running: npm run start:dev"
    npm run start:dev
    exit 0
  elif npm_has_script "dev"; then
    echo "Running: npm run dev"
    npm run dev
    exit 0
  elif npm_has_script "start"; then
    echo "Running: npm run start"
    npm run start
    exit 0
  else
    echo "Error: No start script found in package.json"
    exit 1
  fi
fi

# Poetry (pyproject.toml)
if [ -f pyproject.toml ]; then
  if grep -q '\[tool.poetry.scripts\]' pyproject.toml && grep -q '^start\s*=' pyproject.toml; then
    echo "Running: poetry run start"
    poetry run start
    exit 0
  else
    echo "Error: No [tool.poetry.scripts] start entry found in pyproject.toml"
    exit 1
  fi
fi

# Rust (Cargo.toml)
if [ -f Cargo.toml ]; then
  echo "Running: cargo run"
  cargo run
  exit 0
fi

# Go (go.mod or main.go)
if [ -f go.mod ]; then
  echo "Running: go run ."
  go run .
  exit 0
elif [ -f main.go ]; then
  echo "Running: go run main.go"
  go run main.go
  exit 0
fi

# If nothing matched
echo "Error: No recognized project type or start command found"
exit 1
