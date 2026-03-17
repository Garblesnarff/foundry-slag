import { useEffect, useState } from 'react';
import { getHistory, getHistoryStats } from '../../api/history';
import HistoryStats from './HistoryStats';
import HistoryFilters from './HistoryFilters';
import HistoryGrid from './HistoryGrid';

export default function HistoryView() {
  const [search, setSearch] = useState('');
  const [stats, setStats] = useState<any>(null);
  const [items, setItems] = useState<any[]>([]);
  useEffect(() => { getHistoryStats().then(setStats).catch(()=>{}); }, []);
  useEffect(() => { getHistory(search).then((r)=>setItems(r.images||[])).catch(()=>{}); }, [search]);
  return <div className="p-4 space-y-4"><h2 className="title">Forge History</h2><HistoryStats stats={stats} /><HistoryFilters search={search} setSearch={setSearch} /><HistoryGrid items={items} /></div>;
}
