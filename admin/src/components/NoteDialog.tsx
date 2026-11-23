import { useState } from 'react';
import { ActionDialog, type ActionDialogProps } from './ActionDialog';
import { TextArea } from './Fields';

/** A decision that has to say why: send back, cancel, don't take up. */
export function NoteDialog({
  label,
  help,
  send,
  ...rest
}: Omit<ActionDialogProps, 'children' | 'validate' | 'run'> & {
  label: string;
  help?: string;
  send: (note: string) => Promise<unknown>;
}) {
  const [note, setNote] = useState('');
  return (
    <ActionDialog
      {...rest}
      validate={() => ({ note: note.trim() ? undefined : 'Write a few words.' })}
      run={() => send(note.trim())}
    >
      {(errors) => (
        <TextArea
          label={label}
          help={help}
          maxLength={500}
          autoFocus
          value={note}
          error={errors.note}
          onChange={(e) => setNote(e.target.value)}
        />
      )}
    </ActionDialog>
  );
}
