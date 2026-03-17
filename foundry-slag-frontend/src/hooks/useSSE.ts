import { useEffect } from 'react';

export function useSSE(url: string | null, onEvent: (event: MessageEvent, type: string) => void) {
  useEffect(() => {
    if (!url) return;
    const es = new EventSource(url);
    ['image_complete', 'image_failed', 'batch_complete'].forEach((type) => es.addEventListener(type, (e) => onEvent(e as MessageEvent, type)));
    return () => es.close();
  }, [url, onEvent]);
}
