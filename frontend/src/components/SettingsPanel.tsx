/**
 * SettingsPanel Component
 * 
 * User preferences and model management.
 */

import { useState, useEffect } from 'react'
import { api } from '../api/client'

interface Settings {
  defaultModel: string
  defaultFormat: string
  autoBackup: boolean
  resultTTLDays: number
}

interface SettingsPanelProps {
  onClose: () => void
}

export function SettingsPanel({ onClose }: SettingsPanelProps) {
  const [settings, setSettings] = useState<Settings>({
    defaultModel: 'u2net',
    defaultFormat: 'png',
    autoBackup: false,
    resultTTLDays: 30,
  })
  const [models, setModels] = useState<Array<{ name: string; size: string; installed: boolean }>>([])
  const [saving, setSaving] = useState(false)
  const [downloadingModel, setDownloadingModel] = useState<string | null>(null)

  useEffect(() => {
    loadSettings()
    loadModels()
  }, [])

  const loadSettings = async () => {
    try {
      const data = await api.getSettings()
      setSettings(data)
    } catch (err) {
      console.error('Failed to load settings:', err)
    }
  }

  const loadModels = async () => {
    try {
      const data = await api.getModels()
      if (data.models) {
        setModels(data.models)
      }
    } catch (err) {
      console.error('Failed to load models:', err)
    }
  }

  const handleSave = async () => {
    setSaving(true)
    try {
      await api.updateSettings(settings)
    } catch (err) {
      console.error('Failed to save settings:', err)
    } finally {
      setSaving(false)
    }
  }

  const handleDownloadModel = async (name: string) => {
    setDownloadingModel(name)
    try {
      await api.downloadModel(name)
      await loadModels()
    } catch (err) {
      console.error('Failed to download model:', err)
    } finally {
      setDownloadingModel(null)
    }
  }

  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-50">
      <div className="bg-forge-gray rounded-xl w-full max-w-lg max-h-[80vh] overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-forge-black">
          <h2 className="font-title text-xl text-slag-amber">Settings</h2>
          <button
            onClick={onClose}
            className="text-forge-light opacity-50 hover:opacity-100"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6 overflow-y-auto max-h-[60vh]">
          {/* Default Model */}
          <div>
            <label className="text-sm text-forge-light mb-2 block">Default Model</label>
            <select
              value={settings.defaultModel}
              onChange={(e) => setSettings({ ...settings, defaultModel: e.target.value })}
              className="input-primary w-full"
            >
              {models.map(model => (
                <option key={model.name} value={model.name}>{model.name}</option>
              ))}
            </select>
          </div>

          {/* Default Format */}
          <div>
            <label className="text-sm text-forge-light mb-2 block">Default Export Format</label>
            <select
              value={settings.defaultFormat}
              onChange={(e) => setSettings({ ...settings, defaultFormat: e.target.value })}
              className="input-primary w-full"
            >
              <option value="png">PNG (Transparent)</option>
              <option value="webp">WebP</option>
              <option value="jpg">JPG</option>
            </select>
          </div>

          {/* Result TTL */}
          <div>
            <label className="text-sm text-forge-light mb-2 block">
              Keep Results (Days)
            </label>
            <input
              type="number"
              min="1"
              max="365"
              value={settings.resultTTLDays}
              onChange={(e) => setSettings({ ...settings, resultTTLDays: Number(e.target.value) })}
              className="input-primary w-full"
            />
            <p className="text-xs text-forge-gray mt-1">
              Results older than this will be automatically deleted
            </p>
          </div>

          {/* Auto Backup */}
          <div className="flex items-center justify-between">
            <div>
              <label className="text-sm text-forge-light">Auto Backup</label>
              <p className="text-xs text-forge-gray">Backup history to JSON</p>
            </div>
            <button
              onClick={() => setSettings({ ...settings, autoBackup: !settings.autoBackup })}
              className={`w-12 h-6 rounded-full transition-colors relative ${
                settings.autoBackup ? 'bg-slag-amber' : 'bg-forge-black'
              }`}
            >
              <div className={`absolute w-5 h-5 rounded-full bg-forge-light top-0.5 transition-transform ${
                settings.autoBackup ? 'translate-x-6' : 'translate-x-0.5'
              }`} 
            />
            </button>
          </div>

          {/* Model Management */}
          <div>
            <label className="text-sm text-forge-light mb-3 block">Model Management</label>
            <div className="space-y-2">
              {models.map(model => (
                <div 
                  key={model.name}
                  className="flex items-center justify-between p-3 bg-forge-black rounded-lg"
                >
                  <div>
                    <span className="text-forge-light font-mono text-sm">{model.name}</span>
                    <span className="text-xs text-forge-gray ml-2">{model.size}</span>
                  </div>
                  {model.installed ? (
                    <span className="text-xs text-green-500">Installed</span>
                  ) : (
                    <button
                      onClick={() => handleDownloadModel(model.name)}
                      disabled={downloadingModel === model.name}
                      className="text-xs text-slag-amber hover:underline disabled:opacity-50"
                    >
                      {downloadingModel === model.name ? 'Downloading...' : 'Download'}
                    </button>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-forge-black flex justify-end gap-4">
          <button
            onClick={onClose}
            className="btn-secondary"
          >
            Cancel
          </button>
          <button
            onClick={handleSave}
            disabled={saving}
            className="btn-primary"
          >
            {saving ? 'Saving...' : 'Save Settings'}
          </button>
        </div>
      </div>
    </div>
  )
}
