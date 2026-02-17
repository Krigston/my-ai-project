#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"
ARG1="${2:-}"
ARG2="${3:-}"

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
    git checkout -b "$ARG1"
    echo "Ветка $ARG1 создана и переключена"
    ;;
  commit)
    if [ -z "$ARG1" ]; then
      usage
      exit 1
    fi
    git add .
    git commit -m "$ARG1"
    echo "Коммит создан"
    ;;
  push)
    if [ -z "$ARG1" ]; then
      usage
      exit 1
    fi
    git push origin "$ARG1"
    echo "Изменения отправлены в ветку $ARG1"
    ;;
  create-pr)
    if [ -z "$ARG1" ]; then
      usage
      exit 1
    fi
    if ! command -v gh >/dev/null 2>&1; then
      echo "GitHub CLI (gh) не установлен"
      exit 1
    fi
    gh pr create --title "$ARG1" --body "${ARG2:-Автоматически созданный PR}"
    ;;
  *)
    usage
    exit 1
    ;;
esac
