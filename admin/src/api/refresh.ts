/**
 * Keeps the admin signed in past the 15-minute access cookie (OAuth 2.1
 * refresh, decision 2026-11-11).
 *
 * On a 401 the browser's refresh cookie is traded for new cookies at
 * `/auth/refresh`, then the request is sent once more. Only one refresh
 * runs at a time: the server treats a second refresh with the same cookie
 * as theft and ends the session, so parallel 401s share one refresh.
 * Auth endpoints (log in, refresh, codes) pass straight through, so a
 * refresh can never loop.
 */
export function withRefresh(
  baseUrl: string,
  baseFetch: (input: Request) => Promise<Response> = (input) => globalThis.fetch(input),
): (input: Request) => Promise<Response> {
  let refreshing: Promise<boolean> | null = null;

  const refresh = (): Promise<boolean> => {
    refreshing ??= baseFetch(
      new Request(`${baseUrl}/auth/refresh`, { method: 'POST', credentials: 'include' }),
    )
      .then((res) => res.ok)
      .catch(() => false)
      .finally(() => {
        refreshing = null;
      });
    return refreshing;
  };

  return async (input) => {
    // Kept before sending: a request body can only be read once.
    const retry = input.clone();
    const response = await baseFetch(input);
    if (response.status !== 401 || isPublicAuthPath(input.url, baseUrl)) return response;
    // A failed refresh means the login is over: the 401 stands and the
    // page shows the login screen.
    return (await refresh()) ? baseFetch(retry) : response;
  };
}

function isPublicAuthPath(url: string, baseUrl: string): boolean {
  const path = new URL(url, 'http://local').pathname;
  const base = new URL(baseUrl, 'http://local').pathname.replace(/\/$/, '');
  const rest = path.startsWith(base) ? path.slice(base.length) : path;
  return rest.startsWith('/auth/') && rest !== '/auth/logout';
}
