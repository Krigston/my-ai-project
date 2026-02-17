#!/usr/bin/env node
import { mkdir, appendFile } from 'node:fs/promises'
import path from 'node:path'

const LOG_DIR = path.resolve(process.cwd(), 'logs/ai-pipeline')
const COMMON_LOG_FILE = path.join(LOG_DIR, 'events.jsonl')

export async function logPipelineEvent(source, event, status, details = {}) {
  const payload = {
    ts: new Date().toISOString(),
    source,
    event,
    status,
    details,
  }

  const line = `${JSON.stringify(payload)}\n`
  await mkdir(LOG_DIR, { recursive: true })
  await appendFile(COMMON_LOG_FILE, line, 'utf8')
  await appendFile(path.join(LOG_DIR, `${source}.jsonl`), line, 'utf8')
}
