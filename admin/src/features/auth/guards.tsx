import { Navigate, Outlet, useLocation } from 'react-router';
import { Button, Notice } from '../../components';
import { useMe } from './session';

function Loading() {
  return (
    <main className="page">
      <p className="t-label muted" role="status">
        Loading
      </p>
    </main>
  );
}

function SessionError({ retry }: { retry: () => void }) {
  return (
    <main className="page">
      <Notice
        tone="danger"
        title="Can't reach the server"
        body="Check your internet connection and try again."
        announce
        action={
          <Button compact onClick={retry}>
            Try again
          </Button>
        }
      />
    </main>
  );
}

/** Pages for signed-in people. Others go to log in, and come back after. */
export function RequireSession() {
  const { data: me, isPending, isError, refetch } = useMe();
  const location = useLocation();
  if (isPending) return <Loading />;
  if (isError) return <SessionError retry={() => void refetch()} />;
  if (!me) {
    const next = `${location.pathname}${location.search}`;
    const to = next === '/' ? '/login' : `/login?next=${encodeURIComponent(next)}`;
    return <Navigate to={to} replace />;
  }
  return <Outlet />;
}

/** Log in and password pages. Signed-in people go home instead. */
export function PublicOnly() {
  const { data: me, isPending, isError, refetch } = useMe();
  if (isPending) return <Loading />;
  if (isError) return <SessionError retry={() => void refetch()} />;
  if (me) return <Navigate to="/" replace />;
  return <Outlet />;
}
