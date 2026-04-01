/**
 * TitleBar Component
 * 
 * macOS-style title bar with traffic lights and app title.
 * Shows current model and quick settings.
 */

import { useState, useEffect } from 'react'
import { api } from '../api/client'

interface TitleBarProps {
  currentModel: string
  onModelChange: (model: string) => void
  isProcessing: boolean
  onSettingsClick: () => void
}

export function TitleBar({ currentModel, onModelChange, isProcessing, onSettingsClick }: TitleBarProps) {
  const [models, setModels] = useState<Array<{ name: string; installed: boolean }>>([])
  const [showModelMenu, setShowModelMenu] = useState(false)

  useEffect(() => {
    api.getModels().then(data => {
      if (data.models) {
        setModels(data.models)
      }
    }).catch(console.error)
  }, [])

  return (
    <header className="bg-forge-gray border-b border-forge-gray px-4 py-3 flex items-center justify-between">
      {/* macOS traffic lights */}
      <div className="flex items-center gap-2">
        <div className="w-3 h-3 rounded-full bg-red-500 hover:bg-red-400 cursor-pointer" />
        <div className="w-3 h-3 rounded-full bg-yellow-500 hover:bg-yellow-400 cursor-pointer" />
        <div className="w-3 h-3 rounded-full bg-green-500 hover:bg-green-400 cursor-pointer" />
      </div>

      {/* App title */}
      <h1 className="font-title text-lg tracking-[0.2em] text-slag-amber">
        FOUNDRY SLAG
      </h1>

      {/* Right side controls */}
      <div className="flex items-center gap-4">
        {/* Model selector */}
        <div className="relative">
          <button
            onClick={() => setShowModelMenu(!showModelMenu)}
            className="text-sm text-forge-light opacity-70 hover:opacity-100 flex items-center gap-2"
          >
            <span className="font-mono text-xs">{currentModel}</span>
            {isProcessing && (
              <span className="text-slag-amber animate-pulse">Slagging...</span>
            )}
          </button>
          
          {showModelMenu && (
            <div className="absolute right-0 top-full mt-2 bg-forge-gray border border-forge-gray rounded-lg shadow-lg z-50 min-w-[160px]">
              {models.map(model => (
                <button
                  key={model.name}
                  onClick={() => {
                    onModelChange(model.name)
                    setShowModelMenu(false)
                  }}
                  className={`w-full text-left px-4 py-2 text-sm hover:bg-slag-amber/10 flex items-center justify-between ${
                    model.name === currentModel ? 'text-slag-amber' : 'text-forge-light'
                  }`}
                >
                  <span className="font-mono">{model.name}</span>
                  {!model.installed && (
                    <span className="text-xs text-forge-light opacity-40">↓</span>
                  )}
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Settings button */}
        <button
          onClick={onSettingsClick}
          className="text-forge-light opacity-50 hover:opacity-100 transition-opacity"
          title="Settings"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
        </button>
      </div>
    </header>
  )
}
