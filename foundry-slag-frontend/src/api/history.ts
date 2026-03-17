import { api } from './client';
export const getHistory = (search='') => api<any>(`/history?search=${encodeURIComponent(search)}`);
export const getHistoryStats = () => api<any>('/history/stats');
export const deleteHistoryItem = (id: string) => api<any>(`/history/${id}`, { method: 'DELETE' });
