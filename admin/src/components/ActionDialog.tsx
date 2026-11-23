import { useEffect, useId, useRef, useState, type FormEvent, type ReactNode } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { ApiProblem } from '../api/problem';
import { useAnnounce } from '../app/announce';
import { Button, type ButtonVariant } from './Button';
import { Icon, type IconName } from './Icon';
import { Notice } from './Notice';

export type Errors = Record<string, string | undefined>;

const FIXABLE = new Set(['member.already_in_org']);

export interface ActionDialogProps {
  title: string;
  /** What will happen, before they confirm. */
  body?: ReactNode;
  confirm: string;
  danger?: boolean;
  /** Said once it worked: "Expense approved". */
  done: string;
  /** Field errors found before sending, by the API's field names. */
  validate?: () => Errors;
  run: () => Promise<unknown>;
  onClose: () => void;
  children?: (errors: Errors) => ReactNode;
}

/*
  Every decision goes through this
  ----------------------------------------------------------------------
  - can't be sent twice, and can't be closed while it's being sent
  - a refusal shows under its field; one for no field here, in the notice
  - 409: someone got there first (another tab). It closes, says so, and
    the screen reloads. The message can't live in the dialog: the reload
    takes away the button that owns it
  - whatever happened, the company's data is read again
*/
export function ActionDialog({
  title,
  body,
  confirm,
  danger = false,
  done,
  validate,
  run,
  onClose,
  children,
}: ActionDialogProps) {
  const client = useQueryClient();
  const announce = useAnnounce();
  const dialog = useRef<HTMLDialogElement>(null);
  const sending = useRef(false);
  const headingId = useId();
  const [busy, setBusy] = useState(false);
  const [errors, setErrors] = useState<Errors>({});
  const [problem, setProblem] = useState<ApiProblem | null>(null);

  useEffect(() => {
    const opener = document.activeElement as HTMLElement | null;
    const element = dialog.current;
    if (element && !element.open) element.showModal();
    return () => {
      if (element?.open) element.close();
      // The button that opened it may be gone with the state it changed.
      if (opener?.isConnected) opener.focus();
      else document.querySelector<HTMLElement>('main')?.focus();
    };
  }, []);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (sending.current) return;
    const found = validate?.() ?? {};
    setErrors(found);
    setProblem(null);
    if (Object.values(found).some(Boolean)) return;
    sending.current = true;
    setBusy(true);
    try {
      await run();
      void client.invalidateQueries({ queryKey: ['org'] });
      announce(done);
      onClose();
    } catch (error) {
      const failed =
        error instanceof ApiProblem
          ? error
          : new ApiProblem(0, 'unknown', 'Something went wrong. Try again.');
      // A conflict in what was typed (an email already in the team) is
      // fixed here; one in the record's state can't be.
      if (failed.status === 409 && !FIXABLE.has(failed.code)) {
        void client.invalidateQueries({ queryKey: ['org'] });
        announce(`${failed.message}. The page now shows how it stands.`);
        onClose();
        return;
      }
      setProblem(failed);
      setErrors(failed.fields);
    } finally {
      sending.current = false;
      setBusy(false);
    }
  }

  const details = problem ? Object.values(problem.fields).join(' ') : '';

  return (
    <dialog
      ref={dialog}
      className="dialog"
      aria-labelledby={headingId}
      onCancel={(event) => {
        event.preventDefault();
        if (!sending.current) onClose();
      }}
    >
      <form className="dialog-form" onSubmit={(event) => void submit(event)} noValidate>
        <h2 id={headingId} className="t-h1">
          {title}
        </h2>
        {body && <div className="muted">{body}</div>}
        {problem && <Notice tone="danger" announce title={problem.message} body={details} />}
        {children?.(errors)}
        <div className="dialog-actions">
          <Button onClick={onClose} disabled={busy}>
            Close
          </Button>
          <Button type="submit" variant={danger ? 'danger' : 'primary'} disabled={busy}>
            {busy ? 'Sending…' : confirm}
          </Button>
        </div>
      </form>
    </dialog>
  );
}

/*
  A button that opens a dialog, which starts empty each time
  ----------------------------------------------------------------------
  - give it a key of the state it acts on where another action could
    take its place (Ask for it, then Yes received): an open dialog must
    never become a different one under someone's cursor
  - if what it acts on changes while it's open, it closes and says so
*/
export function DialogButton({
  label,
  hint,
  icon,
  variant,
  compact,
  block,
  disabled,
  dialog,
}: {
  label: string;
  /** Makes it a row of a Manage card: the label, and what it does under it. */
  hint?: string;
  icon?: IconName;
  variant?: ButtonVariant;
  compact?: boolean;
  block?: boolean;
  disabled?: boolean;
  dialog: (close: () => void) => ReactNode;
}) {
  const [open, setOpen] = useState(false);
  const isOpen = useRef(false);
  const announce = useAnnounce();
  useEffect(
    () => () => {
      if (isOpen.current) announce('That changed meanwhile, so the window closed.');
    },
    [announce],
  );
  function show() {
    isOpen.current = true;
    setOpen(true);
  }
  function close() {
    isOpen.current = false;
    setOpen(false);
  }
  return (
    <>
      {hint ? (
        <button
          type="button"
          className={variant === 'danger' ? 'manage manage-danger' : 'manage'}
          aria-label={label}
          aria-description={hint}
          disabled={disabled}
          onClick={show}
        >
          <span className="manage-icon">{icon && <Icon name={icon} size={17} />}</span>
          <span className="cell-main">
            <span className="manage-label">{label}</span>
            <span className="cell-sub">{hint}</span>
          </span>
        </button>
      ) : (
        <Button
          variant={variant}
          icon={icon}
          compact={compact}
          block={block}
          disabled={disabled}
          onClick={show}
        >
          {label}
        </Button>
      )}
      {open && <Opened dialog={dialog} close={close} />}
    </>
  );
}

function Opened({
  dialog,
  close,
}: {
  dialog: (close: () => void) => ReactNode;
  close: () => void;
}) {
  return dialog(close);
}
