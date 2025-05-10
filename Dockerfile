# Default versions - can be overridden at build time using --build-arg
ARG PG_MAJOR_VERSION=16
ARG POSTGIS_MAJOR_VERSION=3
ARG PGVECTOR_TAG=v0.8.0

FROM postgres:${PG_MAJOR_VERSION}

# Re-declare ARGs after FROM to make them available in this build stage
ARG PG_MAJOR_VERSION
ARG POSTGIS_MAJOR_VERSION
ARG PGVECTOR_TAG

LABEL maintainer="Naor Peled me@naor.dev"
LABEL description="PostgreSQL with PostGIS and pgvector extensions for TypeORM"
LABEL org.opencontainers.image.source="https://github.com/naorpeled/typeorm-postgres-docker"

# Set ENV vars from ARGs for runtime inspection and use within the container
ENV PG_MAJOR_VERSION=${PG_MAJOR_VERSION} \
    POSTGIS_MAJOR_VERSION=${POSTGIS_MAJOR_VERSION} \
    PGVECTOR_TAG=${PGVECTOR_TAG}

# Install base dependencies, setup PGDG repository, and install build tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    lsb-release \
    gnupg \
    ca-certificates \
    wget \
    # Add PostgreSQL official repository
    && sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    # Update package lists again after adding the new repository
    && apt-get update \
    # Install build tools and PostgreSQL development packages from PGDG
    && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    make \
    gcc \
    "postgresql-server-dev-${PG_MAJOR_VERSION}"

# Install PostGIS
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    postgis \
    "postgresql-${PG_MAJOR_VERSION}-postgis-${POSTGIS_MAJOR_VERSION}" \
    "postgresql-${PG_MAJOR_VERSION}-postgis-${POSTGIS_MAJOR_VERSION}-scripts"

# Build and install pgvector
RUN apt-get update \
    # Ensure build tools are available for this layer if they were aggressively purged before,
    # or if previous RUN commands didn't include them and they are needed.
    # For pgvector, we need git, make, gcc, and postgresql-server-dev.
    && apt-get install -y --no-install-recommends git make gcc "postgresql-server-dev-${PG_MAJOR_VERSION}" \
    && mkdir -p /usr/src/pgvector \
    && git clone --branch "${PGVECTOR_TAG}" https://github.com/pgvector/pgvector.git /usr/src/pgvector \
    && cd /usr/src/pgvector \
    && make \
    && make install

# Cleanup build dependencies
RUN apt-get purge -y --auto-remove \
    build-essential \
    # git make gcc "postgresql-server-dev-${PG_MAJOR_VERSION}" were re-installed for pgvector, purge them too
    git \
    make \
    gcc \
    "postgresql-server-dev-${PG_MAJOR_VERSION}" \
    wget \
    # gnupg might be needed if other repositories are added later, but for now, we can remove it
    # if it was only for the postgresql repo key. lsb-release and ca-certificates are generally kept.
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/src/pgvector

# Copy initialization scripts
COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/

# Default PostgreSQL port
EXPOSE 5432 