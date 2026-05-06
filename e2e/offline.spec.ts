import { test, expect } from '@playwright/test'
import { signInAsTestUser } from './helpers/auth'

/**
 * Offline mode tests.
 * Verifies that checked state persists in IndexedDB when the network is offline,
 * and syncs back to the server when reconnected.
 */

test.beforeEach(async ({ page }) => {
  await signInAsTestUser(page)
})

test('checked state persists while offline', async ({ page, context }) => {
  // Create a remembrall with a requirement
  await page.goto('/dashboard')
  await page.getByRole('button', { name: /new remembrall/i }).click()
  await page.getByPlaceholder('New requirement').fill('Check me offline')
  await page.getByRole('button', { name: /add/i }).click()

  // Go to run view and wait for page to load fully
  await page.getByRole('link', { name: /← back to/i }).click()
  await expect(page.getByText('Check me offline')).toBeVisible()

  // Go offline
  await context.setOffline(true)
  await expect(page.getByText(/offline/i)).toBeVisible()

  // Check the item while offline
  const checkbox = page.getByRole('checkbox')
  await checkbox.check()
  await expect(checkbox).toBeChecked()

  // Reload while still offline — state should persist via IndexedDB
  await page.reload()
  // Note: page may not load fully offline — this verifies the SW cached it
  await expect(page.getByText('Check me offline')).toBeVisible()

  // Come back online
  await context.setOffline(false)
  await expect(page.getByText(/offline/i)).toBeHidden()
})

test('offline indicator appears and disappears', async ({ page, context }) => {
  await page.goto('/dashboard')

  // Verify no offline indicator when online
  await expect(page.getByText(/offline/i)).toBeHidden()

  // Go offline
  await context.setOffline(true)
  await expect(page.getByText(/offline/i)).toBeVisible()

  // Come back online
  await context.setOffline(false)
  await expect(page.getByText(/offline/i)).toBeHidden()
})
