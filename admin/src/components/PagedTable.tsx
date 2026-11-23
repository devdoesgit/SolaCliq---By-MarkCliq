import { Button } from './Button';
import { DataTable, type Column } from './DataTable';
import { QueryState } from './QueryState';

interface Pages<T> {
  data: { pages: { items: T[] }[] } | undefined;
  error: Error | null;
  refetch: () => unknown;
  hasNextPage: boolean;
  isFetchingNextPage: boolean;
  fetchNextPage: () => unknown;
}

/** A paged list: the rows, what to say when there are none, and Show more. */
export function PagedTable<T>({
  query,
  caption,
  columns,
  rowKey,
  empty,
}: {
  query: Pages<T>;
  caption: string;
  columns: Column<T>[];
  rowKey: (row: T) => string;
  empty: string;
}) {
  return (
    <QueryState query={query}>
      {({ pages }) => {
        const rows = pages.flatMap((page) => page.items);
        if (rows.length === 0) return <p className="empty">{empty}</p>;
        return (
          <>
            <DataTable caption={caption} columns={columns} rows={rows} rowKey={rowKey} />
            {query.hasNextPage && (
              <div className="more">
                <Button
                  compact
                  disabled={query.isFetchingNextPage}
                  onClick={() => void query.fetchNextPage()}
                >
                  Show more
                </Button>
              </div>
            )}
          </>
        );
      }}
    </QueryState>
  );
}
