import { useEffect } from 'react';
import { Link } from 'react-router';
import companyTerms from '../../../../legal/company-terms.md?html';
import privacyPolicy from '../../../../legal/privacy-policy.md?html';
import termsOfUse from '../../../../legal/terms-of-use.md?html';
import { APP_NAME } from '../../config';
import './legal.css';

/** SolaCliq's legal documents (F16), public, from `legal/*.md`. */
export const LEGAL_DOCUMENTS = {
  terms: { title: 'Terms of Use', html: termsOfUse },
  privacy: { title: 'Privacy Policy', html: privacyPolicy },
  'company-terms': { title: 'Company Terms', html: companyTerms },
} as const;

export type LegalDocument = keyof typeof LEGAL_DOCUMENTS;

/*
  One document, readable without logging in: the app links here, and so
  will the Play Store listing. The HTML is made from our own files in the
  repo at build time, never from anything a user sent.
*/
export function LegalPage({ document }: { document: LegalDocument }) {
  const { title, html } = LEGAL_DOCUMENTS[document];

  useEffect(() => {
    const before = window.document.title;
    window.document.title = `${title} · ${APP_NAME}`;
    return () => {
      window.document.title = before;
    };
  }, [title]);

  return (
    <main className="page legal-page">
      <nav className="legal-nav t-label" aria-label="Legal documents">
        <span className="muted">{APP_NAME} · MarkCliq</span>
        {(Object.keys(LEGAL_DOCUMENTS) as LegalDocument[]).map((key) => (
          <Link key={key} to={`/${key}`} aria-current={key === document ? 'page' : undefined}>
            {LEGAL_DOCUMENTS[key].title}
          </Link>
        ))}
      </nav>
      <article className="legal-body" dangerouslySetInnerHTML={{ __html: html }} />
    </main>
  );
}
