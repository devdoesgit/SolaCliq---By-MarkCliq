import { useEffect } from 'react';
import { Link } from 'react-router';
import { APP_NAME } from '../../config';
import './legal.css';

/*
  How to delete an account (F18), readable without logging in
  ----------------------------------------------------------------------
  - Google Play asks for this page: someone without the app must still
    have a way
*/
export function DeleteAccountPage() {
  useEffect(() => {
    const before = document.title;
    document.title = `Delete your account · ${APP_NAME}`;
    return () => {
      document.title = before;
    };
  }, []);

  return (
    <main className="page legal-page">
      <nav className="legal-nav t-label" aria-label="Legal documents">
        <span className="muted">{APP_NAME} · MarkCliq</span>
        <Link to="/privacy">Privacy Policy</Link>
        <Link to="/terms">Terms of Use</Link>
      </nav>
      <article className="legal-body">
        <h1>Delete your {APP_NAME} account</h1>
        <h2>In the app</h2>
        <p>
          Open Profile, tap &ldquo;Delete account&rdquo; under Log out, and enter your password. It
          happens at once and can&rsquo;t be undone.
        </p>
        <h2>Without the app</h2>
        <p>
          Write to{' '}
          <a href="mailto:info@markcliq.com?subject=Delete%20my%20account">info@markcliq.com</a>{' '}
          from your account&rsquo;s email. We delete it within 30 days. A company&rsquo;s admin
          writes to us too, as a company can&rsquo;t be left without one.
        </p>
        <h2>What is deleted</h2>
        <p>
          Your login, email, phone, personal and bank details, settings, notifications, quote
          requests and your agreements to our terms.
        </p>
        <h2>What stays</h2>
        <p>
          A solar company&rsquo;s records of work you did for it, or of your install, belong to that
          company and keep your name. Ask the company about those, or write to us and we pass it on.
        </p>
      </article>
    </main>
  );
}
