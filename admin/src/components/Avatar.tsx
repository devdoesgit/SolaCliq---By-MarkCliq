// The design's avatar colours, picked by the name so a person keeps theirs.
const COLOURS = 5;

function colourOf(name: string): number {
  let hash = 0;
  for (const letter of name) hash = (hash * 31 + (letter.codePointAt(0) ?? 0)) % 997;
  return hash % COLOURS;
}

function initialsOf(name: string): string {
  return name
    .replace(/\(.*?\)/g, '')
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((word) => Array.from(word)[0].toUpperCase())
    .join('');
}

/** Someone's initials in a circle. Their name is always written beside it. */
export function Avatar({
  name,
  size = 'md',
  dark = false,
}: {
  name: string;
  size?: 'sm' | 'md' | 'lg';
  dark?: boolean;
}) {
  const colour = dark ? 'avatar-dark' : `avatar-${colourOf(name)}`;
  return (
    <span className={`avatar avatar-${size} ${colour}`} aria-hidden="true">
      {initialsOf(name)}
    </span>
  );
}

/** An avatar with the name, and a line under it. */
export function Person({
  name,
  sub,
  size,
}: {
  name: string;
  sub?: string;
  size?: 'sm' | 'md' | 'lg';
}) {
  return (
    <span className="person">
      <Avatar name={name} size={size} />
      <span className="cell-main">
        <span className="person-name">{name}</span>
        {sub && <span className="cell-sub">{sub}</span>}
      </span>
    </span>
  );
}
