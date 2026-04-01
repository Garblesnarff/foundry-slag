/**
 * EdgeControls Component
 * 
 * Sliders for adjusting edge refinement (feather and shift).
 */

interface EdgeControlsProps {
  feather: number
  shift: number
  onFeatherChange: (value: number) => void
  onShiftChange: (value: number) => void
  onApply: () => void
}

export function EdgeControls({ 
  feather, 
  shift, 
  onFeatherChange, 
  onShiftChange,
  onApply 
}: EdgeControlsProps) {
  return (
    <div className="space-y-4">
      {/* Feather slider */}
      <div>
        <div className="flex items-center justify-between mb-2">
          <label className="text-sm text-forge-light">Feather</label>
          <span className="text-xs font-mono text-slag-amber">{feather}px</span>
        </div>
        <input
          type="range"
          min="0"
          max="20"
          value={feather}
          onChange={(e) => onFeatherChange(Number(e.target.value))}
          className="slider w-full"
        />
        <div className="flex justify-between text-xs text-forge-gray mt-1">
          <span>Sharp</span>
          <span>Soft</span>
        </div>
      </div>

      {/* Shift slider */}
      <div>
        <div className="flex items-center justify-between mb-2">
          <label className="text-sm text-forge-light">Shift</label>
          <span className="text-xs font-mono text-slag-amber">{shift > 0 ? `+${shift}` : shift}px</span>
        </div>
        <input
          type="range"
          min="-10"
          max="10"
          value={shift}
          onChange={(e) => onShiftChange(Number(e.target.value))}
          className="slider w-full"
        />
        <div className="flex justify-between text-xs text-forge-gray mt-1">
          <span>Erode</span>
          <span>Dilate</span>
        </div>
      </div>

      {/* Apply button */}
      <button
        onClick={onApply}
        className="btn-secondary w-full mt-4"
      >
        Apply Edge Settings
      </button>
    </div>
  )
}
