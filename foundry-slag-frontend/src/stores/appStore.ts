import { useState } from 'react';
import type { ProcessedImage } from '../types';

export type AppTab = 'slag' | 'batch' | 'history';

export function useAppStore() {
  const [tab, setTab] = useState<AppTab>('slag');
  const [currentImage, setCurrentImage] = useState<ProcessedImage | null>(null);
  const [batchJobId, setBatchJobId] = useState<string | null>(null);
  return { tab, setTab, currentImage, setCurrentImage, batchJobId, setBatchJobId };
}
