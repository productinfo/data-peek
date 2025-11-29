import { Header } from '@/components/marketing/header'
import { Hero } from '@/components/marketing/hero'
import { Features } from '@/components/marketing/features'
import { Pricing } from '@/components/marketing/pricing'
import { FAQ } from '@/components/marketing/faq'
import { CTA } from '@/components/marketing/cta'
import { Footer } from '@/components/marketing/footer'

export default function Home() {
  return (
    <div className="min-h-screen">
      <Header />
      <main>
        <Hero />
        <Features />
        <Pricing />
        <FAQ />
        <CTA />
      </main>
      <Footer />
    </div>
  )
}
