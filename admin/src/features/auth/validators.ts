/**
 * Field checks run before any request, so obvious mistakes never wait on
 * the network. The server checks again. Same rules as the mobile app.
 */

const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
const CODE = /^\d{6}$/;

export function validateEmail(value: string): string | undefined {
  const v = value.trim();
  if (!v) return 'Enter Email.';
  return EMAIL.test(v) ? undefined : 'Enter an email like name@example.com.';
}

/** For log in: anything non-empty, since old passwords may predate rules. */
export function validateExistingPassword(value: string): string | undefined {
  return value ? undefined : 'Enter Password.';
}

export function validateNewPassword(value: string): string | undefined {
  if (!value) return 'Enter Password.';
  return value.length < 8 ? 'Use at least 8 characters.' : undefined;
}

export function validateCode(value: string): string | undefined {
  return CODE.test(value.trim()) ? undefined : 'Enter the 6 digits from the email.';
}

/**
 * A `next` parameter is only followed when it is a path on this site, so a
 * crafted login link can't send someone elsewhere after they sign in.
 */
export function safeNextPath(next: string | null): string {
  if (!next || !next.startsWith('/') || next.startsWith('//') || next.startsWith('/\\')) {
    return '/';
  }
  return next;
}
