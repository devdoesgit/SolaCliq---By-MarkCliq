import type { ReactNode } from 'react';
import { Link } from 'react-router';

export type Dot = 'sun' | 'success' | 'danger' | 'tan' | 'quiet';

/** A number the screen leads with, and where it goes. */
export function Stat({
  label,
  value,
  sub,
  dot,
  to,
}: {
  label: string;
  value: ReactNode;
  sub?: string;
  dot: Dot;
  to?: string;
}) {
  const inside = (
    <>
      <span className="stat-label">
        <span className={`dot dot-${dot}`} aria-hidden="true" />
        {label}
      </span>
      <span className="stat-value">{value}</span>
      {sub && <span className="cell-sub">{sub}</span>}
    </>
  );
  return to ? (
    <Link className="stat" to={to}>
      {inside}
    </Link>
  ) : (
    <div className="stat">{inside}</div>
  );
}
