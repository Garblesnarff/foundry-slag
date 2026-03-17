import { useState } from 'react';
import { removeBatch } from '../../api/remove';
import Dropzone from '../slag/Dropzone';
import BatchProgress from './BatchProgress';
import BatchGrid from './BatchGrid';

export default function BatchView() {
  const [job, setJob] = useState<any | null>(null);
  const [images, setImages] = useState<any[]>([]);
  const onFiles = async (files: File[]) => { const res = await removeBatch(files); setJob(res.job); setImages([]); };
  return <div className="p-4 space-y-4"><Dropzone onFiles={onFiles} />{job && <BatchProgress completed={job.completed_images} total={job.total_images} />}<BatchGrid items={images} /></div>;
}
