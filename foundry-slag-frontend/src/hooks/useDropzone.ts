import { useCallback, useState } from 'react';
import type { DragEvent } from 'react';

export function useDropzone(onFiles: (files: File[]) => void) {
  const [dragging, setDragging] = useState(false);

  const onDrop = useCallback(
    (e: DragEvent) => {
      e.preventDefault();
      setDragging(false);
      onFiles(Array.from(e.dataTransfer.files));
    },
    [onFiles]
  );

  return {
    dragging,
    bind: {
      onDragOver: (e: DragEvent) => {
        e.preventDefault();
        setDragging(true);
      },
      onDragLeave: () => setDragging(false),
      onDrop
    }
  };
}
