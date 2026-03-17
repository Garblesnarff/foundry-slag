import { api } from './client';
export const getSettings = () => api<any>('/settings');
export const patchSettings = (payload: Record<string, unknown>) => api<any>('/settings', { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload) });
