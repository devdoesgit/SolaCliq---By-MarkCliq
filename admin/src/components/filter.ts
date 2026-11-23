/**
 * The filter in the address, if it's one of the options; `all` is every
 * one, and anything else is the list's default.
 */
export function readFilter<T extends string>(
  raw: string | null,
  options: { value: T | '' }[],
  fallback: T | '',
): T | '' {
  if (raw === 'all') return '';
  return options.find((o) => o.value !== '' && o.value === raw)?.value ?? fallback;
}
