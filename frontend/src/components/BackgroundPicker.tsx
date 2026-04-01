/**
 * BackgroundPicker Component
 * 
 * Color picker and shadow controls for background replacement.
 */

import { useState } from 'react'

interface BackgroundPickerProps {
  backgroundColor: string
  shadowEnabled: boolean
  shadowBlur: number
  shadowOffsetX: number
  shadowOffsetY: number
  shadowOpacity: number
  onBackgroundColorChange: (color: string) => void
  onShadowToggle: (enabled: boolean) => void
  onShadowChange: (setting: string, value: number) => void
}

export function BackgroundPicker({
  backgroundColor,
  shadowEnabled,
  shadowBlur,
  shadowOffsetX,
  shadowOffsetY,
  shadowOpacity,
  onBackgroundColorChange,
  onShadowToggle,
  onShadowChange,
}: BackgroundPickerProps) {
  const [showColorPicker, setShowColorPicker] = useState(false)

  const presetColors = [
    '#FFFFFF', '#000000', '#F5F5F5', '#3A3935',
    '#E8A849', '#FF6B6B', '#4ECDC4', '#45B7D1',
    '#96CEB4', '#FFEAA7', '#DDA0DD', '#87CEEB',
  ]

  return (
    <div className="space-y-4">
      {/* Background color */}
      <div>
        <label className="text-sm text-forge-light mb-2 block">Background Color</label>
        
        <div className="flex items-center gap-2">
          {/* Current color preview */}
          <button
            onClick={() => setShowColorPicker(!showColorPicker)}
            className="w-10 h-10 rounded-lg border-2 border-forge-gray hover:border-slag-amber transition-colors"
            style={{ backgroundColor: backgroundColor }}
          />
          
          {/* Hex input */}
          <input
            type="text"
            value={backgroundColor}
            onChange={(e) => onBackgroundColorChange(e.target.value)}
            className="input-primary font-mono text-sm flex-1"
            placeholder="#FFFFFF"
          />

          {/* Transparent button */}
          <button
            onClick={() => onBackgroundColorChange('transparent')}
            className="px-3 py-2 text-sm text-forge-light opacity-50 hover:opacity-100 border border-forge-gray rounded"
          >
            None
          </button>
        </div>

        {/* Preset colors */}
        {showColorPicker && (
          <div className="flex flex-wrap gap-2 mt-3">
            {presetColors.map(color => (
              <button
                key={color}
                onClick={() => {
                  onBackgroundColorChange(color)
                  setShowColorPicker(false)
                }}
                className="w-8 h-8 rounded-lg border-2 border-forge-gray hover:border-slag-amber transition-colors"
                style={{ backgroundColor: color }}
              />
            ))}
          </div>
        )}
      </div>

      {/* Shadow toggle */}
      <div className="flex items-center justify-between">
        <label className="text-sm text-forge-light">Drop Shadow</label>
        <button
          onClick={() => onShadowToggle(!shadowEnabled)}
          className={`w-12 h-6 rounded-full transition-colors relative ${
            shadowEnabled ? 'bg-slag-amber' : 'bg-forge-gray'
          }`}
        >
          <div className={`absolute w-5 h-5 rounded-full bg-forge-light top-0.5 transition-transform ${
            shadowEnabled ? 'translate-x-6' : 'translate-x-0.5'
          }`} 
        />
        </button>
      </div>

      {/* Shadow controls */}
      {shadowEnabled && (
        <div className="space-y-3 pl-4 border-l-2 border-forge-gray">
          {/* Blur */}
          <div>
            <div className="flex items-center justify-between mb-1">
              <span className="text-xs text-forge-gray">Blur</span>
              <span className="text-xs font-mono text-slag-amber">{shadowBlur}px</span>
            </div>
            <input
              type="range"
              min="0"
              max="30"
              value={shadowBlur}
              onChange={(e) => onShadowChange('blur', Number(e.target.value))}
              className="slider w-full"
            />
          </div>

          {/* Offset X */}
          <div>
            <div className="flex items-center justify-between mb-1">
              <span className="text-xs text-forge-gray">Offset X</span>
              <span className="text-xs font-mono text-slag-amber">{shadowOffsetX}px</span>
            </div>
            <input
              type="range"
              min="-20"
              max="20"
              value={shadowOffsetX}
              onChange={(e) => onShadowChange('offsetX', Number(e.target.value))}
              className="slider w-full"
            />
          </div>

          {/* Offset Y */}
          <div>
            <div className="flex items-center justify-between mb-1">
              <span className="text-xs text-forge-gray">Offset Y</span>
              <span className="text-xs font-mono text-slag-amber">{shadowOffsetY}px</span>
            </div>
            <input
              type="range"
              min="-20"
              max="20"
              value={shadowOffsetY}
              onChange={(e) => onShadowChange('offsetY', Number(e.target.value))}
              className="slider w-full"
            />
          </div>

          {/* Opacity */}
          <div>
            <div className="flex items-center justify-between mb-1">
              <span className="text-xs text-forge-gray">Opacity</span>
              <span className="text-xs font-mono text-slag-amber">{Math.round(shadowOpacity * 100)}%</span>
            </div>
            <input
              type="range"
              min="0"
              max="100"
              value={shadowOpacity * 100}
              onChange={(e) => onShadowChange('opacity', Number(e.target.value) / 100)}
              className="slider w-full"
            />
          </div>
        </div>
      )}
    </div>
  )
}
