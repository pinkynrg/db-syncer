# db-syncer 🚀

`db-syncer` is a shell script that automates the synchronization of PostgreSQL databases using Docker Compose. It dynamically generates a `docker-compose.yml` file based on environment-specific configurations and syncs remote PostgreSQL databases into local instances.

## Prerequisites 🛠️

- **Docker**: Ensure Docker is installed.
- **Docker Compose**: Ensure Docker Compose is installed.

## Quick Start ⚡

1. **Clone the Repository** 📥:

   ```bash
   git clone https://github.com/pinkynrg/db-syncer.git
   cd db-syncer
   ```

2. **Set Up Environment Files** 📝:

   Create a `.env-*` file in the `envs` directory for each environment. For example `.env-test-1`:

   ```bash
    LOCAL_POSTGRES_USER=local_user
    LOCAL_POSTGRES_PASSWORD=local_password
    LOCAL_POSTGRES_DB=local_db
    REMOTE_POSTGRES_HOST=remote.host.com
    REMOTE_POSTGRES_USER=remote_user
    REMOTE_POSTGRES_PASSWORD=remote_password
    REMOTE_POSTGRES_DB=remote_db
  ```

3. **Run the Script** ▶️:

   ```bash
   sh ./sync.sh
   ```

4. **Monitor and Access** 👀: The synchronization process will run in the foreground. Access the synced data in your local PostgreSQL database.
