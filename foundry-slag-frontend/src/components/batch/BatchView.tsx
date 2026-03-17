import { useEffect, useMemo, useState } from 'react';
import { API_BASE } from '../../api/client';
import { getBatch, removeBatch } from '../../api/remove';
import { useSSE } from '../../hooks/useSSE';
import type { Job, ProcessedImage } from '../../types';
import Dropzone from '../slag/Dropzone';
import BatchGrid from './BatchGrid';
import BatchProgress from './BatchProgress';

export default function BatchView() {
  const [job, setJob] = useState<Job | null>(null);
  const [images, setImages] = useState<ProcessedImage[]>([]);
  const sseUrl = useMemo(() => (job ? `${API_BASE}/remove/batch/${job.id}/progress` : null), [job]);

  const refresh = async (jobId: string) => {
    const data = await getBatch(jobId);
    setJob(data.job);
    setImages(data.images || []);
  };

  const onFiles = async (files: File[]) => {
    const res = await removeBatch(files);
    setJob(res.job);
    setImages([]);
  };

  useSSE(sseUrl, (_evt, type) => {
    if (!job?.id) return;
    if (type === 'image_complete' || type === 'image_failed' || type === 'batch_complete') {
      void refresh(job.id);
    }
  });

  useEffect(() => {
    if (!job?.id) return;
    void refresh(job.id);
  }, [job?.id]);

  return (
    <div className="p-4 space-y-4">
      <Dropzone onFiles={onFiles} />
      {job && <BatchProgress completed={job.completed_images} total={job.total_images} />}
      <BatchGrid items={images} />
    </div>
  );
}
