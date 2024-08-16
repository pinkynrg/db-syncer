#!/bin/bash

# Define local PostgreSQL root user credentials
LOCAL_ROOT_USER="root"
LOCAL_ROOT_PASSWORD="root"

# Define paths and output file
ENVS_DIR="envs"
OUTPUT_FILE="docker-compose.yml"

# Function to write the local_postgresql service
write_local_postgresql_service() {
  cat <<EOF >> "$OUTPUT_FILE"
services:
  local_postgresql:
    image: postgres:latest
    environment:
      POSTGRES_USER: $LOCAL_ROOT_USER
      POSTGRES_PASSWORD: $LOCAL_ROOT_PASSWORD
      POSTGRES_DB: $LOCAL_ROOT_USER
    ports:
      - "5432:5432"
    logging:
      driver: "none"

EOF
}

# Function to write a dynamic postgresql_worker service
write_postgresql_worker_service() {
  local ENV_NAME=$1

  cat <<EOF >> "$OUTPUT_FILE"
  # Service for environment: $ENV_NAME
  postgresql_worker_$ENV_NAME:
    image: postgres:latest
    extra_hosts:
      - "localhost:host-gateway"
    command: >
      bash -c "
        until pg_isready -h local_postgresql -U $LOCAL_ROOT_USER; do
          echo waiting for postgres;
          sleep 2;
        done;

        echo 'Creating database $LOCAL_POSTGRES_DB...';
        PGPASSWORD=$LOCAL_ROOT_PASSWORD psql -h local_postgresql -U $LOCAL_ROOT_USER -c 'CREATE DATABASE $LOCAL_POSTGRES_DB;';

        echo 'Creating user $LOCAL_POSTGRES_USER with superuser privileges...';
        PGPASSWORD=$LOCAL_ROOT_PASSWORD psql -h local_postgresql -U $LOCAL_ROOT_USER -c \"
          CREATE USER $LOCAL_POSTGRES_USER WITH PASSWORD '$LOCAL_POSTGRES_PASSWORD' SUPERUSER;
          GRANT ALL PRIVILEGES ON DATABASE $LOCAL_POSTGRES_DB TO $LOCAL_POSTGRES_USER;
        \";

        echo 'Restoring database from remote...';
        PGPASSWORD=$REMOTE_POSTGRES_PASSWORD pg_dump -h $REMOTE_POSTGRES_HOST -U $REMOTE_POSTGRES_USER $REMOTE_POSTGRES_DB | \
        PGPASSWORD=$LOCAL_POSTGRES_PASSWORD psql -h local_postgresql -U $LOCAL_POSTGRES_USER $LOCAL_POSTGRES_DB;

        if [ \$? -eq 0 ]; then
          echo 'Database restoration complete.';
        else
          echo 'Database restoration failed.';
        fi

        exit;"
EOF
}

# Start writing to the output file
echo "# Generated docker-compose file" > "$OUTPUT_FILE"

# Write the local_postgresql service
write_local_postgresql_service

# Loop through each .env file in the envs directory
for ENV_FILE in $ENVS_DIR/.env-*; do
  # Extract the environment name from the file name (remove '.env-' prefix)
  ENV_NAME=$(basename "$ENV_FILE" | sed 's/\.env-//')

  # Source the environment variables from the .env file
  set -a
  source "$ENV_FILE"
  set +a

  # Write the postgresql_worker service for each environment
  write_postgresql_worker_service "$ENV_NAME"

  echo "Added service for $ENV_NAME using $ENV_FILE"
done

echo "All services added to $OUTPUT_FILE successfully."

# Start the services using docker-compose in the foreground
docker-compose -f "$OUTPUT_FILE" down
docker-compose -f "$OUTPUT_FILE" up
