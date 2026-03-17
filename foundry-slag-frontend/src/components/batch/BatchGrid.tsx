import BatchItem from './BatchItem';
export default function BatchGrid({ items }: { items: any[] }) { return <div className="grid grid-cols-4 gap-3">{items.map(i=><BatchItem key={i.id} item={i} />)}</div>; }
