import { Link } from 'react-router';
import { APP_NAME, SHOW_DEV_TOOLS } from '../config';
import { HealthStatus } from '../features/health/HealthStatus';

/** Start page until log in arrives in F1. */
export function HomePage() {
  return (
    <main className="page stack" style={{ gap: 'var(--space-8)' }}>
      <header className="stack" style={{ gap: 'var(--space-4)' }}>
        <p className="t-label muted">MarkCliq</p>
        <h1 className="t-display">{APP_NAME}</h1>
        <p className="muted" style={{ maxWidth: '36rem' }}>
          The admin website for solar vendors is being built.
        </p>
      </header>
      <HealthStatus />
      {SHOW_DEV_TOOLS && (
        <p>
          <Link className="sc-btn sc-btn-secondary" to="/gallery">
            <span>Component gallery</span>
          </Link>
        </p>
      )}
    </main>
  );
}
