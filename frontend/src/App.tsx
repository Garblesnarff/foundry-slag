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
  const [batchProgress, setBatchProgress] = useState<{
    completed: number
    total: number
    status: string
  } | null>(null)

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
        setBatchProgress({ completed: 0, total: files.length, status: 'processing' })
        await api.batchRemoveBackground(files, { model: currentModel }, (progress) => {
          setBatchProgress({
            completed: progress.completed,
            total: progress.total,
            status: progress.status,
          })
        })
        setBatchProgress(null)
        setView('history')
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
      const blob = await api.exportResult(result.id, 'png', settings.feather, settings.shift)
      const base64 = await new Promise<string>((resolve) => {
        const reader = new FileReader()
        reader.onload = () => resolve(reader.result as string)
        reader.readAsDataURL(blob)
      })
      setResult(prev => prev ? { ...prev, result: base64 } : null)
    } catch (err) {
      console.error('Re-processing failed:', err)
      setError(err instanceof Error ? err.message : 'Re-processing failed')
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

  const handleHistorySelect = useCallback(async (entry: any) => {
    try {
      const blob = await api.exportResult(entry.id, 'png')
      const base64 = await new Promise<string>((resolve) => {
        const reader = new FileReader()
        reader.onload = () => resolve(reader.result as string)
        reader.readAsDataURL(blob)
      })
      setResult({
        id: entry.id,
        original: '',
        result: base64,
        model: entry.modelName || 'u2net',
        processingTimeMs: entry.processingTimeMs || 0,
      })
      setView('main')
    } catch (err) {
      setError('Failed to load history entry')
    }
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

            {batchProgress && (
              <div className="mb-6 p-4 bg-slag-amber/10 border border-slag-amber/30 rounded-lg">
                <p className="text-sm text-forge-light mb-2">
                  Processing batch: {batchProgress.completed}/{batchProgress.total}
                </p>
                <div className="w-full bg-forge-gray rounded-full h-2">
                  <div
                    className="bg-slag-amber h-2 rounded-full transition-all"
                    style={{ width: `${(batchProgress.completed / batchProgress.total) * 100}%` }}
                  />
                </div>
              </div>
            )}

            {!result ? (
              <Dropzone
                onFilesSelected={handleFilesSelected}
                isProcessing={isProcessing}
                multiple={true}
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
