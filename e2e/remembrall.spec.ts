import { test, expect } from '@playwright/test'
import { signInAsTestUser } from './helpers/auth'

/**
 * Authenticated Remembrall flow tests.
 * Requires: PLAYWRIGHT_TEST_MODE=true, running app with DB connection.
 */

test.beforeEach(async ({ page }) => {
  await signInAsTestUser(page)
})

test('can create a Remembrall and see it on dashboard', async ({ page }) => {
  await page.goto('/dashboard')
  await expect(page.getByRole('heading', { name: /my remembralls/i })).toBeVisible()

  // Create one
  await page.getByRole('button', { name: /new remembrall/i }).click()

  // Should redirect to edit page
  await expect(page).toHaveURL(/\/remembrall\/.+\/edit/)
  await expect(page.getByRole('heading', { name: /edit/i })).toBeVisible()
})

test('can add a requirement to a Remembrall', async ({ page }) => {
  // Create via dashboard
  await page.goto('/dashboard')
  await page.getByRole('button', { name: /new remembrall/i }).click()
  await expect(page).toHaveURL(/\/remembrall\/.+\/edit/)

  // Add a requirement
  await page.getByPlaceholder('New requirement').fill('Pack the tent')
  await page.getByRole('button', { name: /add/i }).click()

  // Requirement appears in list
  await expect(page.getByText('Pack the tent')).toBeVisible()
})

test('can check off a requirement on the run page', async ({ page }) => {
  // Create a remembrall with a requirement
  await page.goto('/dashboard')
  await page.getByRole('button', { name: /new remembrall/i }).click()
  await page.getByPlaceholder('New requirement').fill('Bring sunscreen')
  await page.getByRole('button', { name: /add/i }).click()

  // Navigate to run view
  await page.getByRole('link', { name: /← back to/i }).click()

  // Check the item
  const checkbox = page.getByRole('checkbox')
  await expect(checkbox).not.toBeChecked()
  await checkbox.check()
  await expect(checkbox).toBeChecked()

  // Text should be struck through
  await expect(page.getByText('Bring sunscreen')).toHaveCSS('text-decoration-line', 'line-through')
})
