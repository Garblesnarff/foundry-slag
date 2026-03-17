import { useEffect, useState } from 'react';
import { getSettings, patchSettings } from '../../api/settings';

export default function SettingsPanel() {
  const [settings, setSettings] = useState<any>(null);
  useEffect(()=>{ getSettings().then(setSettings).catch(()=>{}); },[]);
  if (!settings) return <div className="card">Loading settings...</div>;
  return <div className="card space-y-2"><h3 className="mono">SETTINGS</h3><select value={settings.model} onChange={async e=>setSettings(await patchSettings({model:e.target.value}))}><option>u2net</option><option>u2netp</option><option>u2net_human_seg</option><option>isnet-general-use</option><option>isnet-anime</option><option>silueta</option></select></div>;
}
