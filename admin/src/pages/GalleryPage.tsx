import { useState, type ReactNode } from 'react';
import { Link } from 'react-router';
import {
  Amount,
  AmountSummary,
  Button,
  ListRow,
  Notice,
  StageTracker,
  StatusPill,
  TextField,
} from '../components';
import { HealthStatus } from '../features/health/HealthStatus';

/**
 * Every component, for checking them in a browser. Development only. All
 * data here is illustrative.
 */
export function GalleryPage() {
  const [tapped, setTapped] = useState<string | null>(null);
  const tap = (what: string) => () => setTapped(what);

  return (
    <main className="page stack" style={{ gap: 'var(--space-12)' }}>
      <header className="stack" style={{ gap: 'var(--space-4)' }}>
        <Link to="/" className="t-label">
          Back
        </Link>
        <h1 className="t-display">Components</h1>
      </header>

      <Notice title="Illustrative" body="Names, amounts and dates on this page are not real." />
      <HealthStatus />
      <p className="t-label muted" aria-live="polite">
        {tapped ? `Clicked: ${tapped}` : 'Click a control to try it.'}
      </p>

      <Section title="Buttons">
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--space-3)' }}>
          <Button variant="primary" onClick={tap('Save expense')}>
            Save expense
          </Button>
          <Button onClick={tap('Add photo')}>Add photo</Button>
          <Button variant="ghost" onClick={tap('Cancel')}>
            Cancel
          </Button>
          <Button variant="danger" onClick={tap('Delete receipt')}>
            Delete receipt
          </Button>
          <Button disabled>Submit (disabled)</Button>
          <Button compact onClick={tap('Compact')}>
            Compact
          </Button>
        </div>
      </Section>

      <Section title="Text fields">
        <div className="stack" style={{ gap: 'var(--space-6)' }}>
          <TextField
            label="Customer name"
            placeholder="Full name"
            help="As on the electricity bill"
          />
          <TextField label="Amount" placeholder="0.00" numeric />
          <TextField label="Meter number" error="Enter the meter number." />
        </div>
      </Section>

      <Section title="Status pills">
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--space-2)' }}>
          <StatusPill label="Draft" />
          <StatusPill label="Approved" tone="success" />
          <StatusPill label="Flagged" tone="warning" />
          <StatusPill label="Rejected" tone="danger" />
          <StatusPill label="Pending" tone="info" />
          <StatusPill label="Current" tone="accent" />
        </div>
      </Section>

      <Section title="Stage tracker">
        <StageTracker
          stages={[
            { name: 'Lead', state: 'done', date: new Date(2026, 9, 2) },
            { name: 'Site survey', state: 'done', date: new Date(2026, 9, 9) },
            { name: 'Quote', state: 'current', date: new Date(2026, 9, 18) },
            { name: 'Subsidy paperwork', state: 'upcoming' },
            { name: 'Install', state: 'upcoming' },
            { name: 'Net metering', state: 'upcoming' },
            { name: 'Service', state: 'upcoming' },
          ]}
        />
      </Section>

      <Section title="List rows">
        <ul className="sc-list" style={{ maxWidth: '40rem' }}>
          <ListRow
            title="Ramesh Sahoo, 5 kW rooftop"
            meta="Quote · 18 Oct 2026"
            onClick={tap('Ramesh Sahoo')}
            end={
              <>
                <Amount paise={18500000} />
                <StatusPill label="Pending" tone="info" />
              </>
            }
          />
          <ListRow
            title="Sunita Mohanty, 3.3 kW rooftop"
            meta="Install · 12 Oct 2026"
            onClick={tap('Sunita Mohanty')}
            end={
              <>
                <Amount paise={9800000} />
                <StatusPill label="Approved" tone="success" />
              </>
            }
          />
          <ListRow title="Static row, not clickable" meta="Service · 1 Sep 2026" />
        </ul>
      </Section>

      <Section title="Amounts">
        <div className="stack" style={{ gap: 'var(--space-6)' }}>
          <div className="stack" style={{ gap: 'var(--space-1)' }}>
            <span className="t-label muted">Balance due</span>
            <Amount paise={4250000} tone="due" large />
          </div>
          <AmountSummary
            lines={[
              { label: 'Panels and inverter', paise: 21000000 },
              { label: 'Installation', paise: 2500000 },
              { label: 'Subsidy', paise: 7800000, tone: 'credit' },
            ]}
            total={{ label: 'Total', paise: 15700000 }}
          />
        </div>
      </Section>

      <Section title="Notices">
        <div className="stack" style={{ gap: 'var(--space-3)', maxWidth: '40rem' }}>
          <Notice title="Waiting for approval" body="MarkCliq is checking your GSTIN." />
          <Notice
            tone="warning"
            title="No GPS signal"
            body="Move into the open and try again."
            action={
              <Button compact onClick={tap('Retry')}>
                Retry
              </Button>
            }
          />
          <Notice tone="danger" title="Upload failed" body="Check your connection and try again." />
          <Notice tone="success" title="Expense approved" />
        </div>
      </Section>
    </main>
  );
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="stack" style={{ gap: 'var(--space-6)' }}>
      <h2 className="t-h2">{title}</h2>
      {children}
    </section>
  );
}
