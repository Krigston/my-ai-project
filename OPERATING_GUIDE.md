# AI DevOS Operating Guide

Практическое руководство по эффективной разработке в этом проекте (Vue + MCP + Conductor).

## 1) Что это за система

Эта система объединяет:
- **Conductor** для изолированной разработки фич через `git worktree`.
- **MCP-инструменты** для задач AI-агента (Figma, Browser, Build, VCS).
- **Quality Gate** через локальные проверки и CI в GitHub Actions.
- **Наблюдаемость** через логи в `logs/ai-pipeline/`.

## 2) Быстрый старт

1. Установить Node по требованиям проекта:
```bash
node -v
```
Ожидается: `>=20.19.0` (рекомендуется `22.13+`).

2. Установить зависимости:
```bash
npm install
```

3. (Опционально) Настроить Figma:
```bash
cat > .env <<'EOF'
FIGMA_TOKEN=your_figma_token
FIGMA_PORT=3001
EOF
```

4. Проверить локальное качество:
```bash
npm run type-check
npm run lint
npm run test:unit
npm run build
```

## 3) Ежедневный рабочий цикл (рекомендуемый)

1. Сформулировать задачу по шаблону:
- `docs/ai/TASK_TEMPLATE.md`

2. Создать изолированную ветку/окружение:
```bash
./conductor.sh start my-feature
```

3. Работать в worktree:
- путь: `../my-feature-worktree`

4. Использовать MCP по назначению:
- Figma: `npm run mcp:figma`
- Browser: `npm run mcp:browser -- screenshot <url> [output]`
- Build: `npm run mcp:build -- <lint|test:unit|build>`
- VCS: `npm run mcp:vcs -- <command> ...`

5. Закрыть фичу:
```bash
./conductor.sh finish my-feature
```

## 4) Quality Gate (обязательно перед merge)

Локально должно быть зелёным:
```bash
npm run type-check
npm run lint
npm run test:unit
npm run build
```

И в PR должен быть зелёный workflow:
- `.github/workflows/ci.yml`

## 5) Наблюдаемость и аудит

Логи AI-пайплайна пишутся в:
- `logs/ai-pipeline/events.jsonl` (общий поток)
- `logs/ai-pipeline/conductor.jsonl`
- `logs/ai-pipeline/mcp-build.jsonl`
- `logs/ai-pipeline/mcp-figma.jsonl`
- `logs/ai-pipeline/mcp-browser.jsonl`
- `logs/ai-pipeline/mcp-vcs.jsonl`

Просмотр в реальном времени:
```bash
npm run logs:ai
```

## 6) Критерий “готово”

Фича считается завершенной только если выполнены пункты:
- `docs/ai/DONE_CRITERIA.md`

Минимально:
- scope выполнен;
- quality gate зелёный;
- логи есть;
- ветка запушена и PR создан (или зафиксирована причина, почему нет).

## 7) Анти-паттерны (чего избегать)

- Разработка фичи напрямую в `main`.
- Большие пачки изменений без промежуточных проверок.
- Ручные действия вместо MCP там, где есть готовая команда.
- Отсутствие acceptance criteria до начала реализации.
- Хранение токенов в репозитории (секреты только в `.env`).

## 8) Рекомендуемое имя системы

Используйте единое название в документации и коммуникации:
- **Krigston AI DevOS**

