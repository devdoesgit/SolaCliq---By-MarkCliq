import { useId, type SelectHTMLAttributes, type TextareaHTMLAttributes } from 'react';

interface Labelled {
  label: string;
  help?: string;
  error?: string;
}

function Note({ id, help, error }: { id: string; help?: string; error?: string }) {
  if (!(error ?? help)) return null;
  return (
    <p
      id={id}
      className={`t-body-sm ${error ? 'sc-field-error' : 'sc-field-help'}`}
      role={error ? 'alert' : undefined}
    >
      {error ?? help}
    </p>
  );
}

export function SelectField({
  label,
  help,
  error,
  children,
  ...rest
}: Labelled & Omit<SelectHTMLAttributes<HTMLSelectElement>, 'id'>) {
  const id = useId();
  return (
    <div className="sc-field">
      <label htmlFor={id} className="t-label">
        {label}
      </label>
      <select
        id={id}
        className="sc-input"
        aria-invalid={error ? true : undefined}
        aria-describedby={(error ?? help) ? `${id}-note` : undefined}
        {...rest}
      >
        {children}
      </select>
      <Note id={`${id}-note`} help={help} error={error} />
    </div>
  );
}

export function TextArea({
  label,
  help,
  error,
  ...rest
}: Labelled & Omit<TextareaHTMLAttributes<HTMLTextAreaElement>, 'id'>) {
  const id = useId();
  return (
    <div className="sc-field">
      <label htmlFor={id} className="t-label">
        {label}
      </label>
      <textarea
        id={id}
        className="sc-input sc-textarea"
        aria-invalid={error ? true : undefined}
        aria-describedby={(error ?? help) ? `${id}-note` : undefined}
        {...rest}
      />
      <Note id={`${id}-note`} help={help} error={error} />
    </div>
  );
}
