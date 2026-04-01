/**
 * App - Foundry Slag
 * 
 * Main application component with state management.
 * Orchestrates all UI components and API calls.
 */

import { useState, useCallback } from 'react'
import { AppProvider, useApp } from './context/AppContext'
import { TitleBar } from './components/TitleBar'
import { Dropzone } from './components/Dropzone'
import { ResultPreview } from './components/ResultPreview'
import { HistoryView } from './components/HistoryView'
import { SettingsPanel } from './components/SettingsPanel'
import { api } from './api/client'

type View = 'main' | 'history'

function AppContent() {
  const { currentModel, setCurrentModel, isProcessing, setIsProcessing } = useApp()
  
  const [view, setView] = useState<View>('main')
  const [result, setResult] = useState<{
    id: string
    original: string
    result: string
    model: string
    processingTimeMs: number
  } | null>(null)
  const [showSettings, setShowSettings] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleFilesSelected = useCallback(async (files: File[]) => {
    if (isProcessing || files.length === 0) return

    setIsProcessing(true)
    setError(null)

    try {
      // Process single image
      if (files.length === 1) {
        const response = await api.removeBackground(files[0], currentModel)
        setResult({
          id: response.id,
          original: response.original,
          result: response.result,
          model: response.model,
          processingTimeMs: response.processingTimeMs,
        })
      } else {
        // TODO: Handle batch processing with SSE
        setError('Batch processing coming soon!')
      }
    } catch (err) {
      console.error('Processing failed:', err)
      setError(err instanceof Error ? err.message : 'Processing failed')
    } finally {
      setIsProcessing(false)
    }
  }, [currentModel, isProcessing, setIsProcessing])

  const handleReProcess = useCallback(async (settings: { feather: number; shift: number }) => {
    if (!result) return
    
    setIsProcessing(true)
    try {
      // Re-process with new settings - using current result as base
      // In a real implementation, we'd call the API with feather/shift params
      console.log('Re-processing with settings:', settings)
    } catch (err) {
      console.error('Re-processing failed:', err)
    } finally {
      setIsProcessing(false)
    }
  }, [result, setIsProcessing])

  const handleExport = useCallback(async (format: 'png' | 'webp' | 'jpg') => {
    if (!result) return

    try {
      const blob = await api.exportResult(result.id, format)
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `slag_export.${format}`
      a.click()
      URL.revokeObjectURL(url)
    } catch (err) {
      console.error('Export failed:', err)
      setError('Export failed')
    }
  }, [result])

  const handleClear = useCallback(() => {
    setResult(null)
    setError(null)
  }, [])

  const handleHistorySelect = useCallback((entry: any) => {
    // Load history entry - would need to fetch the full result
    console.log('Selected history entry:', entry)
  }, [])

  return (
    <div className="min-h-screen bg-forge-black text-forge-light flex flex-col">
      {/* Title Bar */}
      <TitleBar 
        currentModel={currentModel}
        onModelChange={setCurrentModel}
        isProcessing={isProcessing}
        onSettingsClick={() => setShowSettings(true)}
      />

      {/* Navigation */}
      <nav className="bg-forge-gray border-b border-forge-gray px-4 py-2 flex items-center gap-4">
        <button
          onClick={() => setView('main')}
          className={`text-sm ${view === 'main' ? 'text-slag-amber' : 'text-forge-light opacity-50'}`}
        >
          Process
        </button>
        <button
          onClick={() => setView('history')}
          className={`text-sm ${view === 'history' ? 'text-slag-amber' : 'text-forge-light opacity-50'}`}
        >
          History
        </button>
      </nav>

      {/* Main Content */}
      <main className="flex-1 container mx-auto p-6">
        {view === 'main' && (
          <>
            {error && (
              <div className="mb-6 p-4 bg-red-500/20 border border-red-500 rounded-lg text-red-400">
                {error}
              </div>
            )}

            {!result ? (
              <Dropzone 
                onFilesSelected={handleFilesSelected}
                isProcessing={isProcessing}
                multiple={false}
              />
            ) : (
              <ResultPreview
                original={result.original}
                result={result.result}
                model={result.model}
                processingTimeMs={result.processingTimeMs}
                onReProcess={handleReProcess}
                onExport={handleExport}
                onClear={handleClear}
              />
            )}
          </>
        )}

        {view === 'history' && (
          <HistoryView onSelectEntry={handleHistorySelect} />
        )}
      </main>

      {/* Settings Modal */}
      {showSettings && (
        <SettingsPanel onClose={() => setShowSettings(false)} />
      )}
    </div>
  )
}

function App() {
  return (
    <AppProvider>
      <AppContent />
    </AppProvider>
  )
}

export default App
