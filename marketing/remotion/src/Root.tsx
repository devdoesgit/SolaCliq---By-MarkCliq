import { Composition } from 'remotion'
import { DURATION, Promo } from './Promo'

// One story, two shapes: 16:9 for the website, 9:16 for Reels and Status.
export function Root() {
  return (
    <>
      <Composition id="Promo" component={Promo} durationInFrames={DURATION} fps={30} width={1920} height={1080} />
      <Composition id="PromoVertical" component={Promo} durationInFrames={DURATION} fps={30} width={1080} height={1920} />
    </>
  )
}
