import { API_BASE } from './client';
export async function exportSingle(id: string, format='png') {
  const res = await fetch(`${API_BASE}/export/${id}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ format, quality: 95, apply_refinements: true }) });
  return res.blob();
}
export async function exportBatch(image_ids: string[], format='png') {
  const res = await fetch(`${API_BASE}/export/batch`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ image_ids, format, apply_refinements: true }) });
  return res.blob();
}
