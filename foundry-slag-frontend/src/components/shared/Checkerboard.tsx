import type { ReactNode } from 'react';

export default function Checkerboard({ children }: { children: ReactNode }) {
  return <div className="checkerboard rounded-xl p-2">{children}</div>;
}
