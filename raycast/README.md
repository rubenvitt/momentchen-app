# Momentchen Raycast Extension

A Raycast extension to capture and search your moments with Notion integration.

## Features

- **Create Moment**: Quickly capture a new moment with type, timestamp, and favorites
- **Search Moments**: Browse and filter your moments by type, date, or favorites
- **Smart Caching**: Automatic caching with background refresh for fast loading
- **Offline Access**: View cached moments even without internet connection
- **Cache Management**: Inspect and control cache behavior

## Setup

### Prerequisites

1. A Notion integration token (create one at https://www.notion.so/my-integrations)
2. A Notion database for your moments with the following properties:
   - **Name** (Title): The moment description
   - **Zeitpunkt** (Date): When the moment occurred
   - **Typ** (Select): Type of moment (learning, improvement, feeling, miss, etc.)
   - **⭐ Tagesfavorit** (Checkbox): Daily favorite marker
   - **⭐ Wochenfavorit** (Checkbox): Weekly favorite marker
   - **⭐ Monatsfavorit** (Checkbox): Monthly favorite marker
   - **⭐ Jahresfavorit** (Checkbox): Yearly favorite marker
   - **Moment meines Lebens** (Checkbox): Lifetime moment marker
   - **Lebensbereich** (Relation): Life area (optional, links to life areas database)
   - **Projekt** (Relation): Project (optional, links to projects database)
3. Optional: Separate databases for projects and life areas
   - Each should have a **Name** or **Title** property
   - Link them to your moments database via relations
   - The extension will automatically load these for selection when creating moments

### Installation

1. Clone this repository
2. Run `npm install` in the `raycast` directory
3. Configure the extension in Raycast:
   - Set your Notion Integration Token
   - Set your Moments Database ID
4. Run `npm run dev` to start development mode

## Configuration

Open Raycast preferences for the Momentchen extension and configure:

- **Notion Integration Token**: Your internal integration token from Notion
- **Moments Database ID**: The ID of your moments database (found in the database URL)

## Usage

### Create a Moment

1. Open Raycast
2. Search for "Create Moment"
3. Fill in:
   - **Beschreibung**: Title/description of the moment
   - **Typ**: Select the moment type (learning, improvement, feeling, etc.)
   - **Zeitpunkt**: Choose the timestamp (defaults to now)
   - **Kategorie** (optional): Assign to a project or life area
     - Select "Projekt" and choose from your projects
     - Select "Lebensbereich" and choose from your life areas
     - Or leave as "Keine Kategorie"
4. Press Enter to save

**Note**: Favorite status (daily/weekly/monthly/yearly) is set later during reviews, not when creating a moment.

### Search Moments

1. Open Raycast
2. Search for "Search Moments"
3. Browse your moments or filter by:
   - Search text
   - Moment type
   - Favorite markers
   - Moments are sorted by date (newest first)
   - See project/life area icons (📁/🌱) in the list
4. Use keyboard shortcuts:
   - `Cmd+R` - Refresh from Notion
   - `Cmd+Shift+C` - Cache Management
   - `Cmd+.` - Copy Moment ID

### Caching

The extension automatically caches your moments for fast loading:

- **Automatic Refresh**: Data is cached for 5 minutes
- **Background Sync**: Updates automatically when you open the extension
- **Offline Mode**: View cached moments without internet
- **Smart Loading**: Shows cached data while fetching updates
- **Manual Control**: Use `Cmd+R` to force refresh or manage cache via `Cmd+Shift+C`
- **Smart Invalidation**: Cache is automatically cleared when you create new moments

Cache is stored locally and persists across sessions.

**How it works:**
1. Create a new moment → Cache is invalidated
2. Open Search Moments → Automatically loads fresh data from Notion
3. Your new moment appears immediately in the list

See `CACHING.md` for advanced cache management.

## Development

```bash
# Install dependencies
npm install

# Start development mode
npm run dev

# Build for production
npm run build

# Lint and format
npm run lint
npm run fix-lint
```

## Architecture

The extension follows clean architecture principles:

- `src/api/notion.ts` - Notion API client with all HTTP communication
- `src/types/` - TypeScript types matching the Moment domain model
- `src/commands/` - Raycast command implementations
- `src/utils/` - Shared utilities (date formatting, color mapping, etc.)

## License

MIT
