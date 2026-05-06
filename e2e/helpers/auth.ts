import { Page } from '@playwright/test'

/**
 * Sign in as a test user via the test-only auth endpoint.
 * Requires PLAYWRIGHT_TEST_MODE=true on the server.
 */
export async function signInAsTestUser(page: Page, email = 'playwright-test@remembrall.test') {
  const res = await page.request.post('/api/test/auth', {
    data: { email },
  })
  if (!res.ok()) throw new Error(`Test auth failed: ${res.status()} ${await res.text()}`)
}
