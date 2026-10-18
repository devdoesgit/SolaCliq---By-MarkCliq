import { useState, type FormEvent } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router';
import { Button, Notice, TextField } from '../components';
import { AuthError } from '../features/auth/authErrors';
import { AuthLayout } from '../features/auth/AuthLayout';
import { PasswordField } from '../features/auth/PasswordField';
import { useLogin } from '../features/auth/session';
import { safeNextPath, validateEmail, validateExistingPassword } from '../features/auth/validators';

export function LoginPage() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const login = useLogin();
  const [email, setEmail] = useState(params.get('email') ?? '');
  const [password, setPassword] = useState('');
  const [errors, setErrors] = useState<{ email?: string; password?: string }>({});

  const passwordChanged = params.get('notice') === 'reset';

  function edited() {
    if (login.isError) login.reset();
    if (errors.email || errors.password) setErrors({});
  }

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const next = {
      email: validateEmail(email),
      password: validateExistingPassword(password),
    };
    setErrors(next);
    if (next.email || next.password) return;
    login.mutate(
      { email: email.trim(), password },
      { onSuccess: () => navigate(safeNextPath(params.get('next')), { replace: true }) },
    );
  }

  const failure = login.error instanceof AuthError ? login.error : null;

  return (
    <AuthLayout
      title="Log in"
      intro="For solar vendors using SolaCliq, and the MarkCliq team."
      onSubmit={submit}
      notice={
        failure ? (
          <Notice tone="danger" title={failure.message} announce />
        ) : passwordChanged ? (
          <Notice tone="success" title="Password changed. Log in with your new password." />
        ) : null
      }
      actions={
        <>
          <Button type="submit" variant="primary" block disabled={login.isPending}>
            Log in
          </Button>
          <Link
            className="t-label"
            to={email.trim() ? `/forgot?email=${encodeURIComponent(email.trim())}` : '/forgot'}
          >
            Forgot password?
          </Link>
        </>
      }
    >
      <TextField
        label="Email"
        type="email"
        autoComplete="email"
        value={email}
        error={errors.email}
        onChange={(e) => {
          setEmail(e.target.value);
          edited();
        }}
      />
      <PasswordField
        label="Password"
        autoComplete="current-password"
        maxLength={128}
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
