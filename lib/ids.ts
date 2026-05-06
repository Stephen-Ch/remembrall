import { randomUUID } from 'crypto'

export function createId(): string {
  return randomUUID().replace(/-/g, '').slice(0, 24)
}
