import type { ReactNode } from 'react';

export interface Column<T> {
  label: string;
  render: (row: T) => ReactNode;
  /** Right-aligned: amounts. */
  end?: boolean;
}

/** A table that turns into cards on a phone. The first column is the row's name. */
export function DataTable<T>({
  caption,
  columns,
  rows,
  rowKey,
}: {
  caption: string;
  columns: Column<T>[];
  rows: T[];
  rowKey: (row: T) => string;
}) {
  return (
    <table className="table">
      <caption className="visually-hidden">{caption}</caption>
      <thead>
        <tr>
          {columns.map((c) => (
            <th key={c.label} scope="col" className={c.end ? 'table-end' : undefined}>
              {c.label}
            </th>
          ))}
        </tr>
      </thead>
      <tbody>
        {rows.map((row) => (
          <tr key={rowKey(row)}>
            {columns.map((c) => (
              <td key={c.label} data-label={c.label} className={c.end ? 'table-end' : undefined}>
                {c.render(row)}
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
