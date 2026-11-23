import { Link, useSearchParams } from 'react-router';

/** One list's filter, kept in the address so Back and a reload keep it. */
export function Filters<T extends string>({
  name,
  label,
  options,
  value,
}: {
  name: string;
  label: string;
  options: { value: T | ''; label: string }[];
  value: T | '';
}) {
  const [params] = useSearchParams();
  return (
    <nav className="chips" aria-label={label}>
      {options.map((option) => {
        const next = new URLSearchParams(params);
        // 'all' is written out, as no value means the list's default.
        next.set(name, option.value || 'all');
        return (
          <Link
            key={option.value || 'all'}
            className="chip"
            to={`?${next}`}
            aria-current={option.value === value ? 'true' : undefined}
          >
            {option.label}
          </Link>
        );
      })}
    </nav>
  );
}
