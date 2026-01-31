FROM node:22-bookworm

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

# Runtime environment
ENV NODE_ENV=production
ENV HOME=/home/node

EXPOSE 18789 18790

CMD ["node", "dist/index.js", "gateway", "--bind", "lan", "--port", "18789", "--allow-unconfigured"]
