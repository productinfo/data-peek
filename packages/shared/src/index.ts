export interface ConnectionConfig {
  id: string;
  name: string;
  host: string;
  port: number;
  database: string;
  user: string;
  password?: string;
  ssl?: boolean;
}

/**
 * Supported database types
 */
export type DatabaseType = 'postgresql' | 'mysql' | 'sqlite';

/**
 * Field metadata from query results
 * The server resolves type names so the frontend stays database-agnostic
 */
export interface QueryField {
  name: string;
  /** Human-readable data type (e.g., 'varchar', 'integer', 'jsonb') */
  dataType: string;
  /** Original database-specific type ID (for advanced use cases) */
  dataTypeID?: number;
}

export interface QueryResult {
  rows: Record<string, unknown>[];
  fields: QueryField[];
  rowCount: number;
  durationMs: number;
}

export interface IpcResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

// ============================================
// Schema Types - Shared across all DB adapters
// ============================================

/**
 * Foreign key relationship metadata
 */
export interface ForeignKeyInfo {
  /** Constraint name in the database */
  constraintName: string;
  /** Schema containing the referenced table */
  referencedSchema: string;
  /** Referenced table name */
  referencedTable: string;
  /** Referenced column name */
  referencedColumn: string;
}

/**
 * Column metadata for a table or view
 * Compatible with: PostgreSQL, MySQL, SQLite
 */
export interface ColumnInfo {
  name: string;
  dataType: string;
  isNullable: boolean;
  isPrimaryKey: boolean;
  defaultValue?: string;
  /** Column position in the table (1-indexed) */
  ordinalPosition: number;
  /** Foreign key relationship (if this column references another table) */
  foreignKey?: ForeignKeyInfo;
}

/**
 * Table or view metadata
 */
export interface TableInfo {
  name: string;
  type: 'table' | 'view';
  columns: ColumnInfo[];
  /** Estimated row count (if available) */
  estimatedRowCount?: number;
}

/**
 * Schema/namespace metadata
 * Note: SQLite doesn't have schemas, will use 'main' as default
 */
export interface SchemaInfo {
  name: string;
  tables: TableInfo[];
}

/**
 * Complete database schema structure
 */
export interface DatabaseSchema {
  schemas: SchemaInfo[];
  /** When the schema was last fetched */
  fetchedAt: number;
}
