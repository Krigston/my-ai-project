#!/usr/bin/env node
import express from 'express'
import dotenv from 'dotenv'
import { logPipelineEvent } from './pipeline-log.js'

dotenv.config()

const app = express()
const PORT = Number(process.env.FIGMA_PORT || 3001)
const FIGMA_TOKEN = process.env.FIGMA_TOKEN

if (!FIGMA_TOKEN) {
  logPipelineEvent('mcp-figma', 'boot', 'error', { reason: 'missing-figma-token' }).catch(() => {})
  console.error('Ошибка: FIGMA_TOKEN не задан в .env')
  process.exit(1)
}

async function figmaRequest(pathname, query) {
  const baseUrl = 'https://api.figma.com/v1'
  const url = new URL(`${baseUrl}${pathname}`)
  if (query) url.search = query

  const response = await fetch(url, {
    headers: { 'X-Figma-Token': FIGMA_TOKEN },
  })

  const data = await response.json()
  if (!response.ok) {
    const message = data?.err || data?.message || `HTTP ${response.status}`
    throw new Error(message)
  }
  return data
}

app.get('/figma/:fileKey', async (req, res) => {
  await logPipelineEvent('mcp-figma', 'fetch-file', 'started', { fileKey: req.params.fileKey })
  try {
    const data = await figmaRequest(`/files/${req.params.fileKey}`)
    await logPipelineEvent('mcp-figma', 'fetch-file', 'success', { fileKey: req.params.fileKey })
    res.json(data)
  } catch (error) {
    await logPipelineEvent('mcp-figma', 'fetch-file', 'error', {
      fileKey: req.params.fileKey,
      error: String(error?.message || error),
    })
    res.status(500).json({ error: String(error?.message || error) })
  }
})

app.get('/figma/:fileKey/nodes', async (req, res) => {
  const ids = req.query.ids
  if (!ids) {
    await logPipelineEvent('mcp-figma', 'fetch-nodes', 'error', {
      fileKey: req.params.fileKey,
      reason: 'missing-ids',
    })
    res.status(400).json({ error: 'Параметр ids обязателен, например ?ids=1:2,2:3' })
    return
  }

  await logPipelineEvent('mcp-figma', 'fetch-nodes', 'started', { fileKey: req.params.fileKey, ids: String(ids) })
  try {
    const params = new URLSearchParams({ ids: String(ids) })
    const data = await figmaRequest(`/files/${req.params.fileKey}/nodes`, params.toString())
    await logPipelineEvent('mcp-figma', 'fetch-nodes', 'success', { fileKey: req.params.fileKey })
    res.json(data)
  } catch (error) {
    await logPipelineEvent('mcp-figma', 'fetch-nodes', 'error', {
      fileKey: req.params.fileKey,
      error: String(error?.message || error),
    })
    res.status(500).json({ error: String(error?.message || error) })
  }
})

app.listen(PORT, () => {
  logPipelineEvent('mcp-figma', 'boot', 'success', { port: PORT }).catch(() => {})
  console.log(`Figma MCP running on http://localhost:${PORT}`)
})
