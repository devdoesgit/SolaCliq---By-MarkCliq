/** Minus sign for negative amounts (U+2212), never a hyphen or brackets. */
export const MINUS_SIGN = '−';

const MONTHS = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
] as const;

/**
 * Groups a string of digits the Indian way: `18500000` → `1,85,00,000`.
 * The last three digits form one group; every group before it has two.
 */
export function groupIndian(digits: string): string {
  if (digits.length <= 3) return digits;
  const head = digits.slice(0, -3);
  const tail = digits.slice(-3);
  const groups: string[] = [];
  for (let end = head.length; end > 0; end -= 2) {
    groups.unshift(head.slice(Math.max(0, end - 2), end));
  }
  return `${groups.join(',')},${tail}`;
}

/**
 * Formats an amount in paise for display: `₹1,85,000.00`, Indian grouping,
 * two decimals, `−₹5,000.00` for negatives. Accepts a bigint for amounts
 * beyond Number's safe range; the API sends paise as int64.
 */
export function formatPaise(paise: number | bigint): string {
  if (typeof paise === 'number' && !Number.isSafeInteger(paise)) {
    throw new RangeError(`Paise must be a safe integer, got ${paise}`);
  }
  const value = BigInt(paise);
  const negative = value < 0n;
  const digits = (negative ? -value : value).toString().padStart(3, '0');
  const rupees = digits.slice(0, -2);
  const fraction = digits.slice(-2);
  return `${negative ? MINUS_SIGN : ''}₹${groupIndian(rupees)}.${fraction}`;
}

/** `18 Oct 2026`, in the viewer's local time. */
export function formatDate(value: Date): string {
  return `${value.getDate()} ${MONTHS[value.getMonth()]} ${value.getFullYear()}`;
}

/** `18 Oct 2026, 14:05` (24-hour), in the viewer's local time. */
export function formatDateTime(value: Date): string {
  const hh = String(value.getHours()).padStart(2, '0');
  const mm = String(value.getMinutes()).padStart(2, '0');
  return `${formatDate(value)}, ${hh}:${mm}`;
}
