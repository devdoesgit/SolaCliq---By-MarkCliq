import type { ButtonHTMLAttributes } from 'react';

export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger';

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  /** Primary is the one main action on a page. Defaults to secondary. */
  variant?: ButtonVariant;
  /** 40px tall, for tables and toolbars. */
  compact?: boolean;
  /** Fill the available width. */
  block?: boolean;
}

/** A SolaCliq button: mono, uppercase, square, as on markcliq.com. */
export function Button({
  variant = 'secondary',
  compact = false,
  block = false,
  type = 'button',
  className,
  children,
  ...rest
}: ButtonProps) {
  const classes = [
    'sc-btn',
    `sc-btn-${variant}`,
    compact && 'sc-btn-compact',
    block && 'sc-btn-block',
    className,
  ]
    .filter(Boolean)
    .join(' ');
  return (
    <button type={type} className={classes} {...rest}>
      <span>{children}</span>
    </button>
  );
}
