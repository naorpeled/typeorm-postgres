# PostgreSQL with PostGIS and pgvector for TypeORM

This Docker image extends the official PostgreSQL image with PostGIS and pgvector extensions, specifically designed for TypeORM's testing. It provides a configurable PostgreSQL instance with spatial and vector search capabilities.

Pre-built images are available on GitHub Container Registry (GHCR). The following tags are available:

- `ghcr.io/naorpeled/postgis_pgvector:pg16-pgvectorv0.8.0` (also tagged as `latest`)
- `ghcr.io/naorpeled/postgis_pgvector:pg15-pgvectorv0.8.0`
- `ghcr.io/naorpeled/postgis_pgvector:pg16-pgvectorv0.7.2`
- `ghcr.io/naorpeled/postgis_pgvector:pg15-pgvectorv0.7.2`

## Build Arguments

- `PG_MAJOR`: PostgreSQL major version (default: 16)
- `POSTGIS_MAJOR_VERSION`: PostGIS major version (default: 3)
- `PGVECTOR_VERSION`: pgvector version tag (default: v0.8.0)

## Building the Image

```bash
# Build with default versions
docker build -t postgres-postgis-pgvector .

# Build with custom versions
docker build \
  --build-arg PG_MAJOR=15 \
  --build-arg POSTGIS_MAJOR_VERSION=3 \
  --build-arg PGVECTOR_VERSION=v0.7.2 \
  -t postgres-postgis-pgvector:pg15-pgvector0.7.2 .
```

## Running the Container

```bash
# Using docker run
docker run -d \
  --name postgres-gis-vector \
  -e POSTGRES_PASSWORD=test \
  -e POSTGRES_USER=test \
  -e POSTGRES_DB=test \
  -p 5432:5432 \
  postgres-postgis-pgvector

# Using docker-compose
docker-compose up -d
```

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
