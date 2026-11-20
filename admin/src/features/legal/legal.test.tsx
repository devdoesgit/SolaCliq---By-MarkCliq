import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, within } from '@testing-library/react';
import { createMemoryRouter, RouterProvider } from 'react-router';
import { describe, expect, it } from 'vitest';
import { routes } from '../../router';

function open(path: string) {
  const router = createMemoryRouter(routes, { initialEntries: [path] });
  render(
    <QueryClientProvider client={new QueryClient()}>
      <RouterProvider router={router} />
    </QueryClientProvider>,
  );
}

describe('legal pages', () => {
  it.each([
    ['/terms', 'SolaCliq Terms of Use'],
    ['/privacy', 'SolaCliq Privacy Policy'],
    ['/company-terms', 'SolaCliq Company Terms'],
  ])('%s shows its document without logging in', (path, heading) => {
    open(path);
    expect(screen.getByRole('heading', { level: 1, name: heading })).toBeInTheDocument();
  });

  it('links between documents go to their pages', () => {
    open('/terms');
    const article = screen.getByRole('article');
    expect(within(article).getByRole('link', { name: 'Privacy Policy' })).toHaveAttribute(
      'href',
      '/privacy',
    );
    expect(within(article).getByRole('link', { name: 'Company Terms' })).toHaveAttribute(
      'href',
      '/company-terms',
    );
  });

  it('marks the open document in the menu', () => {
    open('/privacy');
    const nav = screen.getByRole('navigation', { name: 'Legal documents' });
    expect(within(nav).getByRole('link', { name: 'Privacy Policy' })).toHaveAttribute(
      'aria-current',
      'page',
    );
  });
});
