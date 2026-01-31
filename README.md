# OpenClaw Docker for Unraid

Docker build configuration for OpenClaw personal AI assistant, designed for Unraid deployment.

## Quick Start (Local Testing)

```bash
# Build the image locally
./build.sh

# Or manually
docker build -t openclaw:latest .

# Test with docker-compose
docker-compose up -d

# Access
http://localhost:18789
```

## For Unraid Tower

```bash
# Clone to Tower
git clone https://github.com/YOUR_USERNAME/openclaw-unraid.git /tmp/openclaw-unraid

# Build on Tower
cd /tmp/openclaw-unraid
docker build -t openclaw:latest .

# Deploy via Unraid template
# Docker → Add Container → select openclaw template
```

## Files

- **Dockerfile** - Multi-stage build, clones OpenClaw and builds Node.js image
- **docker-compose.yml** - Local testing configuration
- **build.sh** - Build helper script
- **unraid-template.xml** - Unraid Docker template (in ../templates/)

## Environment Variables

- `HOME=/home/node`
- `TERM=xterm-256color`
- `NODE_ENV=production`
- `PUID=99` (Unraid standard)
- `PGID=100` (Unraid standard)
- `TZ=America/Chicago`

## Ports

- **18789** - Gateway WebSocket (main interface)
- **18790** - Bridge Protocol (device pairing)

## Volumes

- `/home/node/.openclaw` - Configuration and credentials
- `/home/node/.openclaw/workspace` - Agent skills, sessions, memory

## Build Notes

- Builds from official OpenClaw repo
- Node.js 22 with pnpm
- ~2-3GB final image size
- First build takes 10-15 minutes
