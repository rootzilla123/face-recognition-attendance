// instrumentation.ts — Next.js 15 instrumentation hook
// Loaded automatically when NEXT_PUBLIC_GLITCHTIP_DSN is set.
export async function register() {
  if (process.env.NEXT_PUBLIC_GLITCHTIP_DSN) {
    const Sentry = await import("@sentry/nextjs");
    Sentry.init({
      dsn: process.env.NEXT_PUBLIC_GLITCHTIP_DSN,
      tracesSampleRate: 0.2,
      environment: process.env.NODE_ENV,
    });
  }
}
