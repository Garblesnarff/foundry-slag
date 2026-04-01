/**
 * App Context
 * 
 * Global state management for Foundry Slag.
 * Stores:
 * - Current model selection
 * - Processing state
 * - Settings
 * - History
 */

import { createContext, useContext, ReactNode, useState } from 'react'

interface AppContextType {
  currentModel: string
  setCurrentModel: (model: string) => void
  isProcessing: boolean
  setIsProcessing: (processing: boolean) => void
  settings: Record<string, unknown>
  updateSettings: (settings: Record<string, unknown>) => void
}

const AppContext = createContext<AppContextType | undefined>(undefined)

export function AppProvider({ children }: { children: ReactNode }) {
  const [currentModel, setCurrentModel] = useState('u2net')
  const [isProcessing, setIsProcessing] = useState(false)
  const [settings, setSettings] = useState<Record<string, unknown>>({})

  const updateSettings = (newSettings: Record<string, unknown>) => {
    setSettings(prev => ({ ...prev, ...newSettings }))
  }

  return (
    <AppContext.Provider value={{
      currentModel,
      setCurrentModel,
      isProcessing,
      setIsProcessing,
      settings,
      updateSettings,
    }}>
      {children}
    </AppContext.Provider>
  )
}

export function useApp() {
  const context = useContext(AppContext)
  if (!context) {
    throw new Error('useApp must be used within AppProvider')
  }
  return context
}
