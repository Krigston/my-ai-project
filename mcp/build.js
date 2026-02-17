#!/usr/bin/env node
import { exec } from 'node:child_process'
import { promisify } from 'node:util'

const execPromise = promisify(exec)
const command = process.argv.slice(2)[0]

const commands = {
  lint: 'npm run lint',
  'test:unit': 'npm run test:unit',
  build: 'npm run build',
}

async function run() {
  if (!commands[command]) {
    console.error(`Неизвестная команда. Доступно: ${Object.keys(commands).join(', ')}`)
    process.exit(1)
  }

  try {
    const { stdout, stderr } = await execPromise(commands[command], { cwd: process.cwd() })
    console.log(JSON.stringify({ success: true, stdout, stderr }, null, 2))
  } catch (error) {
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
