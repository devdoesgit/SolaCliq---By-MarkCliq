import type { FormEvent, ReactNode } from 'react';
import { Link } from 'react-router';
import hero from '../../assets/hero-install.jpg';
import icon from '../../assets/solacliq-icon.svg';
import { APP_NAME } from '../../config';

/** The photo on the left, the work on the right: every screen outside a company. */
export function AuthFrame({ children }: { children: ReactNode }) {
  return (
    <div className="auth">
      <aside className="auth-photo" aria-label="About">
        <img src={hero} alt="" />
        <div className="auth-claim">
          <p className="auth-claim-title">Run every install from one place.</p>
          <p>Tasks, customers, commissions and expenses for your EPC.</p>
        </div>
      </aside>
      <main className="auth-main">
        <p className="auth-brand">
          <img src={icon} alt="" />
          <span>
            {APP_NAME} <span className="auth-brand-for">for EPCs</span>
          </span>
        </p>
        {children}
        <p className="auth-legal">
          <Link to="/terms">Terms of Use</Link> <Link to="/privacy">Privacy Policy</Link>
        </p>
      </main>
    </div>
  );
}

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

/** The frame shared by the log in and reset pages. */
export function AuthLayout({ title, intro, notice, onSubmit, children, actions }: AuthLayoutProps) {
  return (
    <AuthFrame>
      <h1 className="auth-title">{title}</h1>
      {intro && <p className="auth-intro">{intro}</p>}
      {notice}
      <form className="auth-form" onSubmit={onSubmit} noValidate>
        <div className="auth-fields">{children}</div>
        <div className="auth-actions">{actions}</div>
      </form>
    </AuthFrame>
  );
}
