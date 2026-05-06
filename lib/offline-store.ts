// Client-side only — do not import in server components or server actions.

const DB_NAME = 'remembrall-offline'
const STORE_NAME = 'check-states'
const DB_VERSION = 1

interface CheckState {
  remembrallId: string
  requirementId: string
  checked: boolean
  syncedAt: Date | null
}

function openDb(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, DB_VERSION)
    req.onupgradeneeded = (e) => {
      const db = (e.target as IDBOpenDBRequest).result
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        const store = db.createObjectStore(STORE_NAME, { keyPath: 'requirementId' })
        store.createIndex('remembrallId', 'remembrallId', { unique: false })
        store.createIndex('syncedAt', 'syncedAt', { unique: false })
      }
    }
    req.onsuccess = () => resolve(req.result)
    req.onerror = () => reject(req.error)
  })
}

export async function saveCheckState(
  remembrallId: string,
  requirementId: string,
  checked: boolean
): Promise<void> {
  const db = await openDb()
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_NAME, 'readwrite')
    const store = tx.objectStore(STORE_NAME)
    store.put({ remembrallId, requirementId, checked, syncedAt: null })
    tx.oncomplete = () => resolve()
    tx.onerror = () => reject(tx.error)
  })
}

export async function getCheckStates(remembrallId: string): Promise<CheckState[]> {
  const db = await openDb()
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_NAME, 'readonly')
    const store = tx.objectStore(STORE_NAME)
    const index = store.index('remembrallId')
    const req = index.getAll(remembrallId)
    req.onsuccess = () => resolve(req.result)
    req.onerror = () => reject(req.error)
  })
}

export async function getPendingSync(): Promise<CheckState[]> {
  const db = await openDb()
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_NAME, 'readonly')
    const store = tx.objectStore(STORE_NAME)
    const req = store.getAll()
    req.onsuccess = () => resolve(req.result.filter((r: CheckState) => r.syncedAt === null))
    req.onerror = () => reject(req.error)
  })
}

export async function markSynced(requirementId: string): Promise<void> {
  const db = await openDb()
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_NAME, 'readwrite')
    const store = tx.objectStore(STORE_NAME)
    const getReq = store.get(requirementId)
    getReq.onsuccess = () => {
      if (getReq.result) {
        store.put({ ...getReq.result, syncedAt: new Date() })
      }
      resolve()
    }
    getReq.onerror = () => reject(getReq.error)
    tx.onerror = () => reject(tx.error)
  })
}
