#!/bin/bash

# Define local PostgreSQL root user credentials
LOCAL_ROOT_USER="root"
LOCAL_ROOT_PASSWORD="root"

# Define local port (default: 5432)
LOCAL_PORT="${LOCAL_PORT:-5432}"

# Define paths and output files
ENVS_DIR="envs"
COMPOSE_FILE="docker-compose.yml"

# --- Docker Compose generation helpers ---

write_local_postgresql_service() {
  cat <<EOF >> "$COMPOSE_FILE"
services:
  local_postgresql:
    image: postgres:latest
    environment:
      POSTGRES_USER: $LOCAL_ROOT_USER
      POSTGRES_PASSWORD: $LOCAL_ROOT_PASSWORD
      POSTGRES_DB: $LOCAL_ROOT_USER
    ports:
      - "$LOCAL_PORT:5432"
    logging:
      driver: "none"
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:

EOF
}

write_postgresql_worker_service() {
  local ENV_NAME=$1

  cat <<EOF >> "$COMPOSE_FILE"
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

generate_compose() {
  local TARGET_ENV="$1"

  echo "# Generated docker-compose file" > "$COMPOSE_FILE"
  write_local_postgresql_service

  if [ -n "$TARGET_ENV" ]; then
    ENV_FILES="$ENVS_DIR/.env-$TARGET_ENV"
    if [ ! -f "$ENV_FILES" ]; then
      echo "Error: Environment file $ENV_FILES not found."
      exit 1
    fi
  else
    ENV_FILES="$ENVS_DIR/.env-*"
  fi

  for ENV_FILE in $ENV_FILES; do
    ENV_NAME=$(basename "$ENV_FILE" | sed 's/\.env-//')
    set -a
    source "$ENV_FILE"
    set +a
    write_postgresql_worker_service "$ENV_NAME"
    echo "Added service for $ENV_NAME"
  done
}

# --- Commands ---

cmd_sync() {
  local TARGET_ENV="$1"
  generate_compose "$TARGET_ENV"
  echo "Destroying existing database..."
  docker-compose -f "$COMPOSE_FILE" down -v
  echo "Starting sync..."
  docker-compose -f "$COMPOSE_FILE" up
}

cmd_start() {
  echo "# Generated docker-compose file" > "$COMPOSE_FILE"
  write_local_postgresql_service
  echo "Starting local PostgreSQL server..."
  docker-compose -f "$COMPOSE_FILE" up -d
  echo "PostgreSQL is running on port $LOCAL_PORT."
}

cmd_stop() {
  docker-compose -f "$COMPOSE_FILE" down
  echo "Local PostgreSQL server stopped."
}

cmd_help() {
  cat <<EOF
db-syncer - PostgreSQL database synchronization tool

Usage: ./db-syncer <command> [environment]

Commands:
  sync [env]    Sync databases from remote to local PostgreSQL.
                If [env] is specified, syncs only that environment.
                Otherwise syncs all environments in envs/.

  start         Start the local PostgreSQL server (without syncing).
                Uses previously synced data.

  stop          Stop the local PostgreSQL server.

  help          Show this help message.

Environment variables:
  LOCAL_PORT    Local port for PostgreSQL (default: 5432).

Examples:
  ./db-syncer sync              # Sync all environments
  ./db-syncer sync users        # Sync only the 'users' environment
  ./db-syncer start             # Start local PostgreSQL server
  ./db-syncer stop              # Stop local PostgreSQL server
  LOCAL_PORT=5433 ./db-syncer sync   # Sync using custom port
EOF
}

# --- Main ---

COMMAND="${1:-help}"
shift 2>/dev/null

case "$COMMAND" in
  sync)   cmd_sync "$1" ;;
  start)  cmd_start ;;
  stop)   cmd_stop ;;
  help)   cmd_help ;;
  *)
    echo "Unknown command: $COMMAND"
    echo ""
    cmd_help
    exit 1
    ;;
esac
