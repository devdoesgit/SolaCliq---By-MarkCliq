import { useState } from 'react';
import { Button, TextField, type TextFieldProps } from '../../components';

/** A password field with a "Show password" button under it. */
export function PasswordField(props: Omit<TextFieldProps, 'type'>) {
  const [visible, setVisible] = useState(false);
  return (
    <div className="stack" style={{ gap: 'var(--space-1)' }}>
      <TextField {...props} type={visible ? 'text' : 'password'} />
      <div>
        {/* Pulled left by its own padding so its text lines up with the field. */}
        <Button
          variant="ghost"
          compact
          aria-pressed={visible}
          style={{ marginInlineStart: 'calc(-1 * var(--space-3))' }}
          onClick={() => setVisible((v) => !v)}
        >
          {visible ? 'Hide password' : 'Show password'}
        </Button>
      </div>
    </div>
  );
}
