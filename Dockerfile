FROM openjdk:27-ea-slim-trixie

WORKDIR /server


RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy server files
COPY game/HytaleServer.jar .
COPY game/Assets.zip .
COPY game/start.sh .

# Make start script executable
RUN chmod +x ./start.sh

# Environment variables (can be overridden)
ENV HYTALE_AUTH_DOMAIN=auth.sanasol.ws
ENV SERVER_NAME="My Hytale Server"
ENV BIND_ADDRESS=0.0.0.0:5520
ENV AUTH_MODE=authenticated

# Expose the game server port
EXPOSE 5520/udp

# Run the start script
CMD ["./start.sh"]