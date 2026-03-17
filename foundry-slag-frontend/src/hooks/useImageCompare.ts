import { useState } from 'react';
export function useImageCompare() { const [percent, setPercent] = useState(50); return { percent, setPercent }; }
