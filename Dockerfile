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

# Optional: Additional CLI tools for more skills
# Uncomment to add these (requires separate installation or mounting):
# - brew (GitHub CLI, Gemini CLI, etc.) - requires macOS/Homebrew setup
# - go (some tools require Go runtime)
# - llm (Claude/OpenAI CLI tools)
# See README.md for installation instructions

# Runtime environment
ENV NODE_ENV=production
ENV HOME=/home/node

EXPOSE 18789 18790

CMD ["node", "dist/index.js", "gateway", "--bind", "lan", "--port", "18789", "--allow-unconfigured"]
