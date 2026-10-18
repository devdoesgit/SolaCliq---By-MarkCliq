import type { FormEvent, ReactNode } from 'react';
import { APP_NAME } from '../../config';

export interface AuthLayoutProps {
  title: string;
  intro?: string;
  /** An error or a success message from the last step. */
  notice?: ReactNode;
  onSubmit: (event: FormEvent<HTMLFormElement>) => void;
  /** The fields. */
  children: ReactNode;
  /** The submit button, then any secondary links. */
  actions: ReactNode;
}

/** The narrow, single-column frame shared by the log in and reset pages. */
export function AuthLayout({ title, intro, notice, onSubmit, children, actions }: AuthLayoutProps) {
  return (
    <main className="page auth-page">
      <p className="t-label muted">{APP_NAME} · MarkCliq</p>
      <h1 className="t-display">{title}</h1>
      {intro && <p className="muted auth-intro">{intro}</p>}
      {notice}
      <form className="auth-form" onSubmit={onSubmit} noValidate>
        <div className="auth-fields">{children}</div>
        <div className="auth-actions">{actions}</div>
      </form>
    </main>
  );
}
