/** A failed request: the API's problem+json, or no connection (status 0). */
export class ApiProblem extends Error {
  readonly status: number;
  readonly code: string;
  /** The server's message per field it refused, by the API's field name. */
  readonly fields: Record<string, string>;

  constructor(status: number, code: string, message: string, fields: Record<string, string> = {}) {
    super(message);
    this.name = 'ApiProblem';
    this.status = status;
    this.code = code;
    this.fields = fields;
  }

  static from(status: number, body: unknown): ApiProblem {
    const b = (typeof body === 'object' && body !== null ? body : {}) as {
      code?: unknown;
      title?: unknown;
      errors?: unknown;
    };
    const fields: Record<string, string> = {};
    if (Array.isArray(b.errors)) {
      for (const e of b.errors as { field?: unknown; message?: unknown }[]) {
        if (typeof e?.field === 'string' && typeof e.message === 'string') {
          fields[e.field] = e.message;
        }
      }
    }
    return new ApiProblem(
      status,
      typeof b.code === 'string' ? b.code : 'unknown',
      status < 500 && typeof b.title === 'string' ? b.title : 'Something went wrong. Try again.',
      fields,
    );
  }
}

interface Answer<T> {
  data?: T;
  error?: unknown;
  response: Response;
}

/** The body of a successful request. Throws `ApiProblem` otherwise. */
export async function unwrap<T>(request: Promise<Answer<T>>): Promise<T> {
  let answer: Answer<T>;
  try {
    answer = await request;
  } catch (error) {
    if (error instanceof DOMException && error.name === 'AbortError') throw error;
    throw new ApiProblem(0, 'network', 'No connection. Check your internet and try again.');
  }
  if (!answer.response.ok) throw ApiProblem.from(answer.response.status, answer.error);
  return answer.data as T;
}
