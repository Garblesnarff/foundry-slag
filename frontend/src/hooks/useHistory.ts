/**
 * useHistory Hook
 * 
 * Custom hook for managing processing history.
 * Fetches and caches history from backend.
 */

import { useEffect, useState } from 'react'
import { api } from '@/api/client'

interface HistoryEntry {
  id: string
  originalFilename: string
  modelName: string
  processingTimeMs: number
  createdAt: string
  settings: Record<string, unknown>
}

export function useHistory() {
  const [history, setHistory] = useState<HistoryEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  const fetchHistory = async () => {
    try {
      setLoading(true)
      const data = await api.getHistory()
      setHistory(data.entries)
      setError(null)
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch history'))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchHistory()
  }, [])

  const deleteEntry = async (id: string) => {
    try {
      await api.deleteHistoryEntry(id)
      setHistory(prev => prev.filter(h => h.id !== id))
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to delete entry'))
    }
  }

  const refresh = () => fetchHistory()

  return { history, loading, error, deleteEntry, refresh }
}
