// SolaCliq's own line icons (the iOS v2 design's, from
// mobile/packages/sola_ui/lib/src/icons/sola_icon.dart): a 24px grid, round
// caps and joins, each with the stroke the app draws it at.
const ICONS = {
  back: ['<path d="M15 5l-7 7 7 7"/>', 1.7],
  check: ['<path d="M5 12.5l4.5 4.5L19 7.5"/>', 2.2],
  camera: ['<path d="M4 8h3l2-3h6l2 3h3v11H4z"/><circle cx="12" cy="13" r="3.5"/>', 2],
  pin: ['<path d="M12 21s-6.5-6.2-6.5-11a6.5 6.5 0 0 1 13 0c0 4.8-6.5 11-6.5 11z"/><circle cx="12" cy="10" r="2.4"/>', 2],
  chevronRight: ['<path d="M9 6l6 6-6 6"/>', 2],
  hourglass: ['<path d="M7 3h10M7 21h10M8 3c0 5 8 5 8 9s-8 4-8 9M16 3c0 5-8 5-8 9"/>', 2.2],
  receipt: ['<path d="M6 3h12v18l-3-2-3 2-3-2-3 2z"/><path d="M9 8h6M9 12h6"/>', 1.7],
  bell: ['<path d="M6 16V11a6 6 0 0 1 12 0v5l1.5 1.5H4.5z"/><path d="M10 20.5h4"/>', 1.7],
  home: ['<path d="M4 10.5l8-6.5 8 6.5V20H4z"/><path d="M10 20v-5h4v5"/>', 1.7],
  user: ['<circle cx="12" cy="8" r="4"/><path d="M4.5 20.5a7.5 7.5 0 0 1 15 0"/>', 1.7],
  bolt: ['<path d="M13 3L5 13.5h6L10 21l8-10.5h-6z"/>', 2.2],
  file: ['<path d="M7 3h7l4 4v14H7z"/><path d="M14 3v4h4M10 12h5M10 16h5"/>', 1.7],
  plus: ['<path d="M12 5v14M5 12h14"/>', 2],
} as const

export type SqIconName = keyof typeof ICONS

export function SqIcon({ name, size = 16 }: { name: SqIconName; size?: number }) {
  const [paths, stroke] = ICONS[name]
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={stroke}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
      style={{ flex: 'none', display: 'block' }}
      dangerouslySetInnerHTML={{ __html: paths }}
    />
  )
}
