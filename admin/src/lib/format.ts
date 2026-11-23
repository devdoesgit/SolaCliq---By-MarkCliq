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
 * Formats an amount in paise for display: `₹1,85,000`, or `₹4.55` when
 * there are paise (as the app and the design show it; nothing is rounded),
 * `−₹5,000` for negatives. Accepts a bigint for amounts beyond Number's
 * safe range; the API sends paise as int64.
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
  const paisePart = fraction === '00' ? '' : `.${fraction}`;
  return `${negative ? MINUS_SIGN : ''}₹${groupIndian(rupees)}${paisePart}`;
}

const INDIA_OFFSET_MS = (5 * 60 + 30) * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

const two = (n: number) => String(n).padStart(2, '0');

// The moment shifted to India's clock: read it with the getUTC* methods.
// India has no daylight saving, so the fixed offset is exact.
function inIndia(value: Date | string): Date {
  return new Date(new Date(value).getTime() + INDIA_OFFSET_MS);
}

/** `18 Oct 2026`, in India, wherever the viewer is. */
export function formatDate(value: Date | string): string {
  const d = inIndia(value);
  return `${d.getUTCDate()} ${MONTHS[d.getUTCMonth()]} ${d.getUTCFullYear()}`;
}

/** `18 Oct 2026, 14:05` (24-hour), in India. */
export function formatDateTime(value: Date | string): string {
  const d = inIndia(value);
  return `${formatDate(value)}, ${two(d.getUTCHours())}:${two(d.getUTCMinutes())}`;
}

/** `14:05`, in India. */
export function formatTime(value: Date | string): string {
  const d = inIndia(value);
  return `${two(d.getUTCHours())}:${two(d.getUTCMinutes())}`;
}

/** Worked time: `568` as `9 h 28 m`. */
export function formatMinutes(minutes: number): string {
  return `${Math.floor(minutes / 60)} h ${two(minutes % 60)} m`;
}

const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'] as const;

/** `21 Oct`, in India. */
export function formatShortDate(value: Date | string): string {
  const d = inIndia(value);
  return `${d.getUTCDate()} ${MONTHS[d.getUTCMonth()]}`;
}

/** When something is due or happened: `Today 13:00`, `Fri 14:30`, `21 Oct 11:00`. */
export function formatWhen(value: Date | string, now: Date = new Date()): string {
  const d = inIndia(value);
  const days = Math.floor(d.getTime() / DAY_MS) - Math.floor(inIndia(now).getTime() / DAY_MS);
  const day =
    days === 0
      ? 'Today'
      : days === 1
        ? 'Tomorrow'
        : days === -1
          ? 'Yesterday'
          : days > 1 && days < 7
            ? WEEKDAYS[d.getUTCDay()]
            : formatShortDate(value);
  return `${day} ${formatTime(value)}`;
}

/** `Monday, 23 Nov`, in India. */
export function formatLongDay(value: Date | string): string {
  const names = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  return `${names[inIndia(value).getUTCDay()]}, ${formatShortDate(value)}`;
}

/** `Good morning`, by India's clock. */
export function greeting(now: Date = new Date()): string {
  const hour = inIndia(now).getUTCHours();
  return hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
}

/** A calendar day from the API (`2026-10-18`) as `18 Oct 2026`. */
export function formatDay(day: string): string {
  const [year, month, date] = day.split('-').map(Number);
  return `${date} ${MONTHS[month - 1]} ${year}`;
}

/** A month from the API (`2026-11`) as `Nov 2026`. */
export function formatMonth(month: string): string {
  const [year, number] = month.split('-').map(Number);
  return `${MONTHS[number - 1]} ${year}`;
}

/** The date in India, `days` from today, for a date field: `2026-10-18`. */
export function indiaDay(days = 0, now: Date = new Date()): string {
  return inIndia(new Date(now.getTime() + days * DAY_MS))
    .toISOString()
    .slice(0, 10);
}

/** An instant as a datetime-local value on India's clock. */
export function toIndiaInput(value: Date | string): string {
  return inIndia(value).toISOString().slice(0, 16);
}

/** A datetime-local value, typed as Indian time, as a UTC instant. */
export function fromIndiaInput(value: string): string {
  return new Date(`${value}:00+05:30`).toISOString();
}

/**
 * Typed rupees as integer paise: `1,85,000` or `4.55`. Undefined when it
 * isn't an amount. The digits are read as text, never through a float.
 */
export function parseRupees(text: string): number | undefined {
  const match = /^(\d{1,12})(?:\.(\d{1,2}))?$/.exec(text.replace(/[,\s₹]/g, ''));
  if (!match) return undefined;
  return Number(match[1]) * 100 + Number((match[2] ?? '').padEnd(2, '0'));
}

/** Paise as text for a rupees field: `185000` or `4.55`. */
export function rupeesInput(paise: number): string {
  const digits = String(paise).padStart(3, '0');
  const part = digits.slice(-2);
  return part === '00' ? digits.slice(0, -2) : `${digits.slice(0, -2)}.${part}`;
}

/** `1 file`, `2 files`. */
export function count(n: number, one: string, many = `${one}s`): string {
  return `${n} ${n === 1 ? one : many}`;
}
