import { ReactNode } from 'react';
export default function ForgeButton({ children, ...props }: { children: ReactNode } & React.ButtonHTMLAttributes<HTMLButtonElement>) { return <button className="forge-btn" {...props}>{children}</button>; }
