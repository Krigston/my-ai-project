#!/usr/bin/env node
import path from 'node:path'

const args = process.argv.slice(2)
const command = args[0]

async function loadPlaywright() {
  try {
    const mod = await import('playwright')
    return mod.chromium
  } catch {
    console.error('Playwright не установлен. Выполните: npm i -D playwright && npx playwright install chromium')
    process.exit(1)
  }
}

async function takeScreenshot(url, outputPath) {
  const chromium = await loadPlaywright()
  const browser = await chromium.launch()
  const page = await browser.newPage()
  await page.goto(url, { waitUntil: 'networkidle' })
  await page.screenshot({ path: outputPath, fullPage: true })
  await browser.close()
  console.log(`Скриншот сохранен: ${outputPath}`)
}

async function run() {
  if (command !== 'screenshot') {
    console.error('Использование: npm run mcp:browser -- screenshot <url> [output]')
    process.exit(1)
  }

  const url = args[1]
  const output = args[2] || 'screenshot.png'
  if (!url) {
    console.error('Ошибка: нужно указать URL')
    process.exit(1)
  }

  const outputPath = path.resolve(process.cwd(), output)
  await takeScreenshot(url, outputPath)
}

run().catch((error) => {
  console.error(String(error?.message || error))
  process.exit(1)
})
