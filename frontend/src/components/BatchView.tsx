/**
 * BatchView Component
 * 
 * Displays batch processing queue and results gallery.
 * Shows progress and allows batch export.
 */

import { useState } from 'react'

interface BatchItem {
  id: string
  originalFilename: string
  status: 'pending' | 'processing' | 'completed' | 'error'
  result?: string
  error?: string
}

interface BatchViewProps {
  items: BatchItem[]
  progress: number
  completed: number
  total: number
  onExport: (ids: string[]) => void
  onClear: () => void
}

export function BatchView({ items, progress, completed, total, onExport, onClear }: BatchViewProps) {
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set())

  const toggleSelection = (id: string) => {
    const newSelected = new Set(selectedIds)
    if (newSelected.has(id)) {
      newSelected.delete(id)
    } else {
      newSelected.add(id)
    }
    setSelectedIds(newSelected)
  }

  const selectAll = () => {
    if (selectedIds.size === items.filter(i => i.status === 'completed').length) {
      setSelectedIds(new Set())
    } else {
      setSelectedIds(new Set(items.filter(i => i.status === 'completed').map(i => i.id)))
    }
  }

  return (
    <div className="space-y-6">
      {/* Progress header */}
      <div className="card">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-title text-xl text-slag-amber">Batch Processing</h2>
          <span className="text-sm font-mono text-forge-gray">
            {completed} / {total}
          </span>
        </div>

        {/* Progress bar */}
        <div className="h-2 bg-forge-black rounded-full overflow-hidden">
          <div 
            className="h-full bg-slag-amber transition-all duration-300"
            style={{ width: `${progress}%` }}
          />
        </div>

        <p className="text-xs text-forge-gray mt-2 text-center">
          {progress === 100 ? 'All done!' : 'Slagging images...'}
        </p>
      </div>

      {/* Gallery */}
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
        {items.map((item) => (
          <div 
            key={item.id}
            className={`
              relative rounded-lg overflow-hidden border-2 transition-colors
              ${selectedIds.has(item.id) ? 'border-slag-amber' : 'border-forge-gray'}
              ${item.status === 'error' ? 'border-red-500' : ''}
            `}
            onClick={() => item.status === 'completed' && toggleSelection(item.id)}
          >
            {/* Image preview */}
            {item.result ? (
              <img 
                src={item.result} 
                alt={item.originalFilename}
                className="w-full aspect-square object-cover"
              />
            ) : (
              <div className="w-full aspect-square bg-forge-gray flex items-center justify-center">
                {item.status === 'pending' && (
                  <span className="text-xs text-forge-gray">Pending</span>
                )}
                {item.status === 'processing' && (
                  <div className="w-6 h-6 border-2 border-slag-amber/30 border-t-slag-amber rounded-full animate-spin" />
                )}
                {item.status === 'error' && (
                  <span className="text-xs text-red-500">Error</span>
                )}
              </div>
            )}

            {/* Filename */}
            <div className="absolute bottom-0 left-0 right-0 bg-black/60 px-2 py-1">
              <span className="text-xs text-forge-light truncate block">
                {item.originalFilename}
              </span>
            </div>

            {/* Selection indicator */}
            {item.status === 'completed' && selectedIds.has(item.id) && (
              <div className="absolute top-2 right-2 w-6 h-6 bg-slag-amber rounded-full flex items-center justify-center">
                <svg className="w-4 h-4 text-forge-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Actions */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={selectAll}
            className="btn-secondary text-sm"
            disabled={items.filter(i => i.status === 'completed').length === 0}
          >
            {selectedIds.size === items.filter(i => i.status === 'completed').length 
              ? 'Deselect All' 
              : 'Select All'}
          </button>

          <button
            onClick={onClear}
            className="text-sm text-forge-gray hover:text-forge-light"
          >
            Clear All
          </button>
        </div>

        <button
          onClick={() => onExport(Array.from(selectedIds))}
          className="btn-primary"
          disabled={selectedIds.size === 0}
        >
          Export Selected ({selectedIds.size})
        </button>
      </div>
    </div>
  )
}
