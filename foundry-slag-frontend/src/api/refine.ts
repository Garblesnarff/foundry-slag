import { api } from './client';
import type { RefinementSettings } from '../types';
export const refineImage = (id: string, payload: RefinementSettings) => api<any>(`/refine/${id}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload) });
export const resetRefine = (id: string) => api<any>(`/refine/${id}/reset`, { method: 'POST' });
