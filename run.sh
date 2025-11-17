#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=$(basename "$0")
REPO_DIR=$(cd "$(dirname "$0")" && pwd)
IMAGE="bios-tool:dev"

usage(){
  cat <<EOF
Usage: $SCRIPT_NAME [options] [-- command args...]

Options:
  --no-mount         Do not mount the repository into the container
  --vendor PATH      Mount host PATH into /opt/vendor in the container
  -h, --help         Show this help

If no command is provided, an interactive shell (/bin/bash) is started.
By default the script will build the image if it's missing, mount the repo
into /opt/bios-tool and mount ./vendor (if present) into /opt/vendor.
EOF
}

# defaults
NO_MOUNT=0
VENDOR_HOST=""

if [ "$#" -eq 0 ]; then
  # nothing passed; we'll start a shell later
  :
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --no-mount)
      NO_MOUNT=1; shift ;;
    --vendor)
      VENDOR_HOST="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    --)
      shift; break ;;
    -* )
      echo "Unknown option: $1" >&2; usage; exit 2 ;;
    *)
      break ;;
  esac
done

# Remaining args are the command to run in the container
if [ $# -gt 0 ]; then
  CMD=("$@")
else
  CMD=("/bin/bash")
fi

# Ensure image exists, otherwise build it
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Docker image $IMAGE not found; building..."
  docker build --platform linux/amd64 -t "$IMAGE" "$REPO_DIR"
fi

DOCKER_ARGS=(--rm -it --platform linux/amd64)

if [ "$NO_MOUNT" -eq 0 ]; then
  DOCKER_ARGS+=( -v "$REPO_DIR":/opt/bios-tool )
fi

# Ensure configs directory exists and is available inside the container.
if [ -d "$REPO_DIR/configs" ]; then
  DOCKER_ARGS+=( -v "$REPO_DIR/configs":/opt/bios-tool/configs )
else
  mkdir -p "$REPO_DIR/configs"
  DOCKER_ARGS+=( -v "$REPO_DIR/configs":/opt/bios-tool/configs )
fi

if [ -n "$VENDOR_HOST" ]; then
  if [ ! -e "$VENDOR_HOST" ]; then
    echo "Specified vendor path does not exist: $VENDOR_HOST" >&2
    exit 3
  fi
  DOCKER_ARGS+=( -v "$VENDOR_HOST":/opt/vendor )
elif [ -d "$REPO_DIR/vendor" ]; then
  DOCKER_ARGS+=( -v "$REPO_DIR/vendor":/opt/vendor )
fi


echo "Running container $IMAGE"
echo "Command: ${CMD[*]}"

exec docker run "${DOCKER_ARGS[@]}" "$IMAGE" "${CMD[@]}"
