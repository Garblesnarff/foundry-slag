/**
 * HistoryView Component
 * 
 * Displays processing history with search and filters.
 * Allows re-export and deletion.
 */

import { useState, useEffect } from 'react'
import { api } from '../api/client'

interface HistoryEntry {
  id: string
  originalFilename: string
  modelName: string
  processingTimeMs: number
  createdAt: string
  settings: Record<string, unknown>
}

interface HistoryViewProps {
  onSelectEntry: (entry: HistoryEntry) => void
}

export function HistoryView({ onSelectEntry }: HistoryViewProps) {
  const [entries, setEntries] = useState<HistoryEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [filterModel, setFilterModel] = useState('')

  useEffect(() => {
    loadHistory()
  }, [])

  const loadHistory = async () => {
    try {
      const data = await api.getHistory()
      if (data.entries) {
        setEntries(data.entries)
      }
    } catch (err) {
      console.error('Failed to load history:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async (id: string) => {
    try {
      await api.deleteHistoryEntry(id)
      setEntries(entries.filter(e => e.id !== id))
    } catch (err) {
      console.error('Failed to delete entry:', err)
    }
  }

  const filteredEntries = entries.filter(entry => {
    const matchesSearch = entry.originalFilename.toLowerCase().includes(search.toLowerCase())
    const matchesModel = !filterModel || entry.modelName === filterModel
    return matchesSearch && matchesModel
  })

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr)
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const formatTime = (ms: number) => {
    if (ms < 1000) return `${ms}ms`
    return `${(ms / 1000).toFixed(1)}s`
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="w-8 h-8 border-2 border-slag-amber/30 border-t-slag-amber rounded-full animate-spin" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="font-title text-xl text-slag-amber">History</h2>
        <span className="text-sm text-forge-gray">
          {entries.length} entries
        </span>
      </div>

      {/* Filters */}
      <div className="flex gap-4">
        <input
          type="text"
          placeholder="Search files..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="input-primary flex-1"
        />
        <select
          value={filterModel}
          onChange={(e) => setFilterModel(e.target.value)}
          className="input-primary"
        >
          <option value="">All models</option>
          {['u2net', 'u2netp', 'isnet-general-use', 'isnet-anime', 'silueta', 'u2net_human_seg'].map(model => (
            <option key={model} value={model}>{model}</option>
          ))}
        </select>
      </div>

      {/* Entry list */}
      {filteredEntries.length === 0 ? (
        <div className="text-center py-12 text-forge-gray">
          <p>No history entries found</p>
          <p className="text-sm mt-2">Your processed images will appear here</p>
        </div>
      ) : (
        <div className="space-y-2">
          {filteredEntries.map(entry => (
            <div 
              key={entry.id}
              className="card flex items-center justify-between p-4 hover:bg-forge-gray/50 transition-colors"
            >
              <div 
                className="flex items-center gap-4 cursor-pointer flex-1"
                onClick={() => onSelectEntry(entry)}
              >
                {/* Thumbnail placeholder */}
                <div className="w-12 h-12 bg-forge-black rounded-lg flex items-center justify-center">
                  <svg className="w-6 h-6 text-forge-gray" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                </div>

                {/* Info */}
                <div>
                  <p className="text-forge-light truncate max-w-[200px]">
                    {entry.originalFilename}
                  </p>
                  <div className="flex items-center gap-2 text-xs text-forge-gray mt-1">
                    <span className="font-mono">{entry.modelName}</span>
                    <span>•</span>
                    <span>{formatTime(entry.processingTimeMs)}</span>
                    <span>•</span>
                    <span>{formatDate(entry.createdAt)}</span>
                  </div>
                </div>
              </div>

              {/* Actions */}
              <div className="flex items-center gap-2">
                <button
                  onClick={() => onSelectEntry(entry)}
                  className="text-sm text-slag-amber hover:underline"
                >
                  View
                </button>
                <button
                  onClick={() => handleDelete(entry.id)}
                  className="text-sm text-red-500 hover:underline"
                >
                  Delete
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Empty state message */}
      <p className="text-center text-xs text-forge-gray italic">
        The forge keeps your history
      </p>
    </div>
  )
}
