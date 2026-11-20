/** A Markdown file as HTML, made at build time (`legalMarkdown` in vite.config.ts). */
declare module '*.md?html' {
  const html: string;
  export default html;
}
