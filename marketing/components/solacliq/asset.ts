// An imported image's URL. Vite gives a string; Next.js gives an object with
// `src` (StaticImageData). Either works here.
export const asset = (m: string | { src: string }) => (typeof m === 'string' ? m : m.src)
