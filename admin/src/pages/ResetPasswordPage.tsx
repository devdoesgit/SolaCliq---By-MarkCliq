import { useState, type FormEvent } from 'react';
import { Link, Navigate, useNavigate, useSearchParams } from 'react-router';
import { Button, Notice, TextField } from '../components';
import { AuthError } from '../features/auth/authErrors';
import { AuthLayout } from '../features/auth/AuthLayout';
import { PasswordField } from '../features/auth/PasswordField';
import { useResetPassword } from '../features/auth/session';
import { validateCode, validateNewPassword } from '../features/auth/validators';

export function ResetPasswordPage() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const reset = useResetPassword();
  const email = params.get('email') ?? '';
  const [code, setCode] = useState('');
  const [password, setPassword] = useState('');
  const [errors, setErrors] = useState<{ code?: string; password?: string }>({});

  if (!email) return <Navigate to="/forgot" replace />;

  function edited() {
    if (reset.isError) reset.reset();
    if (errors.code || errors.password) setErrors({});
  }

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const next = { code: validateCode(code), password: validateNewPassword(password) };
    setErrors(next);
    if (next.code || next.password) return;
    reset.mutate(
      { email, code: code.trim(), new_password: password },
      {
        onSuccess: () =>
          navigate(`/login?email=${encodeURIComponent(email)}&notice=reset`, { replace: true }),
      },
    );
  }

  const failure = reset.error instanceof AuthError ? reset.error : null;

  return (
    <AuthLayout
      title="New password"
      intro={`Enter the code we sent to ${email} and choose a new password.`}
      onSubmit={submit}
      notice={failure && <Notice tone="danger" title={failure.message} announce />}
      actions={
        <>
          <Button type="submit" variant="primary" block disabled={reset.isPending}>
            Save password
          </Button>
          <Link className="t-label" to={`/forgot?email=${encodeURIComponent(email)}`}>
            Send a new code
          </Link>
        </>
      }
    >
      <TextField
        label="6-digit code"
        inputMode="numeric"
        autoComplete="one-time-code"
        maxLength={6}
        numeric
        value={code}
        error={errors.code}
        onChange={(e) => {
          setCode(e.target.value.replace(/\D/g, '').slice(0, 6));
          edited();
        }}
      />
      <PasswordField
        label="New password"
        autoComplete="new-password"
        maxLength={128}
        help="At least 8 characters."
        value={password}
        error={errors.password}
        onChange={(e) => {
          setPassword(e.target.value);
          edited();
        }}
      />
    </AuthLayout>
  );
}
