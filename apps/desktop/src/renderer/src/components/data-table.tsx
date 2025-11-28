'use client'

import * as React from 'react'
import {
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  useReactTable,
  type ColumnDef,
  type ColumnFiltersState,
  type SortingState
} from '@tanstack/react-table'
import {
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  ChevronLeft,
  ChevronRight,
  Copy,
  ChevronsLeft,
  ChevronsRight,
  Filter,
  X,
  Braces,
  Check,
  ChevronDown,
  ChevronRightIcon,
  Link2,
  ExternalLink
} from 'lucide-react'
import type { ForeignKeyInfo } from '@data-peek/shared'
import { Input } from '@/components/ui/input'

import { Button } from '@/components/ui/button'
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetDescription
} from '@/components/ui/sheet'
import {
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow
} from '@/components/ui/table'
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger
} from '@/components/ui/tooltip'
import { Badge } from '@/components/ui/badge'

// Export types for parent components
export interface DataTableFilter {
  column: string
  value: string
}

export interface DataTableSort {
  column: string
  direction: 'asc' | 'desc'
}

export interface DataTableColumn {
  name: string
  dataType: string
  foreignKey?: ForeignKeyInfo
}

interface DataTableProps<TData> {
  columns: DataTableColumn[]
  data: TData[]
  pageSize?: number
  onFiltersChange?: (filters: DataTableFilter[]) => void
  onSortingChange?: (sorting: DataTableSort[]) => void
  /** Called when user clicks a FK cell (opens panel) */
  onForeignKeyClick?: (foreignKey: ForeignKeyInfo, value: unknown) => void
  /** Called when user Cmd+clicks a FK cell (opens new tab) */
  onForeignKeyOpenTab?: (foreignKey: ForeignKeyInfo, value: unknown) => void
}

function getTypeColor(type: string): string {
  const lower = type.toLowerCase()
  if (lower.includes('uuid')) return 'text-purple-400'
  if (lower.includes('varchar') || lower.includes('text') || lower.includes('char'))
    return 'text-green-400'
  if (
    lower.includes('int') ||
    lower.includes('numeric') ||
    lower.includes('decimal') ||
    lower.includes('bigint')
  )
    return 'text-blue-400'
  if (lower.includes('timestamp') || lower.includes('date') || lower.includes('time'))
    return 'text-orange-400'
  if (lower.includes('bool')) return 'text-yellow-400'
  return 'text-muted-foreground'
}

// Recursive JSON tree viewer component
function JsonTreeNode({
  keyName,
  value,
  depth = 0,
  isLast = true
}: {
  keyName?: string
  value: unknown
  depth?: number
  isLast?: boolean
}) {
  const [isExpanded, setIsExpanded] = React.useState(depth < 2)

  const isObject = value !== null && typeof value === 'object'
  const isArray = Array.isArray(value)
  const hasChildren = isObject && Object.keys(value as object).length > 0

  const getValueDisplay = () => {
    if (value === null) return <span className="text-orange-400">null</span>
    if (value === undefined) return <span className="text-muted-foreground">undefined</span>
    if (typeof value === 'boolean')
      return <span className="text-yellow-400">{value ? 'true' : 'false'}</span>
    if (typeof value === 'number') return <span className="text-blue-400">{value}</span>
    if (typeof value === 'string') {
      const truncated = value.length > 100 ? value.slice(0, 100) + '...' : value
      return <span className="text-green-400">"{truncated}"</span>
    }
    return null
  }

  if (!isObject) {
    return (
      <div className="flex items-start gap-1 py-0.5">
        {keyName !== undefined && (
          <>
            <span className="text-purple-400 shrink-0">"{keyName}"</span>
            <span className="text-muted-foreground shrink-0">:</span>
          </>
        )}
        {getValueDisplay()}
        {!isLast && <span className="text-muted-foreground">,</span>}
      </div>
    )
  }

  const entries = Object.entries(value as object)
  const bracketOpen = isArray ? '[' : '{'
  const bracketClose = isArray ? ']' : '}'

  return (
    <div className="py-0.5">
      <div className="flex items-center gap-1">
        {hasChildren && (
          <button
            onClick={() => setIsExpanded(!isExpanded)}
            className="p-0.5 hover:bg-accent/50 rounded shrink-0"
          >
            {isExpanded ? (
              <ChevronDown className="size-3 text-muted-foreground" />
            ) : (
              <ChevronRightIcon className="size-3 text-muted-foreground" />
            )}
          </button>
        )}
        {!hasChildren && <span className="w-4" />}
        {keyName !== undefined && (
          <>
            <span className="text-purple-400">"{keyName}"</span>
            <span className="text-muted-foreground">:</span>
          </>
        )}
        <span className="text-muted-foreground">{bracketOpen}</span>
        {!isExpanded && hasChildren && (
          <>
            <span className="text-muted-foreground/50 text-xs">
              {entries.length} {isArray ? 'items' : 'keys'}
            </span>
            <span className="text-muted-foreground">{bracketClose}</span>
          </>
        )}
        {!hasChildren && <span className="text-muted-foreground">{bracketClose}</span>}
        {!isLast && !isExpanded && <span className="text-muted-foreground">,</span>}
      </div>
      {isExpanded && hasChildren && (
        <div className="ml-4 border-l border-border/30 pl-2">
          {entries.map(([k, v], idx) => (
            <JsonTreeNode
              key={k}
              keyName={isArray ? undefined : k}
              value={v}
              depth={depth + 1}
              isLast={idx === entries.length - 1}
            />
          ))}
        </div>
      )}
      {isExpanded && hasChildren && (
        <div className="flex items-center gap-1">
          <span className="w-4" />
          <span className="text-muted-foreground">{bracketClose}</span>
          {!isLast && <span className="text-muted-foreground">,</span>}
        </div>
      )}
    </div>
  )
}

// JSON cell viewer with sheet popup
function JsonCellValue({ value, columnName }: { value: unknown; columnName?: string }) {
  const [isOpen, setIsOpen] = React.useState(false)
  const [copied, setCopied] = React.useState(false)

  const handleCopy = () => {
    const jsonStr = typeof value === 'string' ? value : JSON.stringify(value, null, 2)
    navigator.clipboard.writeText(jsonStr)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  if (value === null || value === undefined) {
    return <span className="text-muted-foreground/50 italic">NULL</span>
  }

  // Parse JSON if it's a string
  let parsedValue = value
  if (typeof value === 'string') {
    try {
      parsedValue = JSON.parse(value)
    } catch {
      parsedValue = value
    }
  }

  const isObject = parsedValue !== null && typeof parsedValue === 'object'
  const preview = isObject
    ? Array.isArray(parsedValue)
      ? `[${parsedValue.length} items]`
      : `{${Object.keys(parsedValue).length} keys}`
    : String(parsedValue)

  return (
    <>
      <button
        onClick={() => setIsOpen(true)}
        className="flex items-center gap-1.5 text-left hover:bg-accent/50 px-1.5 py-0.5 -mx-1 rounded transition-colors group"
      >
        <Braces className="size-3.5 text-amber-500 shrink-0" />
        <span className="font-mono text-xs text-muted-foreground group-hover:text-foreground truncate max-w-[200px]">
          {preview}
        </span>
      </button>

      <Sheet open={isOpen} onOpenChange={setIsOpen}>
        <SheetContent side="right" className="w-[500px] sm:max-w-[500px] flex flex-col">
          <SheetHeader className="shrink-0">
            <SheetTitle className="flex items-center gap-2">
              <Braces className="size-4 text-amber-500" />
              {columnName || 'JSON'} Data
            </SheetTitle>
            <SheetDescription>View and copy JSON content</SheetDescription>
          </SheetHeader>

          <div className="flex-1 min-h-0 flex flex-col gap-3">
            {/* Toolbar */}
            <div className="flex items-center gap-2 shrink-0">
              <Button
                variant="outline"
                size="sm"
                className="gap-1.5 h-7"
                onClick={handleCopy}
              >
                {copied ? (
                  <>
                    <Check className="size-3 text-green-500" />
                    Copied!
                  </>
                ) : (
                  <>
                    <Copy className="size-3" />
                    Copy JSON
                  </>
                )}
              </Button>
            </div>

            {/* JSON Tree View */}
            <div className="flex-1 min-h-0 overflow-auto bg-muted/30 rounded-lg border border-border/50 p-3">
              <div className="font-mono text-xs leading-relaxed">
                <JsonTreeNode value={parsedValue} />
              </div>
            </div>

            {/* Raw JSON */}
            <div className="shrink-0">
              <p className="text-xs text-muted-foreground mb-1.5">Raw JSON</p>
              <div className="max-h-32 overflow-auto bg-muted/30 rounded-lg border border-border/50 p-2">
                <pre className="font-mono text-[10px] text-muted-foreground whitespace-pre-wrap break-all">
                  {typeof value === 'string' ? value : JSON.stringify(parsedValue, null, 2)}
                </pre>
              </div>
            </div>
          </div>
        </SheetContent>
      </Sheet>
    </>
  )
}

// Foreign key cell with click-to-navigate functionality
function ForeignKeyCellValue({
  value,
  foreignKey,
  onForeignKeyClick,
  onForeignKeyOpenTab
}: {
  value: unknown
  foreignKey: ForeignKeyInfo
  onForeignKeyClick?: (foreignKey: ForeignKeyInfo, value: unknown) => void
  onForeignKeyOpenTab?: (foreignKey: ForeignKeyInfo, value: unknown) => void
}) {
  if (value === null || value === undefined) {
    return <span className="text-muted-foreground/50 italic">NULL</span>
  }

  const stringValue = String(value)
  const isLong = stringValue.length > 30
  const displayValue = isLong ? stringValue.substring(0, 30) + '...' : stringValue

  const handleClick = (e: React.MouseEvent) => {
    if (e.metaKey || e.ctrlKey) {
      // Cmd+Click: Open in new tab
      onForeignKeyOpenTab?.(foreignKey, value)
    } else {
      // Normal click: Open panel
      onForeignKeyClick?.(foreignKey, value)
    }
  }

  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <button
            onClick={handleClick}
            className="group flex items-center gap-1 text-left text-blue-400 hover:text-blue-300 hover:underline cursor-pointer font-mono text-xs px-1 -mx-1 rounded transition-colors"
          >
            <span className="truncate max-w-[200px]">{displayValue}</span>
            <ExternalLink className="size-3 opacity-0 group-hover:opacity-70 shrink-0 transition-opacity" />
          </button>
        </TooltipTrigger>
        <TooltipContent side="bottom" className="max-w-sm">
          <div className="space-y-1">
            <p className="text-xs font-medium">View in {foreignKey.referencedTable}</p>
            <p className="text-[10px] text-muted-foreground">
              Click to open panel, ⌘+Click for new tab
            </p>
            <pre className="text-xs text-muted-foreground font-mono mt-1">{stringValue}</pre>
          </div>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  )
}

function CellValue({
  value,
  dataType,
  columnName,
  foreignKey,
  onForeignKeyClick,
  onForeignKeyOpenTab
}: {
  value: unknown
  dataType: string
  columnName?: string
  foreignKey?: ForeignKeyInfo
  onForeignKeyClick?: (foreignKey: ForeignKeyInfo, value: unknown) => void
  onForeignKeyOpenTab?: (foreignKey: ForeignKeyInfo, value: unknown) => void
}) {
  const [copied, setCopied] = React.useState(false)
  const lowerType = dataType.toLowerCase()

  // Handle JSON/JSONB types specially
  if (lowerType.includes('json')) {
    return <JsonCellValue value={value} columnName={columnName} />
  }

  // Handle Foreign Key columns
  if (foreignKey && value !== null && value !== undefined) {
    return (
      <ForeignKeyCellValue
        value={value}
        foreignKey={foreignKey}
        onForeignKeyClick={onForeignKeyClick}
        onForeignKeyOpenTab={onForeignKeyOpenTab}
      />
    )
  }

  const handleCopy = () => {
    navigator.clipboard.writeText(String(value ?? ''))
    setCopied(true)
    setTimeout(() => setCopied(false), 1500)
  }

  if (value === null || value === undefined) {
    return <span className="text-muted-foreground/50 italic">NULL</span>
  }

  const stringValue = String(value)
  const isLong = stringValue.length > 50
  const isMono = lowerType.includes('uuid') || lowerType.includes('int')

  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <button
            onClick={handleCopy}
            className={`text-left truncate max-w-[300px] hover:bg-accent/50 px-1 -mx-1 rounded transition-colors ${isMono ? 'font-mono text-xs' : ''}`}
          >
            {isLong ? stringValue.substring(0, 50) + '...' : stringValue}
          </button>
        </TooltipTrigger>
        <TooltipContent side="bottom" className="max-w-md">
          <div className="flex items-start gap-2">
            <pre className="text-xs whitespace-pre-wrap break-all flex-1">{stringValue}</pre>
            <Button variant="ghost" size="icon" className="size-6 shrink-0" onClick={handleCopy}>
              <Copy className="size-3" />
            </Button>
          </div>
          {copied && <p className="text-xs text-green-500 mt-1">Copied!</p>}
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  )
}

export function DataTable<TData extends Record<string, unknown>>({
  columns: columnDefs,
  data,
  pageSize = 50,
  onFiltersChange,
  onSortingChange,
  onForeignKeyClick,
  onForeignKeyOpenTab
}: DataTableProps<TData>) {
  const [sorting, setSorting] = React.useState<SortingState>([])
  const [columnFilters, setColumnFilters] = React.useState<ColumnFiltersState>([])
  const [showFilters, setShowFilters] = React.useState(false)

  // Notify parent of filter changes
  React.useEffect(() => {
    if (onFiltersChange) {
      const filters: DataTableFilter[] = columnFilters
        .filter((f) => f.value !== '')
        .map((f) => ({
          column: f.id,
          value: String(f.value)
        }))
      onFiltersChange(filters)
    }
  }, [columnFilters, onFiltersChange])

  // Notify parent of sorting changes
  React.useEffect(() => {
    if (onSortingChange) {
      const sorts: DataTableSort[] = sorting.map((s) => ({
        column: s.id,
        direction: s.desc ? 'desc' : 'asc'
      }))
      onSortingChange(sorts)
    }
  }, [sorting, onSortingChange])

  // Generate TanStack Table columns from column definitions
  const columns = React.useMemo<ColumnDef<TData>[]>(
    () =>
      columnDefs.map((col) => ({
        accessorKey: col.name,
        header: ({ column }) => {
          const isSorted = column.getIsSorted()
          return (
            <div className="flex flex-col gap-0.5">
              <Button
                variant="ghost"
                className="h-auto py-1 px-2 -mx-2 font-medium hover:bg-accent/50"
                onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')}
              >
                <span>{col.name}</span>
                {col.foreignKey && (
                  <Link2 className="ml-1 size-3 text-blue-400" />
                )}
                <Badge
                  variant="outline"
                  className={`ml-1.5 text-[9px] px-1 py-0 font-mono ${getTypeColor(col.dataType)}`}
                >
                  {col.dataType}
                </Badge>
                {isSorted === 'asc' ? (
                  <ArrowUp className="ml-1 size-3 text-primary" />
                ) : isSorted === 'desc' ? (
                  <ArrowDown className="ml-1 size-3 text-primary" />
                ) : (
                  <ArrowUpDown className="ml-1 size-3 opacity-50" />
                )}
              </Button>
              {col.foreignKey && (
                <span className="text-[9px] text-muted-foreground px-2 -mt-0.5">
                  → {col.foreignKey.referencedTable}
                </span>
              )}
            </div>
          )
        },
        cell: ({ getValue }) => (
          <CellValue
            value={getValue()}
            dataType={col.dataType}
            columnName={col.name}
            foreignKey={col.foreignKey}
            onForeignKeyClick={onForeignKeyClick}
            onForeignKeyOpenTab={onForeignKeyOpenTab}
          />
        ),
        filterFn: 'includesString'
      })),
    [columnDefs, onForeignKeyClick, onForeignKeyOpenTab]
  )

  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    state: {
      sorting,
      columnFilters
    },
    initialState: {
      pagination: {
        pageSize
      }
    }
  })

  const activeFilterCount = columnFilters.filter((f) => f.value !== '').length

  const clearAllFilters = () => {
    setColumnFilters([])
  }

  return (
    <div className="flex flex-col h-full min-h-0">
      {/* Filter Toggle Bar */}
      <div className="flex items-center justify-between px-2 py-1.5 border-b border-border/30 shrink-0">
        <div className="flex items-center gap-2">
          <Button
            variant={showFilters ? 'secondary' : 'ghost'}
            size="sm"
            className="h-7 gap-1.5 text-xs"
            onClick={() => setShowFilters(!showFilters)}
          >
            <Filter className="size-3" />
            Filter
            {activeFilterCount > 0 && (
              <Badge variant="secondary" className="ml-1 px-1.5 py-0 text-[10px]">
                {activeFilterCount}
              </Badge>
            )}
          </Button>
          {activeFilterCount > 0 && (
            <Button
              variant="ghost"
              size="sm"
              className="h-7 gap-1 text-xs text-muted-foreground"
              onClick={clearAllFilters}
            >
              <X className="size-3" />
              Clear all
            </Button>
          )}
        </div>
        <div className="text-xs text-muted-foreground">
          {table.getFilteredRowModel().rows.length} of {data.length} rows
        </div>
      </div>

      {/* Table with single scroll container */}
      <div className="flex-1 min-h-0 border rounded-lg border-border/50 relative">
        <div className="absolute inset-0 overflow-auto">
          <table className="w-full min-w-max caption-bottom text-sm">
            <TableHeader className="sticky top-0 bg-muted/95 backdrop-blur-sm z-10">
              {table.getHeaderGroups().map((headerGroup) => (
                <React.Fragment key={headerGroup.id}>
                  <TableRow className="hover:bg-transparent border-border/50">
                    {headerGroup.headers.map((header) => (
                      <TableHead
                        key={header.id}
                        className="h-10 text-xs font-medium text-muted-foreground whitespace-nowrap bg-muted/95"
                      >
                        {header.isPlaceholder
                          ? null
                          : flexRender(header.column.columnDef.header, header.getContext())}
                      </TableHead>
                    ))}
                  </TableRow>
                  {/* Filter Row */}
                  {showFilters && (
                    <TableRow className="hover:bg-transparent border-border/50 bg-muted/80">
                      {headerGroup.headers.map((header) => (
                        <TableHead key={`filter-${header.id}`} className="h-9 py-1 px-2 bg-muted/80">
                          {header.column.getCanFilter() ? (
                            <Input
                              placeholder={`Filter...`}
                              value={(header.column.getFilterValue() as string) ?? ''}
                              onChange={(e) => header.column.setFilterValue(e.target.value)}
                              className="h-7 text-xs bg-background/80"
                            />
                          ) : null}
                        </TableHead>
                      ))}
                    </TableRow>
                  )}
                </React.Fragment>
              ))}
            </TableHeader>
            <TableBody>
              {table.getRowModel().rows?.length ? (
                table.getRowModel().rows.map((row) => (
                  <TableRow
                    key={row.id}
                    className="hover:bg-accent/30 border-border/30 transition-colors"
                  >
                    {row.getVisibleCells().map((cell) => (
                      <TableCell key={cell.id} className="py-2 text-sm whitespace-nowrap">
                        {flexRender(cell.column.columnDef.cell, cell.getContext())}
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              ) : (
                <TableRow>
                  <TableCell colSpan={columns.length} className="h-24 text-center">
                    No results.
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </table>
        </div>
      </div>

      {/* Pagination */}
      <div className="flex items-center justify-between py-2 shrink-0">
        <div className="text-xs text-muted-foreground">
          {table.getFilteredRowModel().rows.length} row(s) total
        </div>
        <div className="flex items-center gap-2">
          <div className="text-xs text-muted-foreground">
            Page {table.getState().pagination.pageIndex + 1} of {table.getPageCount()}
          </div>
          <div className="flex items-center gap-1">
            <Button
              variant="outline"
              size="icon"
              className="size-7"
              onClick={() => table.setPageIndex(0)}
              disabled={!table.getCanPreviousPage()}
            >
              <ChevronsLeft className="size-3.5" />
            </Button>
            <Button
              variant="outline"
              size="icon"
              className="size-7"
              onClick={() => table.previousPage()}
              disabled={!table.getCanPreviousPage()}
            >
              <ChevronLeft className="size-3.5" />
            </Button>
            <Button
              variant="outline"
              size="icon"
              className="size-7"
              onClick={() => table.nextPage()}
              disabled={!table.getCanNextPage()}
            >
              <ChevronRight className="size-3.5" />
            </Button>
            <Button
              variant="outline"
              size="icon"
              className="size-7"
              onClick={() => table.setPageIndex(table.getPageCount() - 1)}
              disabled={!table.getCanNextPage()}
            >
              <ChevronsRight className="size-3.5" />
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}
