#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-}"
FEATURE_NAME="${2:-}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  echo "Использование: ./conductor.sh {start|finish} <feature-name>"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Ошибка: не найдена команда '$1'"
    exit 1
  fi
}

ensure_git_repo() {
  if ! git -C "$SCRIPT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Ошибка: $SCRIPT_DIR не является git-репозиторием."
    echo "Conductor работает только внутри git-проекта."
    exit 1
  fi
}

resolve_base_branch() {
  if git -C "$SCRIPT_DIR" show-ref --verify --quiet refs/heads/main; then
    echo "main"
    return
  fi
  if git -C "$SCRIPT_DIR" show-ref --verify --quiet refs/heads/master; then
    echo "master"
    return
  fi
  git -C "$SCRIPT_DIR" branch --show-current
}

activate_project_node() {
  local nvm_script=""
  if [ -n "${NVM_DIR:-}" ] && [ -s "${NVM_DIR}/nvm.sh" ]; then
    nvm_script="${NVM_DIR}/nvm.sh"
  elif [ -s "${HOME}/.nvm/nvm.sh" ]; then
    nvm_script="${HOME}/.nvm/nvm.sh"
  fi

  if [ -n "$nvm_script" ]; then
    set +u +e
    # shellcheck disable=SC1090
    . "$nvm_script"
    nvm use --silent 22.13.1 >/dev/null 2>&1 || nvm use --silent 22 >/dev/null 2>&1 || true
    set -euo pipefail
  fi
}

require_cmd git
require_cmd npm
ensure_git_repo
BASE_BRANCH="$(resolve_base_branch)"
FEATURE_BRANCH="feature/${FEATURE_NAME}"

case "$COMMAND" in
  start)
    if [ -z "$FEATURE_NAME" ]; then
      usage
      exit 1
    fi

    WORKTREE_PATH="${SCRIPT_DIR}/../${FEATURE_NAME}-worktree"
    if [ -d "$WORKTREE_PATH" ]; then
      echo "Worktree уже существует: $WORKTREE_PATH"
      exit 1
    fi

    if [ -n "$(git -C "$SCRIPT_DIR" status --porcelain)" ]; then
      echo "Ошибка: есть незакоммиченные изменения в основном дереве."
      echo "Перед start закоммитьте или отложите изменения."
      exit 1
    fi

    if git -C "$SCRIPT_DIR" show-ref --verify --quiet "refs/heads/${FEATURE_BRANCH}"; then
      echo "Ошибка: локальная ветка ${FEATURE_BRANCH} уже существует."
      exit 1
    fi

    git -C "$SCRIPT_DIR" checkout "$BASE_BRANCH"
    if git -C "$SCRIPT_DIR" ls-remote --exit-code --heads origin "$BASE_BRANCH" >/dev/null 2>&1; then
      git -C "$SCRIPT_DIR" pull --ff-only origin "$BASE_BRANCH"
    else
      echo "Предупреждение: origin/$BASE_BRANCH не найден, продолжаю с локальной веткой."
    fi

    git -C "$SCRIPT_DIR" worktree add -b "$FEATURE_BRANCH" "$WORKTREE_PATH" "$BASE_BRANCH"

    [ -f "$SCRIPT_DIR/.cursorrules" ] && cp "$SCRIPT_DIR/.cursorrules" "$WORKTREE_PATH/" || true
    [ -d "$SCRIPT_DIR/.vscode" ] && cp -r "$SCRIPT_DIR/.vscode" "$WORKTREE_PATH/" || true

    (
      cd "$WORKTREE_PATH"
      activate_project_node
      npm install
    )

    if command -v cursor >/dev/null 2>&1; then
      (
        cd "$WORKTREE_PATH"
        cursor .
      )
    else
      echo "Подсказка: откройте вручную $WORKTREE_PATH в Cursor."
    fi

    echo "Worktree для фичи '${FEATURE_NAME}' создан: $WORKTREE_PATH"
    ;;

  finish)
    if [ -z "$FEATURE_NAME" ]; then
      usage
      exit 1
    fi

    WORKTREE_PATH="${SCRIPT_DIR}/../${FEATURE_NAME}-worktree"
    if [ ! -d "$WORKTREE_PATH" ]; then
      echo "Worktree не найден: $WORKTREE_PATH"
      exit 1
    fi

    (
      cd "$WORKTREE_PATH"
      activate_project_node
      npm install
      if [ -n "$(git status --porcelain)" ]; then
        echo "Есть незакоммиченные изменения. Сначала закоммитьте их."
        exit 1
      fi

      npm run lint
      npm run test:unit
      git push -u origin "$FEATURE_BRANCH"

      if command -v gh >/dev/null 2>&1; then
        gh pr create --title "feat: ${FEATURE_NAME}" --body "Автоматически созданный PR"
      else
        echo "GitHub CLI не установлен. Создайте PR вручную."
      fi
    )

    git -C "$SCRIPT_DIR" worktree remove "$WORKTREE_PATH"
    git -C "$SCRIPT_DIR" branch -d "$FEATURE_BRANCH" || echo "Ветка не удалена (возможно, не слита)"
    echo "Фича '${FEATURE_NAME}' завершена"
    ;;

  *)
    usage
    exit 1
    ;;
esac
