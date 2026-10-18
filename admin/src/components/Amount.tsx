import { formatPaise } from '../lib/format';

export type AmountTone = 'normal' | 'credit' | 'due';

export interface AmountProps {
  /** Paise. Credits are passed positive and shown negative. */
  paise: number | bigint;
  tone?: AmountTone;
  /** The one headline figure on a page. */
  large?: boolean;
}

const abs = (v: number | bigint) => (v < 0 ? -v : v);

/** An amount of money from integer paise: ₹1,85,000.00. */
export function Amount({ paise, tone = 'normal', large = false }: AmountProps) {
  const value = tone === 'credit' ? -abs(paise) : paise;
  return (
    <span className={`${large ? 't-num-lg' : 't-num'} sc-amt-${tone}`}>{formatPaise(value)}</span>
  );
}

export interface SummaryLine {
  label: string;
  paise: number | bigint;
  tone?: AmountTone;
}

/** A cost breakdown: labelled amounts, then the total under a 1px ink rule. */
export function AmountSummary({ lines, total }: { lines: SummaryLine[]; total: SummaryLine }) {
  return (
    <dl className="sc-sum">
      {lines.map((line) => (
        <div key={line.label} style={{ display: 'contents' }}>
          <dt>{line.label}</dt>
          <dd>
            <Amount paise={line.paise} tone={line.tone} />
          </dd>
        </div>
      ))}
      <dt className="sc-sum-total">{total.label}</dt>
      <dd className="sc-sum-total">
        <Amount paise={total.paise} tone={total.tone} />
      </dd>
    </dl>
  );
}
