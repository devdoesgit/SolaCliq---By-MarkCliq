import { toneClass, type Tone } from './tone';

export interface StatusPillProps {
  /** The status word, sentence case; shown in uppercase. */
  label: string;
  tone?: Tone;
}

/** A short status such as "Approved", on its tone's tint. */
export function StatusPill({ label, tone = 'neutral' }: StatusPillProps) {
  return <span className={`sc-pill t-label ${toneClass(tone)}`}>{label}</span>;
}
