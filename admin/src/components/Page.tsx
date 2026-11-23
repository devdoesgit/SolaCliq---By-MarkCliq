import { useEffect, type ReactNode } from 'react';
import { Link } from 'react-router';
import { APP_NAME } from '../config';
import { Icon } from './Icon';

/** A screen's top: a line of where you are, its title, and on the right the actions. */
export function PageHeader({
  title,
  meta,
  back,
  actions,
}: {
  title: string;
  meta?: ReactNode;
  back?: { to: string; label: string };
  actions?: ReactNode;
}) {
  useEffect(() => {
    document.title = `${title} · ${APP_NAME}`;
    return () => {
      document.title = APP_NAME;
    };
  }, [title]);
  return (
    <header className="page-head">
      <div className="page-head-main">
        {meta && <div className="page-meta">{meta}</div>}
        <h1 className="page-title">{title}</h1>
      </div>
      {(back || actions) && (
        <div className="actions">
          {back && (
            <Link className="sc-btn sc-btn-outline sc-btn-compact" to={back.to}>
              <Icon name="back" size={16} />
              <span>{back.label}</span>
            </Link>
          )}
          {actions}
        </div>
      )}
    </header>
  );
}

/** A white card with its heading; `aside` is the quiet line on its right. */
export function Section({
  title,
  aside,
  actions,
  className,
  children,
}: {
  title: string;
  aside?: ReactNode;
  actions?: ReactNode;
  className?: string;
  children: ReactNode;
}) {
  return (
    <section className={className ? `card ${className}` : 'card'} aria-label={title}>
      <div className="card-head">
        <h2 className="card-title">{title}</h2>
        {aside && <div className="card-aside">{aside}</div>}
        {actions && <div className="actions">{actions}</div>}
      </div>
      {children}
    </section>
  );
}

/** Labelled facts. Those with nothing to show are left out. */
export function Facts({ items }: { items: [string, ReactNode][] }) {
  return (
    <dl className="facts">
      {items
        .filter(([, value]) => value !== undefined && value !== null && value !== '')
        .map(([label, value]) => (
          <div key={label}>
            <dt>{label}</dt>
            <dd>{value}</dd>
          </div>
        ))}
    </dl>
  );
}
