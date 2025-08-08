# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **NotionNext** - a static blog system built with Next.js + Notion API, deployed on Vercel. It's designed for content creators who want to use Notion as their CMS while maintaining a modern, fast blog website with multiple theme options.

## Key Architecture

- **Framework**: Next.js 14.2.4 with React 18
- **Data Source**: Notion API (notion-client v7.3.0) 
- **Styling**: Tailwind CSS with theme-specific customizations
- **Content Rendering**: react-notion-x for converting Notion blocks to React components
- **Multi-theme System**: Dynamic theme loading with 20+ built-in themes (heo, hexo, next, medium, etc.)
- **Caching**: Multi-layer caching (memory, Redis, local file) via `/lib/cache/`
- **Internationalization**: Built-in i18n support with dynamic locale detection

## Essential Commands

### Development
```bash
yarn dev          # Start development server
yarn build        # Build for production  
yarn start        # Start production server on port 3001
```

### Production Management
```bash
./start_yarn.sh   # Start server with PID tracking (port 3001)
./update.sh       # Full update: stash configs, pull upstream, restore configs, rebuild, restart
```

### Analysis & Export
```bash
yarn bundle-report    # Analyze bundle size
yarn export           # Static export build
yarn post-build       # Generate sitemap after build
```

## Core Configuration

- **`blog.config.js`**: Main configuration hub that imports modular configs from `/conf/` directory
- **`/conf/` directory**: Modular configuration files for different features (comments, analytics, plugins, etc.)
- **Environment variables**: Most settings can be overridden via `process.env.NEXT_PUBLIC_*`

## Theme System Architecture

- **Theme Location**: `/themes/{theme-name}/` - each theme is self-contained
- **Dynamic Loading**: Themes are loaded dynamically via webpack aliases and Next.js dynamic imports
- **Theme Structure**: Each theme has `index.js`, `config.js`, `style.js`, and `/components/` folder
- **Current Theme**: Controlled by `BLOG.THEME` in config, can be overridden via URL parameter `?theme=themename`

## Key Directories

- **`/components/`**: Global shared components (analytics, SEO, plugins, etc.)
- **`/lib/notion/`**: Notion API integration and data fetching logic
- **`/lib/cache/`**: Caching system implementation (memory, Redis, file-based)
- **`/pages/`**: Next.js pages with dynamic routing for posts, categories, tags
- **`/hooks/`**: Custom React hooks
- **`/conf/`**: Modular configuration files

## Important Files

- **`middleware.ts`**: Next.js middleware for request handling
- **`next.config.js`**: Next.js configuration with theme aliases and multi-language support  
- **`tailwind.config.js`**: Tailwind CSS configuration
- **Deployment scripts**: `start_yarn.sh`, `update.sh` for production management

## Data Flow

1. **Content**: Notion database → `lib/notion/` API calls → cached data → pages
2. **Themes**: URL/config determines theme → dynamic import → components rendered
3. **Multi-language**: URL prefix detection → locale-specific Notion page IDs → localized content

## Development Notes

- **ESLint**: Configured but ignored during builds (`ignoreDuringBuilds: true`)
- **TypeScript**: Mixed JS/TS codebase with `.ts` files for type-sensitive areas
- **No testing framework** currently configured
- **Caching**: Essential for performance - understand cache invalidation when modifying data-fetching logic
- **Multi-language setup**: Uses comma-separated Notion page IDs with language prefixes (e.g., `en:pageId`)