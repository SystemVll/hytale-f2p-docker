# Hytale F2P Server

A dockerized Hytale F2P server that automatically handles authentication and server registration with the Hytale auth server.

## Prerequisites

- Docker and Docker Compose installed
- `HytaleServer.jar` and `Assets.zip` files in the `game/` directory

## Quick Start

1. Run the server:

```bash
docker-compose up
```

The server will:
- Automatically fetch authentication tokens from the auth server
- Bind to `0.0.0.0:5520` (UDP)
- Register as "My Hytale Server" (customizable)

## Configuration

Edit the `docker-compose.yml` file to customize server settings:

```yaml
environment:
  HYTALE_AUTH_DOMAIN: auth.sanasol.ws    # Auth server domain
  SERVER_NAME: "My Hytale Server"         # Server display name
  BIND_ADDRESS: "0.0.0.0:5520"           # Server bind address
  AUTH_MODE: "authenticated"              # Authentication mode
```

## Advanced Configuration

Set JVM memory limits via environment variables:

```bash
docker-compose run -e JVM_XMS=512M -e JVM_XMX=2G hytale
```

## Logs

View server logs:

```bash
docker-compose logs -f hytale
```

## Stopping the Server

```bash
docker-compose down
```

## Technical Details

- **Base Image**: OpenJDK 27 EA on Debian Trixie (slim)
- **Port**: 5520/UDP
- **Script**: Automatic token generation and server startup handled by `start.sh`

The server automatically generates a unique server ID on first run and stores it in `.server-id` for future connections.

