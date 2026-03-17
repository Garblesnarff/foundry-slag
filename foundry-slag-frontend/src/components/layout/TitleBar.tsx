import type { AppTab } from '../../stores/appStore';

export default function TitleBar({ tab, onTab, model }: { tab: AppTab; onTab: (t: AppTab)=>void; model: string }) {
  const tabs: AppTab[] = ['slag', 'batch', 'history'];
  return <header className="h-12 px-4 flex items-center justify-between border-b" style={{background:'var(--bg-titlebar)',borderColor:'var(--border)'}}>
    <div className="flex items-center gap-3"><span>● ● ●</span><strong>[F] FOUNDRY SLAG</strong></div>
    <nav className="flex gap-2">{tabs.map(t=><button key={t} onClick={()=>onTab(t)} className="px-3 py-1 rounded" style={{background:tab===t?'var(--bg-card)':'transparent'}}>{t[0].toUpperCase()+t.slice(1)}</button>)}</nav>
    <div className="mono text-xs">{model} · CPU · Apple Silicon ⚙</div>
  </header>;
}
