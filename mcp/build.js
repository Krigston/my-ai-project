#!/usr/bin/env node
import { exec } from 'node:child_process'
import { promisify } from 'node:util'
import { logPipelineEvent } from './pipeline-log.js'

const execPromise = promisify(exec)
const command = process.argv.slice(2)[0]

const commands = {
  lint: 'npm run lint',
  'test:unit': 'npm run test:unit',
  build: 'npm run build',
}

async function run() {
  if (!commands[command]) {
    await logPipelineEvent('mcp-build', 'validate-command', 'error', { command })
    console.error(`Неизвестная команда. Доступно: ${Object.keys(commands).join(', ')}`)
    process.exit(1)
  }

  await logPipelineEvent('mcp-build', 'run-command', 'started', { command })
  try {
    const { stdout, stderr } = await execPromise(commands[command], { cwd: process.cwd() })
    await logPipelineEvent('mcp-build', 'run-command', 'success', { command })
    console.log(JSON.stringify({ success: true, stdout, stderr }, null, 2))
  } catch (error) {
    await logPipelineEvent('mcp-build', 'run-command', 'error', {
      command,
      error: error?.message || String(error),
    })
    console.log(
      JSON.stringify(
        {
          success: false,
          error: error?.message || String(error),
          stdout: error?.stdout || '',
          stderr: error?.stderr || '',
        },
        null,
        2,
      ),
    )
    process.exit(1)
  }
}

run()
