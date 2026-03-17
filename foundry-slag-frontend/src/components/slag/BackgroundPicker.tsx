import { PRESET_BG_COLORS } from '../../types';

export default function BackgroundPicker({ color, onChange }: { color: string; onChange: (color: string)=>void }) {
  return <div className="space-y-2"><div className="flex gap-2">{PRESET_BG_COLORS.map(c=><button key={c} onClick={()=>onChange(c==='transparent'?'#FFFFFF':c)} className="w-7 h-7 rounded border" style={{background:c==='transparent'?'repeating-conic-gradient(#2A2520 0 25%,#1E1B18 0 50%) 50%/10px 10px':c,borderColor:color===c?'var(--accent-amber)':'var(--border)'}} />)}</div><input value={color} onChange={(e)=>onChange(e.target.value)} /></div>;
}
