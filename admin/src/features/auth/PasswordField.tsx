import { useState } from 'react';
import { TextField, type TextFieldProps } from '../../components';

/** A password field with "Show password" on its label's line. */
export function PasswordField(props: Omit<TextFieldProps, 'type'>) {
  const [visible, setVisible] = useState(false);
  return (
    <div className="password">
      <TextField {...props} type={visible ? 'text' : 'password'} />
      <button
        type="button"
        className="password-show"
        aria-pressed={visible}
        onClick={() => setVisible((v) => !v)}
      >
        {visible ? 'Hide password' : 'Show password'}
      </button>
    </div>
  );
}
