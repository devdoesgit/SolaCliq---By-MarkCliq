import type { ReactNode } from 'react';
import { ApiProblem } from '../api/problem';
import { Button } from './Button';
import { Notice } from './Notice';

interface Query<T> {
  data: T | undefined;
  error: Error | null;
  refetch: () => unknown;
}

/*
  A read's loading, not found and failed states
  ----------------------------------------------------------------------
  - once there is data it stays on screen: a failed refresh only says so
    above it, so nothing typed below is lost
*/
export function QueryState<T>({
  query,
  children,
}: {
  query: Query<T>;
  children: (data: T) => ReactNode;
}) {
  const { data, error } = query;
  if (data === undefined && !error) {
    return (
      <p className="t-label muted loading" role="status">
        Loading
      </p>
    );
  }
  const problem = error instanceof ApiProblem ? error : null;
  const failed = error && (
    <Notice
      tone="danger"
      announce
      title={problem?.status === 404 ? 'Not found' : "Couldn't load this"}
      body={
        problem?.status === 404
          ? 'It may be another company’s, or the link is wrong.'
          : (problem?.message ?? 'Something went wrong. Try again.')
      }
      action={
        problem?.status === 404 ? undefined : (
          <Button compact onClick={() => void query.refetch()}>
            Try again
          </Button>
        )
      }
    />
  );
  return (
    <>
      {failed}
      {data !== undefined && children(data)}
    </>
  );
}
