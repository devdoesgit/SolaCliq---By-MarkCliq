import { useId, type InputHTMLAttributes } from 'react';

export interface TextFieldProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'id'> {
  /** Field label, sentence case; shown in uppercase. */
  label: string;
  /** Help text under the field. */
  help?: string;
  /** Error text; replaces help and marks the field invalid. */
  error?: string;
  /** Mono with tabular figures: amounts, kW, readings. */
  numeric?: boolean;
}

/** A labelled text field with help or error text wired for screen readers. */
export function TextField({
  label,
  help,
  error,
  numeric = false,
  className,
  ...rest
}: TextFieldProps) {
  const id = useId();
  const noteId = `${id}-note`;
  const note = error ?? help;
  return (
    <div className="sc-field">
      <label htmlFor={id} className="t-label">
        {label}
      </label>
      <input
        id={id}
        className={['sc-input', numeric && 'sc-input-num', className].filter(Boolean).join(' ')}
        inputMode={numeric ? 'decimal' : rest.inputMode}
        aria-invalid={error ? true : undefined}
        aria-describedby={note ? noteId : undefined}
        {...rest}
      />
      {note && (
        <p
          id={noteId}
          className={`t-body-sm ${error ? 'sc-field-error' : 'sc-field-help'}`}
          role={error ? 'alert' : undefined}
        >
          {note}
        </p>
      )}
    </div>
  );
}
