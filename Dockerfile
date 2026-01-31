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

# Create entrypoint script for conditional tool installation at runtime
# This keeps the image lean while enabling all skills on first container start
COPY --chmod=755 <<EOF /usr/local/bin/docker-entrypoint.sh
#!/bin/bash
set -e

# Create bin directory for optional tools
mkdir -p /home/node/bin

echo "🚀 OpenClaw Gateway starting up..."

# ============================================================================
# Go-based Skills (goplaces, etc)
# ============================================================================

# Install Go from official source if not present (for goplaces and other Go-based skills)
# Debian repos have Go 1.19, but goplaces requires Go 1.25+
if ! command -v go &> /dev/null; then
    echo "📦 Installing Go 1.25.5 runtime for Go-based skills..."
    GO_VERSION="1.25.5"
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" | tar -xz -C /usr/local/
    ln -sf /usr/local/go/bin/go /usr/local/bin/go
fi

# Install goplaces (Google Places API) if not present
if ! command -v goplaces &> /dev/null && command -v go &> /dev/null; then
    echo "🌍 Installing goplaces (Google Places API skill)..."
    export GOPATH=/home/node/.local
    go install github.com/steipete/goplaces/cmd/goplaces@latest 2>/dev/null && \
        ln -sf /home/node/.local/go/bin/goplaces /home/node/bin/goplaces || true
fi

# ============================================================================
# GitHub CLI (gh) - for github, gist, and other GitHub integration skills
# ============================================================================

if ! command -v gh &> /dev/null; then
    echo "🐙 Installing GitHub CLI (gh) for GitHub integration skills..."
    apt-get update && apt-get install -y --no-install-recommends gh && rm -rf /var/lib/apt/lists/* || true
fi

# ============================================================================
# Gemini CLI - for gemini skill support
# ============================================================================

if ! command -v gemini &> /dev/null; then
    echo "✨ Installing Gemini CLI for Gemini AI skills..."
    npm install -g @google/gemini-cli 2>/dev/null || true
fi

# ============================================================================
# Claude/OpenAI CLI tools - for model usage tracking and direct API access
# ============================================================================

if ! npm list -g llm &>/dev/null 2>&1; then
    echo "🤖 Installing Claude/OpenAI CLI tools for model tracking skills..."
    npm install -g llm openai 2>/dev/null || true
fi

# ============================================================================
# Additional NPM CLI tools
# ============================================================================

# obsidian-cli for Obsidian vault integration
if ! command -v obsidian &> /dev/null && ! npm list -g obsidian-cli &>/dev/null 2>&1; then
    echo "📝 Installing Obsidian CLI for vault integration..."
    npm install -g obsidian-cli 2>/dev/null || true
fi

# ============================================================================
# System packages (via apt) for additional CLI tools
# ============================================================================

# 1Password CLI (op command)
if ! command -v op &> /dev/null; then
    echo "🔐 Installing 1Password CLI (op) for password/secret management..."
    (apt-get update && apt-get install -y --no-install-recommends 1password-cli && rm -rf /var/lib/apt/lists/*) 2>/dev/null || true
fi

# ffprobe (part of ffmpeg) - already have ffmpeg, but explicit check
if ! command -v ffprobe &> /dev/null; then
    echo "🎬 Ensuring ffprobe available for video analysis..."
    apt-get update && apt-get install -y --no-install-recommends ffmpeg && rm -rf /var/lib/apt/lists/* 2>/dev/null || true
fi

# tmux for session control
if ! command -v tmux &> /dev/null; then
    echo "🧵 Installing tmux for terminal session control..."
    apt-get update && apt-get install -y --no-install-recommends tmux && rm -rf /var/lib/apt/lists/* 2>/dev/null || true
fi

# ============================================================================
# Cargo-based tools (Rust package manager) - for specialized CLIs
# ============================================================================

# Install Rust/Cargo if needed for Rust-based tools
if ! command -v cargo &> /dev/null && [ -z "\$CARGO_SKIP" ]; then
    echo "🦀 Installing Rust/Cargo for Rust-based CLI tools..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>/dev/null || true
    export PATH="/root/.cargo/bin:\$PATH"
fi

# spotify-player (Rust-based Spotify CLI)
if ! command -v spotify_player &> /dev/null && command -v cargo &> /dev/null; then
    echo "🎵 Installing Spotify Player CLI..."
    cargo install spotify-player 2>/dev/null || true
fi

# sherpa-onnx-tts (Rust-based TTS)
if ! command -v sherpa-onnx-tts &> /dev/null && command -v cargo &> /dev/null; then
    echo "🗣️ Installing Sherpa ONNX TTS..."
    cargo install sherpa-onnx 2>/dev/null || true
fi

# Export PATH to include optional tools
export PATH="/home/node/bin:/root/.cargo/bin:\$PATH"

echo "✅ Skill support tools ready"
echo "🌐 OpenClaw Gateway starting..."

# Start OpenClaw Gateway
exec node dist/index.js gateway --bind lan --port 18789 --allow-unconfigured
EOF

# Runtime environment
ENV NODE_ENV=production
ENV HOME=/home/node
ENV PATH=/home/node/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

EXPOSE 18789 18790

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
