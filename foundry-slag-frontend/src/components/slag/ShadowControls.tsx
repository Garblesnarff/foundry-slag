import type { RefinementSettings } from '../../types';
export default function ShadowControls({ settings, onChange }: { settings: RefinementSettings; onChange: (s: RefinementSettings)=>void }) {
  return <div className="space-y-2"><label><input type="checkbox" checked={settings.shadow_enabled} onChange={e=>onChange({...settings, shadow_enabled:e.target.checked})} /> Enable Shadow</label><input type="range" min={0} max={1} step={0.05} value={settings.shadow_opacity} onChange={e=>onChange({...settings, shadow_opacity:+e.target.value})} /></div>;
}
