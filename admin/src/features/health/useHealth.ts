import { useQuery } from '@tanstack/react-query';
import { api, type components } from '../../api/client';

export type Health = components['schemas']['Health'];

/** Thrown when the API can't be reached or gives no usable answer. */
export class HealthUnreachableError extends Error {
  constructor(cause?: unknown) {
    super("Can't reach the server", { cause });
    this.name = 'HealthUnreachableError';
  }
}

/**
 * Reads `GET /health`. A 503 is a valid answer (database down), not an
 * error. The request is aborted if the component unmounts.
 */
export async function fetchHealth(signal?: AbortSignal): Promise<Health> {
  let result;
  try {
    result = await api.GET('/health', { signal });
  } catch (error) {
    if (signal?.aborted) throw error;
    throw new HealthUnreachableError(error);
  }
  const { data, error } = result;
  const body = data ?? (result.response.status === 503 ? error : undefined);
  if (!body) throw new HealthUnreachableError(result.response.status);
  return body;
}

export function useHealth() {
  return useQuery({
    queryKey: ['health'],
    queryFn: ({ signal }) => fetchHealth(signal),
    retry: false,
  });
}
