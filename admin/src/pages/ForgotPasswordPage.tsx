import { useState, type FormEvent } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router';
import { Button, Notice, TextField } from '../components';
import { AuthError } from '../features/auth/authErrors';
import { AuthLayout } from '../features/auth/AuthLayout';
import { useRequestPasswordReset } from '../features/auth/session';
import { validateEmail } from '../features/auth/validators';

export function ForgotPasswordPage() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const request = useRequestPasswordReset();
  const [email, setEmail] = useState(params.get('email') ?? '');
  const [error, setError] = useState<string>();

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const problem = validateEmail(email);
    setError(problem);
    if (problem) return;
    const address = email.trim();
    request.mutate(
      { email: address },
      { onSuccess: () => navigate(`/reset?email=${encodeURIComponent(address)}`) },
    );
  }

  const failure = request.error instanceof AuthError ? request.error : null;

  return (
    <AuthLayout
      title="Reset password"
      intro="Enter your email. If it has an account, we'll send a 6-digit code."
      onSubmit={submit}
      notice={failure && <Notice tone="danger" title={failure.message} announce />}
      actions={
        <>
          <Button type="submit" variant="primary" block disabled={request.isPending}>
            Send code
          </Button>
          <Link className="t-label" to="/login">
            Back to log in
          </Link>
        </>
      }
    >
      <TextField
        label="Email"
        type="email"
        autoComplete="email"
        value={email}
        error={error}
        onChange={(e) => {
          setEmail(e.target.value);
          if (request.isError) request.reset();
          if (error) setError(undefined);
        }}
      />
    </AuthLayout>
  );
}
