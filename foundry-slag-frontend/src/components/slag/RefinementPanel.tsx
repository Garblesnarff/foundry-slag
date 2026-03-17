import type { RefinementSettings } from '../../types';
import BackgroundPicker from './BackgroundPicker';
import ShadowControls from './ShadowControls';

export default function RefinementPanel({ settings, onChange }: { settings: RefinementSettings; onChange: (s: RefinementSettings)=>void }) {
  return <div className="card space-y-4"><h3 className="mono">EDGE REFINEMENT</h3><input type="range" min={0} max={10} step={0.1} value={settings.edge_feather} onChange={e=>onChange({...settings, edge_feather:+e.target.value})} /><input type="range" min={-5} max={5} step={0.1} value={settings.edge_shift} onChange={e=>onChange({...settings, edge_shift:+e.target.value})} /><h3 className="mono">BACKGROUND</h3><BackgroundPicker color={settings.bg_color} onChange={(bg_color)=>onChange({...settings,bg_type:'color',bg_color})} /><h3 className="mono">DROP SHADOW</h3><ShadowControls settings={settings} onChange={onChange} /></div>;
}
