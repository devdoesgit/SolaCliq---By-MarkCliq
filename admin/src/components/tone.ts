/** The meaning a pill or notice carries. Always shown with a word. */
export type Tone = 'neutral' | 'success' | 'warning' | 'danger' | 'info' | 'accent';

export const toneClass = (tone: Tone) => (tone === 'neutral' ? '' : `sc-tone-${tone}`);
