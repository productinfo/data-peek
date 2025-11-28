import { contextBridge, ipcRenderer } from 'electron'
import { electronAPI } from '@electron-toolkit/preload'
import type {
  ConnectionConfig,
  IpcResponse,
  DatabaseSchema,
  EditBatch,
  EditResult
} from '@shared/index'

// Custom APIs for renderer
const api = {
  // Connection management
  connections: {
    list: (): Promise<IpcResponse<ConnectionConfig[]>> => ipcRenderer.invoke('connections:list'),
    add: (connection: ConnectionConfig): Promise<IpcResponse<ConnectionConfig>> =>
      ipcRenderer.invoke('connections:add', connection),
    update: (connection: ConnectionConfig): Promise<IpcResponse<ConnectionConfig>> =>
      ipcRenderer.invoke('connections:update', connection),
    delete: (id: string): Promise<IpcResponse<void>> => ipcRenderer.invoke('connections:delete', id)
  },
  // Database operations
  db: {
    connect: (config: ConnectionConfig): Promise<IpcResponse<void>> =>
      ipcRenderer.invoke('db:connect', config),
    query: (config: ConnectionConfig, query: string): Promise<IpcResponse<unknown>> =>
      ipcRenderer.invoke('db:query', { config, query }),
    schemas: (config: ConnectionConfig): Promise<IpcResponse<DatabaseSchema>> =>
      ipcRenderer.invoke('db:schemas', config),
    execute: (config: ConnectionConfig, batch: EditBatch): Promise<IpcResponse<EditResult>> =>
      ipcRenderer.invoke('db:execute', { config, batch }),
    previewSql: (
      batch: EditBatch
    ): Promise<IpcResponse<Array<{ operationId: string; sql: string }>>> =>
      ipcRenderer.invoke('db:preview-sql', { batch }),
    explain: (
      config: ConnectionConfig,
      query: string,
      analyze: boolean
    ): Promise<IpcResponse<{ plan: unknown; durationMs: number }>> =>
      ipcRenderer.invoke('db:explain', { config, query, analyze })
  }
}

// Use `contextBridge` APIs to expose Electron APIs to
// renderer only if context isolation is enabled, otherwise
// just add to the DOM global.
if (process.contextIsolated) {
  try {
    contextBridge.exposeInMainWorld('electron', electronAPI)
    contextBridge.exposeInMainWorld('api', api)
  } catch (error) {
    console.error(error)
  }
} else {
  // @ts-ignore (define in dts)
  window.electron = electronAPI
  // @ts-ignore (define in dts)
  window.api = api
}

// Type declarations for renderer
export type Api = typeof api
