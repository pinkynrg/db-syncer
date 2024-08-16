# PostgreSQL Database Synchronization

This repository contains a shell script that automates the synchronization of PostgreSQL databases using Docker Compose. The script dynamically generates a `docker-compose.yml` file based on environment-specific configurations and starts the services. It syncs databases from remote PostgreSQL instances into local PostgreSQL databases specified in environment files.

## How It Works

The script processes each environment file found in the `envs` directory. For each environment:

1. **Local PostgreSQL Setup**: A local PostgreSQL service is configured and started. This service uses the default credentials specified in the script (`root` for both username and password).

2. **Database Creation**: For each environment, the script creates a specified local database and a corresponding user with superuser privileges.

3. **Database Synchronization**: The script connects to a remote PostgreSQL database, dumps its contents, and restores them into the local PostgreSQL database. This syncs the remote data into your local environment.

4. **Service Management**: The script generates a `docker-compose.yml` file and starts the services, running them in the foreground.

## Prerequisites

- **Docker**: Ensure that Docker is installed on your system.
- **Docker Compose**: Docker Compose must also be installed to run the generated `docker-compose.yml` file.

## Environment Variables

Each environment is defined by a `.env-*` file in the `envs` directory. These files specify the local and remote PostgreSQL settings, enabling the synchronization process.

### Required Variables

- `LOCAL_POSTGRES_USER`: The username for the local PostgreSQL database.
- `LOCAL_POSTGRES_PASSWORD`: The password for the local PostgreSQL user.
- `LOCAL_POSTGRES_DB`: The name of the local PostgreSQL database to be created and synced.
- `REMOTE_POSTGRES_HOST`: The host address of the remote PostgreSQL server.
- `REMOTE_POSTGRES_USER`: The username for the remote PostgreSQL server.
- `REMOTE_POSTGRES_PASSWORD`: The password for the remote PostgreSQL user.
- `REMOTE_POSTGRES_DB`: The name of the remote PostgreSQL database to be synced.

### Example `.env` File (`envs/.env-dev`)

```bash
LOCAL_POSTGRES_USER=local_user
LOCAL_POSTGRES_PASSWORD=local_password
LOCAL_POSTGRES_DB=local_db
REMOTE_POSTGRES_HOST=remote.host.com
REMOTE_POSTGRES_USER=remote_user
REMOTE_POSTGRES_PASSWORD=remote_password
REMOTE_POSTGRES_DB=remote_db
```

In this example:

- `local_user` and `local_password` are the credentials for the local PostgreSQL database `local_db`.
- The script will sync data from the remote database `remote_db` hosted on `remote.host.com` into `local_db`.

## How to Use

1. **Clone the Repository**

   Clone this repository to your local machine:

   ```bash
   git clone https://github.com/yourusername/postgresql-docker-compose-automation.git
   cd postgresql-docker-compose-automation
   ```

2. **Set Up Environment Files**

   Create environment-specific `.env-*` files in the `envs` directory. Each file should define the environment variables mentioned above. For example:

   ```bash
   mkdir envs
   touch envs/.env-dev
   touch envs/.env-prod
   ```

   Populate the `.env-*` files with the appropriate values for your environments.

3. **Run the Script**

   Execute the script to generate the `docker-compose.yml` file and start the services:

   ```bash
   sh ./sync.sh
   ```

   The script will:
   - Create and start the necessary local PostgreSQL service.
   - Create the specified local databases and users.
   - Sync the remote databases into the corresponding local databases.

4. **Monitor the Sync Process**

   The services will run in the foreground. You can monitor the synchronization process directly from your terminal. Any errors during the sync process will be displayed.

5. **Access the Synchronized Databases**

   Once the sync is complete, the local databases specified in your environment files will be fully populated with data from the remote PostgreSQL instances.

## Example Workflow

### Example Scenario

Imagine you have a remote PostgreSQL database `remote_db` hosted on `remote.host.com`, and you want to sync its contents into a local PostgreSQL database `local_db` on your machine for development or testing.

1. Create an environment file (`envs/.env-dev`) with the following content:

   ```bash
   LOCAL_POSTGRES_USER=dev_user
   LOCAL_POSTGRES_PASSWORD=dev_password
   LOCAL_POSTGRES_DB=local_db
   REMOTE_POSTGRES_HOST=remote.host.com
   REMOTE_POSTGRES_USER=remote_user
   REMOTE_POSTGRES_PASSWORD=remote_password
   REMOTE_POSTGRES_DB=remote_db
   ```

2. Run the script:

   ```bash
   sh ./sync.sh
   ```

3. The script will create `local_db` with user `dev_user` on your local machine and sync the data from `remote_db`.

4. You can now work with the synced data in `local_db` locally.

This process is particularly useful for development, testing, or backup scenarios where you need local access to the latest data from a remote PostgreSQL instance.
