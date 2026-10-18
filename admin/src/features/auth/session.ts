import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api, type components } from '../../api/client';
import { AuthError, callApi } from './authErrors';

export type Me = components['schemas']['Me'];

export const meQueryKey = ['me'] as const;

/**
 * Who is signed in, from the session cookie. Null when nobody is (401).
 * Throws `AuthError` when the server can't answer.
 */
export async function fetchMe(signal?: AbortSignal): Promise<Me | null> {
  const { data, error, response } = await callApi(() => api.GET('/me', { signal }), signal);
  if (data) return data;
  if (response.status === 401) return null;
  throw AuthError.fromResponse(response, error);
}

/** The admin website is for org admins and the MarkCliq platform admin. */
export function canUseAdmin(me: Me): boolean {
  return me.is_platform_admin || me.memberships.some((m) => m.role === 'org_admin');
}

export function useMe() {
  return useQuery({
    queryKey: meQueryKey,
    queryFn: ({ signal }) => fetchMe(signal),
    retry: false,
    staleTime: 5 * 60 * 1000,
  });
}

export function useLogin() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ email, password }: { email: string; password: string }) => {
      const { data, error, response } = await callApi(() =>
        api.POST('/auth/login', { body: { email, password, client: 'web' } }),
      );
      if (!data) throw AuthError.fromResponse(response, error);
      return data.user;
    },
    onSuccess: (user) => queryClient.setQueryData(meQueryKey, user),
  });
}

/** Ends the session. Signs out locally even if the server can't be reached. */
export function useLogout() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async () => {
      try {
        await api.POST('/auth/logout');
      } catch {
        // The cookie expires on its own; signing out locally is what matters.
      }
    },
    onSettled: () => {
      queryClient.removeQueries({ predicate: (q) => q.queryKey[0] !== meQueryKey[0] });
      queryClient.setQueryData(meQueryKey, null);
    },
  });
}

export function useRequestPasswordReset() {
  return useMutation({
    mutationFn: async ({ email }: { email: string }) => {
      const { error, response } = await callApi(() =>
        api.POST('/auth/password/forgot', { body: { email } }),
      );
      if (!response.ok) throw AuthError.fromResponse(response, error);
    },
  });
}

export function useResetPassword() {
  return useMutation({
    mutationFn: async (body: { email: string; code: string; new_password: string }) => {
      const { error, response } = await callApi(() => api.POST('/auth/password/reset', { body }));
      if (!response.ok) throw AuthError.fromResponse(response, error);
    },
  });
}
