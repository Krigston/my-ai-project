# Definition of Done for AI Tasks

Task is "Done" only if all checkpoints below are true:

- `Code`: change is implemented and reviewed against requested scope.
- `Quality`: `npm run type-check`, `npm run lint`, `npm run test:unit`, `npm run build` are green.
- `Observability`: execution events exist in `logs/ai-pipeline/events.jsonl` and related source log (`mcp-*.jsonl` or `conductor.jsonl`).
- `Docs`: task decision and result are captured with `docs/ai/TASK_TEMPLATE.md`.
- `Git`: branch is pushed and PR is created (or explicitly documented why not).

## Mandatory PR checklist

- [ ] Scope matches task request.
- [ ] No leaked secrets in code/config/logs.
- [ ] CI workflow is green.
- [ ] Rollback path is understood.
