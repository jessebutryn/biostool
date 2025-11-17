#!/usr/bin/env bash
set -euo pipefail

# Simple build helper for the bios-tool Docker image.
# Usage:
#   ./build.sh                # build bios-tool:dev
#   ./build.sh --tag mytag    # build with custom tag
#   ./build.sh --no-cache     # pass --no-cache to docker build
#   ./build.sh --compose      # use docker-compose build instead

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAG="bios-tool:dev"
NO_CACHE=0
COMPOSE=0

print_help(){
  cat <<EOF
Usage: $(basename "$0") [--tag TAG] [--no-cache] [--compose] [--help]

Options:
  --tag TAG      Set image tag (default: bios-tool:dev)
  --no-cache     Do not use Docker build cache
  --compose      Run 'docker-compose build' instead of 'docker build'
  -h, --help     Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)
      TAG="$2"; shift 2;;
    --no-cache)
      NO_CACHE=1; shift;;
    --compose)
      COMPOSE=1; shift;;
    -h|--help)
      print_help; exit 0;;
    *)
      echo "Unknown option: $1" >&2; print_help; exit 2;;
  esac
done

echo "Building image: $TAG"
echo "Project root: $ROOT"

if [[ $COMPOSE -eq 1 ]]; then
  if ! command -v docker-compose >/dev/null 2>&1; then
    echo "docker-compose not found in PATH" >&2; exit 3
  fi
  if [[ $NO_CACHE -eq 1 ]]; then
    echo "docker-compose build --no-cache"
    docker-compose build --no-cache
  else
    echo "docker-compose build"
    docker-compose build
  fi
else
  DCMD=(docker build)
  DCMD+=(--platform linux/amd64)
  if [[ $NO_CACHE -eq 1 ]]; then
    DCMD+=(--no-cache)
  fi
  DCMD+=(-t "$TAG" "$ROOT")
  # shellcheck disable=SC2086
  echo "${DCMD[*]}"
  # Use eval to allow the array to expand with quotes preserved for tag and path
  eval "${DCMD[*]}"
fi

echo "Build complete: $TAG"
