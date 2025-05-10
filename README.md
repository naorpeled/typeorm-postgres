# PostgreSQL with PostGIS and pgvector for TypeORM

This Docker image extends the official PostgreSQL image with PostGIS and pgvector extensions, specifically designed for TypeORM development and testing environments. It provides a configurable PostgreSQL instance with spatial and vector search capabilities.

## Use Cases

- **TypeORM Testing**: Drop-in replacement for PostgreSQL in TypeORM test suites.
- **Development**: Local development with TypeORM projects requiring PostGIS or pgvector.
- **CI/CD**: GitHub Actions and other CI environments for TypeORM projects.

## Pre-built Images

Pre-built images are available on GitHub Container Registry (GHCR). Replace `yourusername/yourrepositoryname` with your actual GHCR path (e.g., `ghcr.io/naorpeled/typeorm-postgres-docker`).

Example tags (refer to the `publish.yml` workflow matrix for all combinations):

- `ghcr.io/yourusername/yourrepositoryname:pg16-postgis3-pgvectorv0.8.0`
- `ghcr.io/yourusername/yourrepositoryname:latest` (points to the default latest combination)

## Build Arguments

The following build arguments can be used with `docker build --build-arg VAR=value` or via the `args` section in `docker-compose.yml` (which can use environment variables from your `.env` file):

- `PG_MAJOR_VERSION`: PostgreSQL major version (default: 16). In `docker-compose.yml`, fed by `PG_MAJOR` env var.
- `POSTGIS_MAJOR_VERSION`: PostGIS major version (default: 3). In `docker-compose.yml`, fed by `POSTGIS_MAJOR_VERSION` env var.
- `PGVECTOR_TAG`: pgvector version tag (e.g., `v0.8.0`, default: v0.8.0). In `docker-compose.yml`, fed by `PGVECTOR_VERSION` env var.

## Building the Image

```bash
# Build with default versions
docker build -t your-image-name .

# Build with custom versions (using Docker build args)
docker build \\
  --build-arg PG_MAJOR_VERSION=15 \\
  --build-arg POSTGIS_MAJOR_VERSION=3 \\
  --build-arg PGVECTOR_TAG=v0.7.2 \\
  -t your-image-name:custom .
```

## Running the Container

### Using `docker run`

To ensure pgvector is properly preloaded for optimal performance, pass the `shared_preload_libraries` setting to the `postgres` command. This is handled by the `command` directive in the provided `docker-compose.yml`.

```bash
docker run -d \\
  --name postgres-gis-vector \\
  -e POSTGRES_PASSWORD=yourpassword \\
  -e POSTGRES_USER=youruser \\
  -e POSTGRES_DB=yourdb \\
  -p 5432:5432 \\
  -v postgres_data_volume:/var/lib/postgresql/data \\
  your-image-name postgres -c shared_preload_libraries=vector
```

### Using `docker-compose.yml`

The provided `docker-compose.yml` is configured to build and run the image, including preloading pgvector via the `command` directive.

```yaml
# docker-compose.yml (snippet)
services:
  db:
    build:
      context: .
      args:
        PG_MAJOR_VERSION: ${PG_MAJOR:-16}
        POSTGIS_MAJOR_VERSION: ${POSTGIS_MAJOR_VERSION:-3}
        PGVECTOR_TAG: ${PGVECTOR_VERSION:-v0.8.0}
    command: postgres -c shared_preload_libraries=vector # Ensures pgvector preloading
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-test} # TypeORM test default
      POSTGRES_USER: ${POSTGRES_USER:-test} # TypeORM test default
      POSTGRES_DB: ${POSTGRES_DB:-test} # TypeORM test default
      # ... other environment variables ...
```

Create a `.env` file in the same directory as `docker-compose.yml` to set build arguments and PostgreSQL credentials (optional, defaults are provided):

```env
# .env (example)
PG_MAJOR=16
POSTGIS_MAJOR_VERSION=3
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

- `.github/workflows/test.yml`: Builds the Docker image with a matrix of PostgreSQL versions and pgvector tags, and runs basic extension checks. `POSTGIS_MAJOR_VERSION` is typically fixed (e.g., to 3) in these tests.
- `.github/workflows/publish.yml`: Builds and publishes the Docker image to GHCR on tagged releases (e.g., `v1.0.0`). The image name on GHCR will be based on your GitHub username/organization and repository name (e.g., `ghcr.io/yourusername/yourrepositoryname`).

## TypeORM Compatibility

This image is configured to be a drop-in replacement for PostgreSQL in TypeORM projects.

- Default credentials in `docker-compose.yml` (`test`/`test`/`test`) match common TypeORM test configurations.
- Ensure your TypeORM datasource configuration matches the environment variables used (e.g., `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `POSTGRES_PORT`).
- The image ensures `pgvector` is preloaded via `shared_preload_libraries=vector` when run with the provided `docker-compose.yml` or an equivalent `docker run` command, which is crucial for some pgvector features and performance.

This setup ensures that TypeORM can connect and utilize PostGIS and pgvector functionalities seamlessly.

## Environment Variables

Inherits all environment variables from the official PostgreSQL image. See the [official PostgreSQL image documentation](https://hub.docker.com/_/postgres/) for details.

The build arguments `PG_MAJOR_VERSION`, `POSTGIS_MAJOR_VERSION`, and `PGVECTOR_TAG` are also exposed as environment variables with the same names within the running container for runtime inspection.

Additional runtime environment variables for the entrypoint script:

- `ADDITIONAL_DATABASES`: Comma-separated list of additional databases to create and initialize with extensions.

### Local Testing with `docker-compose.test.yml`

The repository includes `docker-compose.test.yml` for more comprehensive local testing that mirrors some aspects of the CI tests.

To run tests locally using this file:

```bash
# Build and test with default versions using environment variables from your .env or defaults
docker compose -f docker-compose.test.yml up --build --exit-code-from test

# Test with specific versions by setting environment variables for the compose command:
PG_MAJOR=15 POSTGIS_MAJOR_VERSION=3 PGVECTOR_VERSION=v0.7.2 docker compose -f docker-compose.test.yml up --build --exit-code-from test
```

## License

MIT
