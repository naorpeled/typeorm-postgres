# PostgreSQL with PostGIS and pgvector for TypeORM

This Docker image extends the official PostgreSQL image with PostGIS and pgvector extensions, specifically designed for TypeORM development and testing environments. It provides a configurable PostgreSQL instance with spatial and vector search capabilities.

## Use Cases

- **TypeORM Testing**: Drop-in replacement for PostgreSQL in TypeORM test suites.
- **Development**: Local development with TypeORM projects requiring PostGIS or pgvector.
- **CI/CD**: GitHub Actions and other CI environments for TypeORM projects.

## Pre-built Images

Pre-built images are available on GitHub Container Registry (GHCR). Replace `yourusername/postgis_pgvector` with your actual image path.

- `ghcr.io/yourusername/postgis_pgvector:pg16-pgvectorv0.8.0` (also tagged as `latest`)
- `ghcr.io/yourusername/postgis_pgvector:pg15-pgvectorv0.8.0`
- `ghcr.io/yourusername/postgis_pgvector:pg16-pgvectorv0.7.2`
- `ghcr.io/yourusername/postgis_pgvector:pg15-pgvectorv0.7.2`

(Note: Update image tags based on your publishing workflow in `.github/workflows/publish.yml`)

## Build Arguments

The following build arguments can be used with `docker build --build-arg VAR=value` or via the `args` section in `docker-compose.yml` (which can use environment variables):

- `MY_PG_VER`: PostgreSQL major version (default: 16). Corresponds to environment variable `PG_MAJOR` in `docker-compose.yml`.
- `MY_POSTGIS_VER`: PostGIS major version (default: 3). Corresponds to environment variable `POSTGIS_MAJOR_VERSION` in `docker-compose.yml`.
- `MY_PGVECTOR_VER`: pgvector version tag (default: v0.8.0). Corresponds to environment variable `PGVECTOR_VERSION` in `docker-compose.yml`.

## Building the Image

```bash
# Build with default versions
docker build -t your-image-name .

# Build with custom versions (using Docker build args)
docker build \
  --build-arg MY_PG_VER=15 \
  --build-arg MY_POSTGIS_VER=3 \
  --build-arg MY_PGVECTOR_VER=v0.7.2 \
  -t your-image-name:custom .
```

## Running the Container

### Using `docker run`

To ensure pgvector is properly preloaded for optimal performance (especially for certain index types), pass the `shared_preload_libraries` setting to the `postgres` command:

```bash
docker run -d \
  --name postgres-gis-vector \
  -e POSTGRES_PASSWORD=yourpassword \
  -e POSTGRES_USER=youruser \
  -e POSTGRES_DB=yourdb \
  -p 5432:5432 \
  -v postgres_data_volume:/var/lib/postgresql/data \
  your-image-name postgres -c shared_preload_libraries=vector
```

### Using `docker-compose.yml`

The provided `docker-compose.yml` can be used to build and run the image. To enable pgvector preloading, add the `command` directive to the `db` service:

```yaml
version: "3.8"

services:
  db:
    build:
      context: .
      args:
        MY_PG_VER: ${PG_MAJOR:-16}
        MY_POSTGIS_VER: ${POSTGIS_MAJOR_VERSION:-3}
        MY_PGVECTOR_VER: ${PGVECTOR_VERSION:-v0.8.0}
    command: postgres -c shared_preload_libraries=vector # Add this line for pgvector
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-test} # TypeORM test default
      POSTGRES_USER: ${POSTGRES_USER:-test} # TypeORM test default
      POSTGRES_DB: ${POSTGRES_DB:-test} # TypeORM test default
      ADDITIONAL_DATABASES: ${ADDITIONAL_DATABASES:-}
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-test}"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

Create a `.env` file in the same directory as `docker-compose.yml` to set environment variables for compose (optional, defaults are provided):

```env
# .env (example)
PG_MAJOR=16
POSTGRES_MAJOR_VERSION=3
PGVECTOR_VERSION=v0.8.0

POSTGRES_PASSWORD=supersecret
POSTGRES_USER=myuser
POSTGRES_DB=mydb
POSTGRES_PORT=5432
# ADDITIONAL_DATABASES=db1,db2
```

Then run:

```bash
docker compose up --build -d
```

## GitHub Actions

This repository includes GitHub Actions workflows:

- `test.yml`: Builds the Docker image with a matrix of PostgreSQL and pgvector versions and runs basic extension checks.
- `publish.yml`: Builds and publishes the Docker image to GHCR on tagged releases (e.g., `v1.0.0`). Ensure you update `IMAGE_NAME` in the workflow to your desired GHCR path (e.g., `yourusername/yourrepository`).

## TypeORM Compatibility

This image is configured to be a drop-in replacement for PostgreSQL in TypeORM projects.

- Default credentials in `docker-compose.yml` (`test`/`test`/`test`) match common TypeORM test configurations.
- Ensure your TypeORM datasource configuration matches the environment variables used (e.g., `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `POSTGRES_PORT`).

This setup ensures that TypeORM can connect and utilize PostGIS and pgvector functionalities seamlessly.

## Environment Variables

Inherits all environment variables from the official PostgreSQL image. See the [official PostgreSQL image documentation](https://hub.docker.com/_/postgres/) for details.

Additional environment variables:

- `ADDITIONAL_DATABASES`: Comma-separated list of additional databases to create and initialize with extensions

### Testing

The repository includes GitHub Actions workflows that:

1. Test the image build with different PostgreSQL and pgvector versions
2. Verify that PostGIS and pgvector extensions work correctly
3. Test creation and initialization of additional databases

To run tests locally:

```bash
# Build and test with default versions
docker build -t postgres-postgis-pgvector:test .
docker-compose -f docker-compose.test.yml up --exit-code-from test

# Test with specific versions
PG_MAJOR=15 PGVECTOR_VERSION=v0.7.2 docker-compose -f docker-compose.test.yml up --exit-code-from test
```

## License

MIT
