import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { Link } from 'react-router';
import { api } from '../../api/client';
import { unwrap } from '../../api/problem';
import { Button, Notice } from '../../components';
import { AuthFrame } from './AuthLayout';
import { meQueryKey, useLogout, type Me } from './session';

/*
  Before you start (F16), on the website
  ----------------------------------------------------------------------
  - stands in for every signed-in screen until the current terms are
    agreed to, as the app's screen does
*/
export function TermsGate({ me }: { me: Me }) {
  const client = useQueryClient();
  const logout = useLogout();
  const [agreed, setAgreed] = useState(false);
  const accept = useMutation({
    mutationFn: () =>
      unwrap(api.POST('/me/terms', { body: { version: me.terms.current_version } })),
    onSuccess: () => client.invalidateQueries({ queryKey: meQueryKey }),
  });
  return (
    <AuthFrame>
      <h1 className="auth-title">Before you start</h1>
      <p>
        Read the{' '}
        <Link to="/terms" target="_blank" rel="noreferrer">
          Terms of Use
        </Link>{' '}
        and{' '}
        <Link to="/privacy" target="_blank" rel="noreferrer">
          Privacy Policy
        </Link>
        . They say what is stored, why, and who sees it.
      </p>
      <label className="option">
        <input type="checkbox" checked={agreed} onChange={(e) => setAgreed(e.target.checked)} />
        <span>I agree to the Terms of Use and Privacy Policy</span>
      </label>
      {accept.error && <Notice tone="danger" announce title="Couldn't save that. Try again." />}
      <div className="actions">
        <Button
          variant="primary"
          disabled={!agreed || accept.isPending}
          onClick={() => accept.mutate()}
        >
          Continue
        </Button>
        <Button onClick={() => logout.mutate()} disabled={logout.isPending}>
          Log out
        </Button>
      </div>
    </AuthFrame>
  );
}
