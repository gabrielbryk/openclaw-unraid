FROM node:22-bookworm

# Install system dependencies (for skill requirements)
# These enable additional OpenClaw skills to function
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git \
    curl \
    jq \
    python3 \
    python3-pip \
    ffmpeg \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Bun (required for build scripts)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

# Clone OpenClaw repository
RUN git clone https://github.com/openclaw/openclaw.git /app

# Install dependencies
RUN corepack enable
RUN pnpm install --frozen-lockfile

# Build the application
RUN pnpm build
RUN pnpm ui:install
RUN pnpm ui:build

# Install OpenClaw CLI globally
RUN npm install -g /app/dist/cli.js || true && \
    ln -sf /app/dist/index.js /usr/local/bin/openclaw

# Create entrypoint script for conditional tool installation
# This allows tools to be installed at runtime without bloating the image
COPY --chmod=755 <<EOF /usr/local/bin/docker-entrypoint.sh
#!/bin/bash
set -e

# Create bin directory for optional tools
mkdir -p /home/node/bin

# Install Go from official source if not present (for goplaces and other Go-based skills)
# Debian repos have Go 1.19, but goplaces requires Go 1.25+
if ! command -v go &> /dev/null; then
    echo "📦 Installing Go runtime from official source..."
    GO_VERSION="1.25.5"
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" | tar -xz -C /usr/local/
    ln -sf /usr/local/go/bin/go /usr/local/bin/go
fi

# Install goplaces if not present
if ! command -v goplaces &> /dev/null; then
    if command -v go &> /dev/null; then
        echo "🌍 Installing goplaces (Google Places API CLI)..."
        export GOPATH=/home/node/.local
        go install github.com/steipete/goplaces/cmd/goplaces@latest 2>/dev/null || true
        if [ -f "/home/node/.local/go/bin/goplaces" ]; then
            ln -sf /home/node/.local/go/bin/goplaces /home/node/bin/goplaces
        fi
    fi
fi

# Export PATH to include optional tools
export PATH="/home/node/bin:$PATH"

# Start OpenClaw Gateway
exec node dist/index.js gateway --bind lan --port 18789 --allow-unconfigured
EOF

# Runtime environment
ENV NODE_ENV=production
ENV HOME=/home/node
ENV PATH=/home/node/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

EXPOSE 18789 18790

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
