import type { ReactNode } from 'react';
import { toneClass, type Tone } from './tone';

export interface NoticeProps {
  /** What happened. */
  title: string;
  /** What to do. */
  body?: string;
  tone?: Exclude<Tone, 'neutral' | 'accent'>;
  /** One action, usually a secondary Button. */
  action?: ReactNode;
  /** Announce to screen readers when it appears (errors). */
  announce?: boolean;
}

/** A message across the page, ruled top and bottom in its tone's colour. */
export function Notice({ title, body, tone = 'info', action, announce = false }: NoticeProps) {
  return (
    <div className={`sc-notice ${toneClass(tone)}`} role={announce ? 'alert' : undefined}>
      <p className="sc-notice-title">{title}</p>
      {body && <p className="sc-notice-body t-body-sm">{body}</p>}
      {action && <div className="sc-notice-action">{action}</div>}
    </div>
  );
}
