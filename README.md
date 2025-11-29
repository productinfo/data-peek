# data-peek

A minimal, fast, lightweight PostgreSQL client desktop application. Built for developers who want to quickly peek at their data without the bloat.

## Features

- **Fast** - Opens in under 2 seconds, low memory footprint
- **Query Editor** - Monaco editor with SQL syntax highlighting and autocomplete
- **Multi-tab Support** - Work with multiple queries simultaneously
- **Inline Editing** - Edit table data directly with INSERT/UPDATE/DELETE
- **ERD Visualization** - See table relationships visually
- **Query Plans** - Analyze query performance with EXPLAIN ANALYZE viewer
- **Dark/Light Mode** - Easy on the eyes
- **Keyboard-First** - Power users shouldn't need a mouse
- **Secure** - Connection credentials encrypted locally, no telemetry

## Installation

### Download

Download the latest release for your platform from [Releases](https://github.com/Rohithgilla12/data-peek/releases).

- **macOS**: `.dmg` (Intel & Apple Silicon)
- **Windows**: `.exe` installer
- **Linux**: `.AppImage` or `.deb`

### Build from Source

```bash
# Clone the repository
git clone https://github.com/Rohithgilla12/data-peek.git
cd data-peek

# Install dependencies
pnpm install

# Run in development mode
pnpm dev

# Build for your platform
pnpm build:mac    # macOS
pnpm build:win    # Windows
pnpm build:linux  # Linux
```

## Tech Stack

| Layer | Technology |
|-------|------------|
| Desktop | Electron |
| Frontend | React 19 + TypeScript |
| UI | shadcn/ui + Tailwind CSS |
| State | Zustand |
| Query Editor | Monaco |
| Database | pg (PostgreSQL driver) |

## Project Structure

```
apps/
  desktop/     # Electron desktop application
  web/         # Marketing website + licensing
packages/
  shared/      # Shared types for IPC
```

## Development

```bash
# Install dependencies
pnpm install

# Start desktop app with hot reload
pnpm dev

# Start web app
pnpm dev:web

# Lint all workspaces
pnpm lint

# Build desktop app
pnpm build
```

## License

MIT License - see [LICENSE](LICENSE) for details.

Pre-built binaries require a license for commercial use. See the license file for details on free vs. commercial use.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Support

- [GitHub Issues](https://github.com/Rohithgilla12/data-peek/issues) - Bug reports and feature requests
- Twitter/X: [@gillarohith](https://x.com/gillarohith)
