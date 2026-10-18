import type { ReactNode } from 'react';

export interface ListRowProps {
  title: string;
  /** Second line in the label style: stage, date, ID. */
  meta?: string;
  /** Right-hand side, stacked: an amount, a status pill. */
  end?: ReactNode;
  /** Makes the row a button. For navigation, wrap content in a link instead. */
  onClick?: () => void;
}

/** A row in a list, separated by a 1px rule. Put rows inside <ul className="sc-list">. */
export function ListRow({ title, meta, end, onClick }: ListRowProps) {
  const content = (
    <>
      <span className="sc-row-main">
        <span className="t-title">{title}</span>
        {meta && <span className="t-label muted">{meta}</span>}
      </span>
      {end && <span className="sc-row-end">{end}</span>}
    </>
  );
  return (
    <li>
      {onClick ? (
        <button type="button" className="sc-row" onClick={onClick}>
          {content}
        </button>
      ) : (
        <div className="sc-row">{content}</div>
      )}
    </li>
  );
}
