# Default versions - can be overridden at build time using --build-arg
ARG PG_MAJOR=16
ARG POSTGIS_MAJOR_VERSION=3
ARG PGVECTOR_VERSION=v0.7.2

FROM postgres:${PG_MAJOR}

LABEL maintainer="Naor Peled me@naor.dev"
LABEL description="PostgreSQL with PostGIS and pgvector extensions"
LABEL org.opencontainers.image.source="https://github.com/naorpeled/postgis_pgvector"

# Set ENV vars from ARGs for use in subsequent RUN commands and runtime inspection
ENV POSTGIS_MAJOR_VERSION=${POSTGIS_MAJOR_VERSION} \
    PGVECTOR_VERSION=${PGVECTOR_VERSION} \
    PG_MAJOR=${PG_MAJOR}

# Install build dependencies and PostgreSQL development packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    # Tools for adding repositories
    lsb-release \
    gnupg \
    ca-certificates \
    wget \
    # Build tools for pgvector
    build-essential \
    git \
    make \
    gcc \
    postgresql-server-dev-${PG_MAJOR} \
    # Add PostgreSQL repository for latest PostGIS
    && wget --quiet -O /usr/share/keyrings/postgresql-archive-keyring.asc https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    && echo "deb [signed-by=/usr/share/keyrings/postgresql-archive-keyring.asc] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main ${PG_MAJOR}" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    # Install PostGIS
    && apt-get install -y --no-install-recommends \
    postgis \
    postgresql-${PG_MAJOR}-postgis-${POSTGIS_MAJOR_VERSION} \
    postgresql-${PG_MAJOR}-postgis-${POSTGIS_MAJOR_VERSION}-scripts \
    # Build and install pgvector
    && mkdir -p /usr/src/pgvector \
    && git clone --branch ${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git /usr/src/pgvector \
    && cd /usr/src/pgvector \
    && make \
    && make install \
    # Cleanup
    && apt-get purge -y --auto-remove \
    wget \
    gnupg \
    build-essential \
    git \
    make \
    gcc \
    postgresql-server-dev-${PG_MAJOR} \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/src/pgvector

# Copy initialization scripts
COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/

# Default PostgreSQL port
EXPOSE 5432 