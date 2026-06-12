#!/usr/bin/env bash
set -euo pipefail

DEPLOY_DIR="${HOME}/.claude/skills"

usage() {
  echo "Usage: $0 <skill-directory> [--link]" >&2
  echo "" >&2
  echo "  <skill-directory>  Skill directory to package and deploy" >&2
  echo "  --link             Deploy as symlink (local changes reflected immediately)" >&2
  echo "" >&2
  echo "Examples:" >&2
  echo "  $0 image-exif" >&2
  echo "  $0 image-exif --link" >&2
  exit 1
}

SKILL_DIR=""
USE_LINK=false

for arg in "$@"; do
  case "$arg" in
    --link) USE_LINK=true ;;
    -*) echo "Error: unknown option '$arg'" >&2; usage ;;
    *)
      if [[ -z "$SKILL_DIR" ]]; then
        SKILL_DIR="$arg"
      else
        echo "Error: unexpected argument '$arg'" >&2
        usage
      fi
      ;;
  esac
done

if [[ -z "$SKILL_DIR" ]]; then
  usage
fi

SKILL_DIR="${SKILL_DIR%/}"

if [[ ! -d "$SKILL_DIR" ]]; then
  echo "Error: directory '$SKILL_DIR' not found" >&2
  exit 1
fi

if [[ ! -f "$SKILL_DIR/SKILL.md" ]]; then
  echo "Error: '$SKILL_DIR/SKILL.md' not found" >&2
  exit 1
fi

SKILL_NAME=$(basename "$SKILL_DIR")
SKILL_ABS="$(pwd)/${SKILL_DIR}"

mkdir -p bin
OUTPUT="$(pwd)/bin/${SKILL_NAME}.zip"
rm -f "$OUTPUT"

(
  cd "$SKILL_DIR"
  if [[ -d datas ]]; then
    zip -r "$OUTPUT" SKILL.md datas/ >/dev/null
  else
    zip -j "$OUTPUT" SKILL.md >/dev/null
  fi
)

echo "Packaged → bin/${SKILL_NAME}.zip"

DEPLOY_DIR_EXISTED=true
if [[ ! -d "$DEPLOY_DIR" ]]; then
  DEPLOY_DIR_EXISTED=false
fi
mkdir -p "$DEPLOY_DIR"
TARGET="${DEPLOY_DIR}/${SKILL_NAME}"

if [[ "$USE_LINK" == true ]]; then
  if [[ -L "$TARGET" ]]; then
    rm "$TARGET"
  elif [[ -d "$TARGET" ]]; then
    echo "Error: '$TARGET' already exists as a directory, remove it first to use --link" >&2
    exit 1
  fi
  ln -s "$SKILL_ABS" "$TARGET"
  echo "Deployed → $TARGET (symlink)"
else
  rsync -a --delete "${SKILL_DIR}/" "${TARGET}/"
  echo "Deployed → $TARGET"
fi

if [[ "$DEPLOY_DIR_EXISTED" == false ]]; then
  echo ""
  echo "Note: ~/.claude/skills/ was just created. Restart Claude Code for the skill to be detected."
else
  echo "Done — skill '${SKILL_NAME}' ready in Claude Code (no restart needed)"
fi
