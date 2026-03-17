import { api } from './client';
export const removeSingle = async (file: File, model='u2net', alpha_matting=false) => {
  const fd = new FormData(); fd.append('file', file); fd.append('model', model); fd.append('alpha_matting', String(alpha_matting));
  return api<{image: any}>('/remove', { method: 'POST', body: fd });
};
export const removeBatch = async (files: File[], model='u2net', alpha_matting=false) => {
  const fd = new FormData(); files.forEach((f)=>fd.append('files', f)); fd.append('model', model); fd.append('alpha_matting', String(alpha_matting));
  return api<{job: any}>('/remove/batch', { method: 'POST', body: fd });
};
export const getBatch = (jobId: string) => api<any>(`/remove/batch/${jobId}`);
