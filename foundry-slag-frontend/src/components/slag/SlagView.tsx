import { useState } from 'react';
import { exportSingle } from '../../api/export';
import { refineImage } from '../../api/refine';
import { removeSingle } from '../../api/remove';
import type { RefinementSettings } from '../../types';
import Dropzone from './Dropzone';
import ExportBar from './ExportBar';
import RefinementPanel from './RefinementPanel';
import ResultPreview from './ResultPreview';

const defaultRef: RefinementSettings = {
  edge_feather: 0,
  edge_shift: 0,
  bg_type: 'transparent',
  bg_color: '#FFFFFF',
  bg_image_path: null,
  shadow_enabled: false,
  shadow_opacity: 0.3,
  shadow_offset_x: 5,
  shadow_offset_y: 5,
  shadow_blur: 10
};

export default function SlagView() {
  const [image, setImage] = useState<{ id: string; original_url: string; result_url: string } | null>(null);
  const [settings, setSettings] = useState<RefinementSettings>(defaultRef);
  const [format, setFormat] = useState('png');
  const [busy, setBusy] = useState(false);

  const onFiles = async (files: File[]) => {
    if (!files[0]) return;
    setBusy(true);
    try {
      const res = await removeSingle(files[0]);
      setImage(res.image);
    } finally {
      setBusy(false);
    }
  };

  const onRefine = async (s: RefinementSettings) => {
    setSettings(s);
    if (!image) return;
    setBusy(true);
    try {
      await refineImage(image.id, s);
      setImage({ ...image });
    } finally {
      setBusy(false);
    }
  };

  const onExport = async () => {
    if (!image) return;
    const blob = await exportSingle(image.id, format);
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `slagged.${format}`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="grid grid-cols-5 gap-4 p-4">
      <div className="col-span-3 relative">
        {image ? (
          <ResultPreview original={`http://localhost:3458${image.original_url}`} result={`http://localhost:3458${image.result_url}`} />
        ) : (
          <Dropzone onFiles={onFiles} />
        )}
        {busy && <div className="absolute inset-0 bg-black/40 grid place-items-center mono">Slagging...</div>}
      </div>
      <div className="col-span-2 space-y-4">
        <RefinementPanel settings={settings} onChange={onRefine} />
        <ExportBar format={format} setFormat={setFormat} onExport={onExport} />
      </div>
    </div>
  );
}
