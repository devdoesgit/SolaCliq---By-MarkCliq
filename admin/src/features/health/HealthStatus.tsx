import { Button, Notice, StatusPill } from '../../components';
import { useHealth } from './useHealth';

/** Whether the API and its database are up, with a retry when unreachable. */
export function HealthStatus() {
  const { data, isPending, isError, refetch, isFetching } = useHealth();

  if (isPending) {
    return <p className="t-label muted">Checking the server</p>;
  }
  if (isError) {
    return (
      <Notice
        tone="danger"
        title="Can't reach the server"
        body="Check your internet connection and try again."
        announce
        action={
          <Button compact onClick={() => void refetch()} disabled={isFetching}>
            Try again
          </Button>
        }
      />
    );
  }
  const ok = data.status === 'ok' && data.database === 'ok';
  return (
    <div className="stack" style={{ gap: 'var(--space-2)', alignItems: 'flex-start' }}>
      <StatusPill
        label={ok ? 'Server ok' : 'Database unavailable'}
        tone={ok ? 'success' : 'warning'}
      />
      <p className="t-label muted">Version {data.version}</p>
    </div>
  );
}
