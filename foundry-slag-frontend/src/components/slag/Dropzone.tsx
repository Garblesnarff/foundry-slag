import { useDropzone } from '../../hooks/useDropzone';

export default function Dropzone({ onFiles }: { onFiles: (files: File[])=>void }) {
  const { dragging, bind } = useDropzone(onFiles);
  return <div {...bind} className="card text-center p-12" style={{borderColor:dragging?'var(--accent-amber)':'var(--border)'}}>
    <p className="title">Drop your image into the forge. The slag burns away.</p>
  </div>;
}
