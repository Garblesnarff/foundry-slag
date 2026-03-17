import { useState } from 'react';
import BatchView from './components/batch/BatchView';
import HistoryView from './components/history/HistoryView';
import StatusBar from './components/layout/StatusBar';
import TitleBar from './components/layout/TitleBar';
import SettingsPanel from './components/settings/SettingsPanel';
import SlagView from './components/slag/SlagView';

export default function App() {
  const [tab, setTab] = useState<'slag'|'batch'|'history'>('slag');
  return <div className="min-h-screen flex flex-col"><TitleBar tab={tab} onTab={setTab} model="u2net" /><main className="flex-1">{tab==='slag'&&<SlagView />}{tab==='batch'&&<BatchView />}{tab==='history'&&<HistoryView />}</main><div className="p-4"><SettingsPanel /></div><StatusBar status="Pure gold." /></div>;
}
