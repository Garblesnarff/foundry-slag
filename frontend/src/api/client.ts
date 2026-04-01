/**
 * API Client
 * 
 * Fetch-based wrapper for all backend API calls.
 * Handles request/response serialization and error handling.
 * Uses relative URLs which are proxied by Vite to the backend.
 */

const API_URL = '' // Empty because Vite proxies all requests

interface SlagResponse {
  id: string
  result: string // base64-encoded PNG
  original: string
  model: string
  processingTimeMs: number
  settings?: Record<string, unknown>
}

interface BatchProgress {
  status: 'pending' | 'processing' | 'completed' | 'error'
  completed: number
  total: number
  currentId?: string
  progress?: number
  results?: Array<{
    id: string
    originalFilename: string
    model: string
    processingTimeMs: number
  }>
}

interface HistoryEntry {
  id: string
  originalFilename: string
  modelName: string
  processingTimeMs: number
  createdAt: string
  settings: Record<string, unknown>
  batchSetId?: string
}

interface ModelInfo {
  name: string
  size: string
  useCase: string
  installed: boolean
}

interface Settings {
  defaultModel: string
  defaultFormat: string
  autoBackup: boolean
  resultTTLDays: number
}

/**
 * API client singleton with methods for all endpoints
 */
export const api = {
  /**
   * Health check
   */
  async health(): Promise<{ status: string; version: string }> {
    const res = await fetch(`${API_URL}/health`)
    if (!res.ok) throw new Error(`Health check failed: ${res.statusText}`)
    return res.json()
  },

  /**
   * Remove background from single image
   */
  async removeBackground(
    file: File,
    model: string = 'u2net',
    feather: number = 0,
    shift: number = 0,
  ): Promise<SlagResponse> {
    const formData = new FormData()
    formData.append('file', file)
    formData.append('model', model)
    formData.append('feather', feather.toString())
    formData.append('shift', shift.toString())
    
    const res = await fetch(`${API_URL}/slag`, {
      method: 'POST',
      body: formData,
    })
    
    if (!res.ok) {
      const error = await res.json().catch(() => ({ message: 'Unknown error' }))
      throw new Error(error.message || `Background removal failed: ${res.statusText}`)
    }
    return res.json()
  },

  /**
   * Batch remove backgrounds with SSE progress
   */
  async batchRemoveBackground(
    files: File[],
    options: { model?: string; feather?: number; shift?: number } = {},
    onProgress: (progress: BatchProgress) => void,
  ): Promise<SlagResponse[]> {
    const formData = new FormData()
    files.forEach(f => formData.append('files', f))
    formData.append('model', options.model || 'u2net')
    if (options.feather) formData.append('feather', options.feather.toString())
    if (options.shift) formData.append('shift', options.shift.toString())
    
    const res = await fetch(`${API_URL}/slag/batch`, {
      method: 'POST',
      body: formData,
    })
    
    if (!res.ok) throw new Error(`Batch processing failed: ${res.statusText}`)
    
    // Read the SSE stream
    const reader = res.body?.getReader()
    const decoder = new TextDecoder()
    let buffer = ''
    const results: SlagResponse[] = []

    if (!reader) {
      throw new Error('No response body')
    }

    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      
      buffer += decoder.decode(value, { stream: true })
      
      // Process complete SSE messages
      const lines = buffer.split('\n')
      buffer = lines.pop() || ''
      
      for (const line of lines) {
        if (line.startsWith('data: ')) {
          try {
            const data = JSON.parse(line.slice(6))
            onProgress(data)
            
            if (data.status === 'completed' && data.results) {
              return data.results.map((r: any) => ({
                id: r.id,
                result: '', // Would need to fetch individually
                original: '',
                model: r.model,
                processingTimeMs: r.processingTimeMs,
              }))
            }
          } catch (e) {
            // Skip invalid JSON
          }
        }
      }
    }

    return results
  },

  /**
   * Get available models
   */
  async getModels(): Promise<{ models: ModelInfo[] }> {
    const res = await fetch(`${API_URL}/slag/models`)
    if (!res.ok) throw new Error(`Failed to fetch models: ${res.statusText}`)
    return res.json()
  },

  /**
   * Download a model
   */
  async downloadModel(name: string): Promise<{ name: string; size: string; installed: boolean; downloadTimeMs: number }> {
    const res = await fetch(`${API_URL}/slag/models/${name}/download`, {
      method: 'POST',
    })
    if (!res.ok) throw new Error(`Failed to download model: ${res.statusText}`)
    return res.json()
  },

  /**
   * Get processing history
   */
  async getHistory(): Promise<{ entries: HistoryEntry[]; total: number; skip: number; limit: number }> {
    const res = await fetch(`${API_URL}/history`)
    if (!res.ok) throw new Error(`Failed to fetch history: ${res.statusText}`)
    return res.json()
  },

  /**
   * Get single history entry
   */
  async getHistoryEntry(id: string): Promise<HistoryEntry & { resultPath: string }> {
    const res = await fetch(`${API_URL}/history/${id}`)
    if (!res.ok) throw new Error(`Failed to fetch history entry: ${res.statusText}`)
    return res.json()
  },

  /**
   * Delete history entry
   */
  async deleteHistoryEntry(id: string): Promise<void> {
    const res = await fetch(`${API_URL}/history/${id}`, {
      method: 'DELETE',
    })
    if (!res.ok) throw new Error(`Failed to delete history entry: ${res.statusText}`)
  },

  /**
   * Get settings
   */
  async getSettings(): Promise<Settings> {
    const res = await fetch(`${API_URL}/settings`)
    if (!res.ok) throw new Error(`Failed to fetch settings: ${res.statusText}`)
    return res.json()
  },

  /**
   * Update settings
   */
  async updateSettings(settings: Partial<Settings>): Promise<Settings> {
    const res = await fetch(`${API_URL}/settings`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(settings),
    })
    if (!res.ok) throw new Error(`Failed to update settings: ${res.statusText}`)
    return res.json()
  },

  /**
   * Export processed image
   */
  async exportResult(
    id: string,
    format: 'png' | 'webp' | 'jpg',
  ): Promise<Blob> {
    const res = await fetch(`${API_URL}/export/${id}?format=${format}`)
    if (!res.ok) throw new Error(`Failed to export result: ${res.statusText}`)
    return res.blob()
  },

  /**
   * Export batch as ZIP
   */
  async exportBatch(
    ids: string[],
    format: 'png' | 'webp' | 'jpg' = 'png',
  ): Promise<Blob> {
    const res = await fetch(`${API_URL}/export/batch`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ids, format, naming: 'original' }),
    })
    if (!res.ok) throw new Error(`Failed to export batch: ${res.statusText}`)
    return res.blob()
  },
}
