/**
 * ResultPreview Component
 * 
 * Displays the processed result with original for comparison.
 * Shows processing time and export options.
 */

import { useState } from 'react'
import { CompareSlider } from './CompareSlider'
import { EdgeControls } from './EdgeControls'

interface ResultPreviewProps {
  original: string
  result: string
  model: string
  processingTimeMs: number
  onReProcess: (settings: { feather: number; shift: number }) => void
  onExport: (format: 'png' | 'webp' | 'jpg') => void
  onClear: () => void
}

export function ResultPreview({ 
  original, 
  result, 
  model, 
  processingTimeMs,
  onReProcess,
  onExport,
  onClear 
}: ResultPreviewProps) {
  const [viewMode, setViewMode] = useState<'side-by-side' | 'slider'>('side-by-side')
  const [showExportMenu, setShowExportMenu] = useState(false)
  const [feather, setFeather] = useState(0)
  const [shift, setShift] = useState(0)

  const handleApplySettings = () => {
    onReProcess({ feather, shift })
  }

  const formatTime = (ms: number) => {
    if (ms < 1000) return `${ms}ms`
    return `${(ms / 1000).toFixed(1)}s`
  }

  return (
    <div className="space-y-6">
      {/* Header with view controls */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <h2 className="font-title text-xl text-slag-amber">Result</h2>
          <span className="text-xs font-mono text-forge-gray">
            {model} • {formatTime(processingTimeMs)}
          </span>
        </div>
        
        <div className="flex items-center gap-2">
          {/* View mode toggle */}
          <button
            onClick={() => setViewMode('side-by-side')}
            className={`px-3 py-1 text-sm rounded ${
              viewMode === 'side-by-side' 
                ? 'bg-slag-amber text-forge-black' 
                : 'text-forge-light opacity-50 hover:opacity-100'
            }`}
          >
            Side by Side
          </button>
          <button
            onClick={() => setViewMode('slider')}
            className={`px-3 py-1 text-sm rounded ${
              viewMode === 'slider' 
                ? 'bg-slag-amber text-forge-black' 
                : 'text-forge-light opacity-50 hover:opacity-100'
            }`}
          >
            Compare
          </button>
        </div>
      </div>

      {/* Preview area */}
      {viewMode === 'slider' ? (
        <CompareSlider original={original} result={result} />
      ) : (
        <div className="grid grid-cols-2 gap-4">
          <div className="card">
            <h3 className="text-sm text-forge-gray mb-2">Original</h3>
            <img 
              src={original} 
              alt="Original" 
              className="w-full h-auto rounded-lg"
            />
          </div>
          <div className="card">
            <h3 className="text-sm text-forge-gray mb-2">Result</h3>
            <img 
              src={result} 
              alt="Result" 
              className="w-full h-auto rounded-lg"
            />
          </div>
        </div>
      )}

      {/* Edge controls */}
      <div className="card">
        <h3 className="text-sm text-forge-gray mb-4">Edge Refinement</h3>
        <EdgeControls 
          feather={feather} 
          shift={shift}
          onFeatherChange={setFeather}
          onShiftChange={setShift}
          onApply={handleApplySettings}
        />
      </div>

      {/* Action buttons */}
      <div className="flex items-center justify-between">
        <button
          onClick={onClear}
          className="btn-secondary"
        >
          Clear & Start Over
        </button>

        <div className="relative">
          <button
            onClick={() => setShowExportMenu(!showExportMenu)}
            className="btn-primary flex items-center gap-2"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
            </svg>
            Export
          </button>

          {showExportMenu && (
            <div className="absolute right-0 top-full mt-2 bg-forge-gray border border-forge-gray rounded-lg shadow-lg z-50 min-w-[120px]">
              {(['png', 'webp', 'jpg'] as const).map(format => (
                <button
                  key={format}
                  onClick={() => {
                    onExport(format.toUpperCase() as 'png' | 'webp' | 'jpg')
                    setShowExportMenu(false)
                  }}
                  className="w-full text-left px-4 py-2 text-sm hover:bg-slag-amber/10 text-forge-light font-mono"
                >
                  {format.toUpperCase()}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Slag message */}
      <p className="text-center text-xs text-forge-gray italic">
        "The slag burns away, the gold remains"
      </p>
    </div>
  )
}
