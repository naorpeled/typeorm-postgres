#!/bin/bash
set -e

# Function to enable extensions in a database
enable_extensions() {
    local db=$1
    echo "Enabling extensions in database: $db"
    
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" <<-EOSQL
        -- Enable PostGIS extension
        CREATE EXTENSION IF NOT EXISTS postgis;
        CREATE EXTENSION IF NOT EXISTS postgis_topology;
        CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
        
        -- Enable pgvector extension
        CREATE EXTENSION IF NOT EXISTS vector;
EOSQL
}

# Enable extensions in the default database
enable_extensions "$POSTGRES_DB"

# If ADDITIONAL_DATABASES is set, create and initialize those databases too
if [ -n "$ADDITIONAL_DATABASES" ]; then
    for db in $(echo $ADDITIONAL_DATABASES | tr ',' ' '); do
        echo "Creating and initializing additional database: $db"
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
            CREATE DATABASE $db;
EOSQL
        enable_extensions "$db"
    done
fi

echo "PostGIS and pgvector extensions have been enabled." 