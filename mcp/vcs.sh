#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"
ARG1="${2:-}"
ARG2="${3:-}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs/ai-pipeline"
LOG_FILE="${LOG_DIR}/mcp-vcs.jsonl"

log_event() {
  local event="$1"
  local status="$2"
  local details="${3:-}"
  mkdir -p "$LOG_DIR"
  printf '{"ts":"%s","source":"mcp-vcs","event":"%s","status":"%s","details":"%s"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    "$event" \
    "$status" \
    "${details//\"/\'}" >>"$LOG_FILE"
}

usage() {
  echo "Использование:"
  echo "  $0 create-branch <name>"
  echo "  $0 commit <message>"
  echo "  $0 push <branch>"
  echo "  $0 create-pr <title>"
}

case "$ACTION" in
  create-branch)
    if [ -z "$ARG1" ]; then
      usage
      exit 1
    fi
    log_event "create-branch" "started" "branch=$ARG1"
    git checkout -b "$ARG1"
    log_event "create-branch" "success" "branch=$ARG1"
    echo "Ветка $ARG1 создана и переключена"
    ;;
  commit)
    if [ -z "$ARG1" ]; then
      usage
      exit 1
    fi
    log_event "commit" "started" "message=$ARG1"
    git add .
    git commit -m "$ARG1"
    log_event "commit" "success"
    echo "Коммит создан"
    ;;
  push)
    if [ -z "$ARG1" ]; then
      usage
      exit 1
    fi
    log_event "push" "started" "branch=$ARG1"
    git push origin "$ARG1"
    log_event "push" "success" "branch=$ARG1"
    echo "Изменения отправлены в ветку $ARG1"
    ;;
  create-pr)
    if [ -z "$ARG1" ]; then
      usage
      exit 1
    fi
    if ! command -v gh >/dev/null 2>&1; then
      log_event "create-pr" "error" "gh-not-installed"
      echo "GitHub CLI (gh) не установлен"
      exit 1
    fi
    log_event "create-pr" "started" "title=$ARG1"
    gh pr create --title "$ARG1" --body "${ARG2:-Автоматически созданный PR}"
    log_event "create-pr" "success" "title=$ARG1"
    ;;
  *)
    log_event "invoke" "error" "unknown-action=$ACTION"
    usage
    exit 1
    ;;
esac
