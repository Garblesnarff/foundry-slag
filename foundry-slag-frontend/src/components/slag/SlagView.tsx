import { useState } from 'react';
import { removeSingle } from '../../api/remove';
import { refineImage } from '../../api/refine';
import Dropzone from './Dropzone';
import ResultPreview from './ResultPreview';
import RefinementPanel from './RefinementPanel';
import ExportBar from './ExportBar';
import type { RefinementSettings } from '../../types';

const defaultRef: RefinementSettings = { edge_feather: 0, edge_shift: 0, bg_type: 'transparent', bg_color: '#FFFFFF', bg_image_path: null, shadow_enabled: false, shadow_opacity: 0.3, shadow_offset_x: 5, shadow_offset_y: 5, shadow_blur: 10 };

export default function SlagView() {
  const [image, setImage] = useState<any | null>(null);
  const [settings, setSettings] = useState<RefinementSettings>(defaultRef);
  const [format, setFormat] = useState('png');
  const onFiles = async (files: File[]) => { if (!files[0]) return; const res = await removeSingle(files[0]); setImage(res.image); };
  const onRefine = async (s: RefinementSettings) => { setSettings(s); if (image) await refineImage(image.id, s); };
  return <div className="grid grid-cols-5 gap-4 p-4"> <div className="col-span-3">{image ? <ResultPreview original={`http://localhost:3458${image.original_url}`} result={`http://localhost:3458${image.result_url}`} /> : <Dropzone onFiles={onFiles} />}</div><div className="col-span-2 space-y-4"><RefinementPanel settings={settings} onChange={onRefine} /><ExportBar format={format} setFormat={setFormat} onExport={()=>{}} /></div></div>;
}
