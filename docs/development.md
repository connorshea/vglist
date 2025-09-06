# Development Environment

This directory contains configuration for setting up a development environment for vglist.

## Quick Start

### Option 1: Docker Compose (Recommended)

The easiest way to get started is using Docker Compose:

```bash
# Run the setup script
./bin/setup-dev

# Or manually:
docker-compose up -d --build
docker-compose exec web bundle exec rails db:setup
```

This will start:
- Rails app on http://localhost:3000
- Webpack dev server on http://localhost:3035
- PostgreSQL database on localhost:5432
- Redis on localhost:6379

### Option 2: VS Code Dev Containers

1. Install the "Dev Containers" extension in VS Code
2. Open the project in VS Code
3. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS)
4. Type "Dev Containers: Reopen in Container"
5. Wait for the container to build and the environment to set up

### Option 3: Local Setup

Follow the instructions in [CONTRIBUTING.md](../CONTRIBUTING.md) for local setup.

## Services

- **web**: Rails application server
- **webpack**: Webpack development server for hot reloading
- **db**: PostgreSQL 17 database
- **redis**: Redis for caching and background jobs

## Useful Commands

```bash
# View logs
docker-compose logs -f

# Access Rails console
docker-compose exec web bundle exec rails console

# Run tests
docker-compose exec web bundle exec rspec

# Access database
docker-compose exec db psql -U vglist -d vglist_development

# Stop services
docker-compose down

# Rebuild services
docker-compose up -d --build
```

## Environment Variables

The development environment uses these default environment variables:

- `DATABASE_URL`: PostgreSQL connection string
- `VGLIST_DATABASE_PASSWORD`: Database password (default: "password")
- `REDIS_URL`: Redis connection string
- `RAILS_ENV`: Set to "development"

You can override these by creating a `.env` file in the project root.

## Troubleshooting

### Database Connection Issues
If you get database connection errors:
1. Make sure PostgreSQL is running: `docker-compose ps`
2. Check the database logs: `docker-compose logs db`
3. Restart the database: `docker-compose restart db`

### Port Conflicts
If ports 3000, 3035, 5432, or 6379 are already in use:
1. Stop the conflicting services
2. Or modify the port mappings in `docker-compose.yml`

### Permission Issues
If you get permission errors with volumes:
```bash
sudo chown -R $USER:$USER .
```