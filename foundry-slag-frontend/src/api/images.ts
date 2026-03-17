import { API_BASE } from './client';
export const originalUrl = (id: string) => `${API_BASE}/images/${id}/original`;
export const resultUrl = (id: string) => `${API_BASE}/images/${id}/result`;
export const thumbnailUrl = (id: string) => `${API_BASE}/images/${id}/thumbnail`;
