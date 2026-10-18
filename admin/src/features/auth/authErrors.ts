/** Why an auth request failed, from the API's problem `code` or the network. */
export type AuthErrorCode =
  | 'invalid_credentials'
  | 'email_unverified'
  | 'code_invalid'
  | 'code_expired'
  | 'too_many_attempts'
  | 'password_too_weak'
  | 'session_expired'
  | 'validation'
  | 'network'
  | 'unknown';

const API_CODES: Record<string, AuthErrorCode> = {
  'auth.invalid_credentials': 'invalid_credentials',
  'account.email_unverified': 'email_unverified',
  'auth.code_invalid': 'code_invalid',
  'auth.code_expired': 'code_expired',
  'auth.too_many_attempts': 'too_many_attempts',
  'auth.password_too_weak': 'password_too_weak',
  'auth.session_expired': 'session_expired',
  'validation.failed': 'validation',
};

/** What each failure tells the person. Same wording as the mobile app. */
export const AUTH_ERROR_MESSAGES: Record<AuthErrorCode, string> = {
  invalid_credentials: 'Email or password is wrong.',
  email_unverified: "Your email isn't verified yet. Use the code we emailed you.",
  code_invalid: 'That code is wrong. Check the email and try again.',
  code_expired: 'That code has expired. Request a new one.',
  too_many_attempts: 'Too many tries. Wait a few minutes and try again.',
  password_too_weak: 'Choose a stronger password.',
  session_expired: 'You were logged out. Log in again.',
  validation: 'Check the fields and try again.',
  network: 'No connection. Check your internet and try again.',
  unknown: 'Something went wrong. Try again.',
};

export class AuthError extends Error {
  readonly code: AuthErrorCode;

  constructor(code: AuthErrorCode, cause?: unknown) {
    super(AUTH_ERROR_MESSAGES[code], { cause });
    this.name = 'AuthError';
    this.code = code;
  }

  /** From a failed response: its problem+json `code`, else its status. */
  static fromResponse(response: Response, body: unknown): AuthError {
    const apiCode =
      typeof body === 'object' && body !== null && 'code' in body
        ? (body as { code: unknown }).code
        : undefined;
    const known = typeof apiCode === 'string' ? API_CODES[apiCode] : undefined;
    if (known) return new AuthError(known, body);
    switch (response.status) {
      case 401:
        return new AuthError('invalid_credentials', body);
      case 422:
        return new AuthError('validation', body);
      case 429:
        return new AuthError('too_many_attempts', body);
      default:
        return new AuthError('unknown', body);
    }
  }
}

/**
 * Runs an API call and turns a thrown fetch (no connection) into an
 * `AuthError('network')`. Aborts are rethrown unchanged.
 */
export async function callApi<T>(request: () => Promise<T>, signal?: AbortSignal): Promise<T> {
  try {
    return await request();
  } catch (error) {
    if (signal?.aborted || error instanceof AuthError) throw error;
    throw new AuthError('network', error);
  }
}
