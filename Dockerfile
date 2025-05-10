# Default versions - can be overridden at build time using --build-arg
ARG MY_PG_VER=16
ARG MY_POSTGIS_VER=3
ARG MY_PGVECTOR_VER=v0.8.0

FROM postgres:${MY_PG_VER}

# Re-declare ARGs after FROM to make them available in this build stage
ARG MY_PG_VER
ARG MY_POSTGIS_VER
ARG MY_PGVECTOR_VER

LABEL maintainer="Naor Peled me@naor.dev"
LABEL description="PostgreSQL with PostGIS and pgvector extensions"
LABEL org.opencontainers.image.source="https://github.com/naorpeled/typeorm-postgres-docker"

# Set ENV vars from ARGs for runtime inspection (using different names to avoid confusion with ARGs)
ENV RT_PG_MAJOR=${MY_PG_VER} \
    RT_POSTGIS_MAJOR_VERSION=${MY_POSTGIS_VER} \
    RT_PGVECTOR_VERSION=${MY_PGVECTOR_VER}

# Install build dependencies and PostgreSQL development packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    # Tools for adding repositories
    lsb-release \
    gnupg \
    ca-certificates \
    wget \
    # Build tools
    build-essential \
    git \
    make \
    gcc \
    "postgresql-server-dev-${MY_PG_VER}" \
    # Add PostgreSQL repository
    && sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Install PostGIS
RUN effective_pg_major_shell="$MY_PG_VER" \
    && effective_postgis_major_shell="$MY_POSTGIS_VER" \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    postgis \
    "postgresql-${effective_pg_major_shell}-postgis-${effective_postgis_major_shell}" \
    "postgresql-${effective_pg_major_shell}-postgis-${effective_postgis_major_shell}-scripts"

# Build and install pgvector
RUN apt-get update \
    && apt-get install -y --no-install-recommends git make gcc "postgresql-server-dev-${MY_PG_VER}" \
    # pgvector build might need some dev tools re-installed if previous purge was too aggressive
    # or ensure build-essential is available through the whole multi-RUN sequence.
    # For now, assuming postgresql-server-dev-${MY_PG_VER}, git, make, gcc are sufficient here.
    && mkdir -p /usr/src/pgvector \
    && git clone --branch "${MY_PGVECTOR_VER}" https://github.com/pgvector/pgvector.git /usr/src/pgvector \
    && cd /usr/src/pgvector \
    && make \
    && make install

# Cleanup build dependencies that are no longer needed
RUN apt-get purge -y --auto-remove \
    build-essential \
    git \
    make \
    gcc \
    "postgresql-server-dev-${MY_PG_VER}" \
    wget \
    # gnupg can be kept if future repo additions are needed, but for now, let's purge
    # build-essential includes gcc, make etc.
    # git was for pgvector
    # postgresql-server-dev-${MY_PG_VER} was for pgvector and potentially postgis from source (not used here)
    # No, let's be more specific about what to remove after pgvector build
    # Keep: lsb-release, gnupg, ca-certificates (core OS/apt functionality)
    # Remove: wget (used for key), build-essential, git, make, gcc, postgresql-server-dev-${MY_PG_VER} (if only needed for build)
    # The following were installed specifically for building:
    # wget was also for initial setup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/src/pgvector

# Copy initialization scripts
COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/

# Default PostgreSQL port
EXPOSE 5432 