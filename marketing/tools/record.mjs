// Records one seamless loop of a Stageshow example, frame by frame on the
// playground's virtual clock (?embed=, stepped by stageshow:control
// messages), as 2x PNG frames; ffmpeg turns them into MP4 and WebM.
// Run it from a Stageshow checkout with its playground on port 5199:
//   node record.mjs <example> <outDir> [--fps 30] [--mark photo] [--still] [--poster <mark>]
import { chromium } from 'playwright-core'
import { mkdirSync, rmSync } from 'node:fs'

const [name, out, ...rest] = process.argv.slice(2)
const opt = (k, d) => { const i = rest.indexOf(`--${k}`); return i < 0 ? d : rest[i + 1] }
const still = rest.includes('--still')
const fps = Number(opt('fps', 30))
const mark = opt('mark', null)
const scale = Number(opt('scale', 2))

const browser = await chromium.launch({ channel: 'chrome' })
const page = await browser.newPage({ viewport: { width: 1000, height: 900 }, deviceScaleFactor: scale })
page.on('pageerror', (e) => console.error('pageerror', e.message))
await page.goto(`http://127.0.0.1:5199/?embed=${name}`)
const stage = page.locator('#example .ss-stage').first()
const poster = opt('poster', null)
await stage.waitFor()
await page.evaluate(() => document.fonts.ready)
// Video has no transparency: the page's grey (markcliq.com, #f5f5f7) shows
// in the stage's rounded corners, so on the site they disappear. Stills keep
// transparent corners.
if (!still) await page.addStyleTag({ content: 'html, body, #root { background: #f5f5f7 !important; }' })

// One virtual frame (1/60 s), awaited through the status reply
const step = () => page.evaluate(() => new Promise((res) => {
  const h = (e) => { if (e.data?.type === 'stageshow:status') { removeEventListener('message', h); res(e.data.frame) } }
  addEventListener('message', h)
  postMessage({ type: 'stageshow:control', step: true }, location.origin)
}))
const currentMark = () => stage.getAttribute('data-mark')

mkdirSync(out, { recursive: true })
if (still) {
  // A still of a looping scene: wait for a beat (--poster <mark>) and let it land
  if (poster) { let g = 0; while ((await currentMark()) !== poster && g++ < 6000) await step() }
  for (let i = 0; i < Number(opt('settle', 30)); i++) await step()
  await stage.screenshot({ path: `${out}/${name}.png`, omitBackground: true })
  console.log('still', `${out}/${name}.png`)
} else {
  const frames = `${out}/frames-${name}`
  rmSync(frames, { recursive: true, force: true })
  mkdirSync(frames, { recursive: true })
  const per = Math.round(60 / fps)
  // Start where the mark begins (a calm frame), stop where it begins again
  let prev = await currentMark()
  let guard = 0
  while (guard++ < 6000) {
    await step()
    const m = await currentMark()
    if (m === mark && prev !== mark) break
    prev = m
  }
  let n = 0
  prev = mark
  while (n < fps * 40) {
    await stage.screenshot({ path: `${frames}/${String(n).padStart(5, '0')}.png` })
    n++
    let back = false
    for (let k = 0; k < per; k++) {
      await step()
      const m = await currentMark()
      if (m === mark && prev !== mark) back = true
      prev = m
    }
    if (back) break
  }
  console.log('frames', n, frames)
}
await browser.close()
