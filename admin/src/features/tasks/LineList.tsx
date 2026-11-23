import { Icon, type IconName } from '../../components';

/** The checklist's rows, or the photos' chips: typed in place. */
export function LineList({
  title,
  item,
  icon,
  chips = false,
  max,
  lines,
  error,
  onChange,
}: {
  title: string;
  item: string;
  icon: IconName;
  chips?: boolean;
  max: number;
  lines: string[];
  error?: string;
  onChange: (lines: string[]) => void;
}) {
  return (
    <fieldset className="lines">
      <legend className="field-label">{title}</legend>
      <ul className={chips ? 'line-chips' : 'line-rows'}>
        {lines.map((line, i) => (
          <li key={i} className={chips ? 'line-chip' : 'line-row'}>
            <Icon name={icon} size={15} />
            <label>
              <span className="visually-hidden">{`${item} ${i + 1}`}</span>
              <input
                maxLength={max}
                placeholder={`${item} ${i + 1}`}
                value={line}
                onChange={(e) => onChange(lines.map((l, j) => (j === i ? e.target.value : l)))}
              />
            </label>
            <button
              type="button"
              className="line-remove"
              aria-label={`Remove ${item.toLowerCase()} ${i + 1}`}
              onClick={() => onChange(lines.filter((_, j) => j !== i))}
            >
              <Icon name="close" size={14} />
            </button>
          </li>
        ))}
      </ul>
      <button
        type="button"
        className="link-button add-line"
        onClick={() => onChange([...lines, ''])}
      >
        <Icon name="plus" size={14} />
        Add {item.toLowerCase()}
      </button>
      {error && (
        <p className="sc-field-error t-body-sm" role="alert">
          {error}
        </p>
      )}
    </fieldset>
  );
}
