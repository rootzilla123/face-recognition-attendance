'use client';
import Link from 'next/link';

const plans = [
  {
    name: 'Starter',
    price: '$49',
    period: '/month',
    description: 'Perfect for small schools getting started.',
    color: 'from-gray-500 to-gray-600',
    features: [
      'Up to 200 students',
      '2 camera streams',
      'Parent notifications',
      'Basic attendance reports',
      'Email support',
    ],
    cta: 'Get Started',
    href: '/onboarding',
    highlight: false,
  },
  {
    name: 'Pro',
    price: '$149',
    period: '/month',
    description: 'For growing schools that need more power.',
    color: 'from-purple-600 to-pink-600',
    features: [
      'Up to 1,000 students',
      '10 camera streams',
      'Real-time parent alerts',
      'Advanced analytics & reports',
      'CSV student import',
      'Priority support',
    ],
    cta: 'Start Free Trial',
    href: '/onboarding',
    highlight: true,
  },
  {
    name: 'Enterprise',
    price: 'Custom',
    period: '',
    description: 'For large institutions and school networks.',
    color: 'from-indigo-600 to-blue-600',
    features: [
      'Unlimited students',
      'Unlimited cameras',
      'Multi-branch support',
      'Custom integrations',
      'Dedicated account manager',
      'SLA guarantee',
    ],
    cta: 'Contact Us',
    href: 'mailto:sales@attendanceai.com',
    highlight: false,
  },
];

export default function PricingPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-950 via-gray-900 to-purple-950 px-4 py-20">
      <div className="max-w-5xl mx-auto">
        {/* Header */}
        <div className="text-center mb-16">
          <div className="inline-flex items-center gap-2 bg-purple-500/10 border border-purple-500/20 rounded-full px-4 py-1.5 text-purple-300 text-sm font-medium mb-6">
            💳 Simple, transparent pricing
          </div>
          <h1 className="text-5xl font-bold text-white mb-4 tracking-tight">
            Plans for every school
          </h1>
          <p className="text-gray-400 text-lg max-w-xl mx-auto">
            Start free, scale as you grow. No hidden fees, no long-term contracts.
          </p>
        </div>

        {/* Plans */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-16">
          {plans.map((plan) => (
            <div
              key={plan.name}
              className={`relative rounded-2xl p-6 flex flex-col ${
                plan.highlight
                  ? 'bg-white/10 border-2 border-purple-500 shadow-2xl shadow-purple-500/20 scale-105'
                  : 'bg-white/5 border border-white/10'
              }`}
            >
              {plan.highlight && (
                <div className="absolute -top-3.5 left-1/2 -translate-x-1/2">
                  <span className="bg-gradient-to-r from-purple-600 to-pink-600 text-white text-xs font-bold px-4 py-1 rounded-full">
                    MOST POPULAR
                  </span>
                </div>
              )}

              <div className={`w-10 h-10 rounded-xl bg-gradient-to-br ${plan.color} mb-4`} />
              <h2 className="text-xl font-bold text-white mb-1">{plan.name}</h2>
              <p className="text-gray-400 text-sm mb-4">{plan.description}</p>

              <div className="mb-6">
                <span className="text-4xl font-bold text-white">{plan.price}</span>
                <span className="text-gray-400 text-sm">{plan.period}</span>
              </div>

              <ul className="space-y-2.5 mb-8 flex-1">
                {plan.features.map((f) => (
                  <li key={f} className="flex items-center gap-2.5 text-sm text-gray-300">
                    <span className="text-green-400 text-base">✓</span>
                    {f}
                  </li>
                ))}
              </ul>

              <Link
                href={plan.href}
                className={`w-full py-3 rounded-xl text-center font-semibold text-sm transition ${
                  plan.highlight
                    ? 'bg-gradient-to-r from-purple-600 to-pink-600 text-white hover:opacity-90'
                    : 'bg-white/10 text-white hover:bg-white/20 border border-white/10'
                }`}
              >
                {plan.cta}
              </Link>
            </div>
          ))}
        </div>

        {/* FAQ strip */}
        <div className="bg-white/5 border border-white/10 rounded-2xl p-8 text-center">
          <p className="text-gray-300 text-sm">
            All plans include a <span className="text-white font-semibold">14-day free trial</span>. No credit card required.
            Questions? <a href="mailto:hello@attendanceai.com" className="text-purple-400 hover:text-purple-300 underline">Talk to us</a>.
          </p>
        </div>

        <div className="text-center mt-8">
          <Link href="/" className="text-gray-500 hover:text-gray-300 text-sm transition">← Back to home</Link>
        </div>
      </div>
    </div>
  );
}
