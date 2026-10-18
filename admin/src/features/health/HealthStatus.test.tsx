import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { api } from '../../api/client';
import { HealthStatus } from './HealthStatus';
import { fetchHealth, HealthUnreachableError } from './useHealth';

// The shape openapi-fetch resolves with; cast because its generic types
// can't be named for one path.
const answer = (status: number, body: unknown) =>
  ({
    data: status === 200 ? body : undefined,
    error: status === 200 ? undefined : body,
    response: new Response(null, { status }),
  }) as never;

const healthy = { status: 'ok', version: '0.1.0', database: 'ok' };
const degraded = { status: 'degraded', version: '0.1.0', database: 'unavailable' };

function renderStatus() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  render(
    <QueryClientProvider client={client}>
      <HealthStatus />
    </QueryClientProvider>,
  );
}

afterEach(() => {
  vi.restoreAllMocks();
});

describe('fetchHealth', () => {
  it('returns the report on 200', async () => {
    vi.spyOn(api, 'GET').mockResolvedValue(answer(200, healthy));
    await expect(fetchHealth()).resolves.toEqual(healthy);
  });

  it('treats 503 as a report with the database down', async () => {
    vi.spyOn(api, 'GET').mockResolvedValue(answer(503, degraded));
    await expect(fetchHealth()).resolves.toEqual(degraded);
  });

  it('turns other statuses and network errors into HealthUnreachableError', async () => {
    vi.spyOn(api, 'GET').mockResolvedValueOnce(answer(500, {}));
    await expect(fetchHealth()).rejects.toBeInstanceOf(HealthUnreachableError);
    vi.spyOn(api, 'GET').mockRejectedValueOnce(new TypeError('offline'));
    await expect(fetchHealth()).rejects.toBeInstanceOf(HealthUnreachableError);
  });

  it('passes the abort signal through', async () => {
    const spy = vi.spyOn(api, 'GET').mockResolvedValue(answer(200, healthy));
    const controller = new AbortController();
    await fetchHealth(controller.signal);
    expect(spy).toHaveBeenCalledWith('/health', { signal: controller.signal });
  });
});

describe('HealthStatus', () => {
  it('shows ok and the version', async () => {
    vi.spyOn(api, 'GET').mockResolvedValue(answer(200, healthy));
    renderStatus();
    expect(await screen.findByText('Server ok')).toBeInTheDocument();
    expect(screen.getByText('Version 0.1.0')).toBeInTheDocument();
  });

  it('shows when the database is down', async () => {
    vi.spyOn(api, 'GET').mockResolvedValue(answer(503, degraded));
    renderStatus();
    expect(await screen.findByText('Database unavailable')).toBeInTheDocument();
  });

  it('offers a retry when unreachable', async () => {
    const spy = vi.spyOn(api, 'GET').mockRejectedValue(new TypeError('offline'));
    renderStatus();
    expect(await screen.findByRole('alert')).toHaveTextContent("Can't reach the server");
    spy.mockResolvedValue(answer(200, healthy));
    await userEvent.click(screen.getByRole('button', { name: 'Try again' }));
    expect(await screen.findByText('Server ok')).toBeInTheDocument();
  });
});
