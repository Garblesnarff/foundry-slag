import Checkerboard from '../shared/Checkerboard';
import CompareSlider from './CompareSlider';

export default function ResultPreview({ original, result }: { original: string; result: string }) {
  return <Checkerboard><div className="relative h-[420px]"><img src={result} className="absolute inset-0 w-full h-full object-contain" /><img src={original} className="absolute inset-0 w-1/2 h-full object-cover" /><CompareSlider /></div></Checkerboard>;
}
