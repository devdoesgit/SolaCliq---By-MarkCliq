import type { ButtonHTMLAttributes } from 'react';
import { Icon, type IconName } from './Icon';

export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger' | 'dark';

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  /** Primary is the one main action on a page. Defaults to secondary. */
  variant?: ButtonVariant;
  /** 40px tall, for tables and toolbars. */
  compact?: boolean;
  /** Fill the available width. */
  block?: boolean;
  icon?: IconName;
}

/** A SolaCliq button: a pill, as in the app. */
export function Button({
  variant = 'secondary',
  compact = false,
  block = false,
  icon,
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
      {icon && <Icon name={icon} size={16} />}
      <span>{children}</span>
    </button>
  );
}
