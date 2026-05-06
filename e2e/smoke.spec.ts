import { test, expect } from '@playwright/test'

/**
 * Smoke tests — unauthenticated flows only.
 * These run without credentials and verify the app serves correctly.
 */

test('landing page loads and shows sign in', async ({ page }) => {
  await page.goto('/')
  await expect(page).toHaveTitle(/Remembrall/)
  await expect(page.getByRole('link', { name: /sign in/i })).toBeVisible()
})

test('dashboard redirects unauthenticated users to home', async ({ page }) => {
  await page.goto('/dashboard')
  await expect(page).toHaveURL('/')
})

test('unknown remembrall redirects to dashboard when unauthenticated', async ({ page }) => {
  await page.goto('/remembrall/nonexistent-id')
  // Unauthenticated → redirects to home
  await expect(page).toHaveURL('/')
})
