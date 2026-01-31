# OpenClaw Docker for Unraid

Docker build configuration for OpenClaw personal AI assistant, designed for Unraid deployment.

Based on official documentation: https://docs.openclaw.ai/install/docker

---

## Quick Start (Local Testing)

```bash
# Build the image locally
./build.sh

# Or manually
docker build -t openclaw:latest .

# Test with docker-compose
docker-compose up -d

# Access Gateway
http://localhost:18789

# View logs
docker-compose logs -f openclaw

# Stop
docker-compose down
```

---

## For Unraid Tower Server

### 1. Build on Tower

```bash
# SSH to Tower
ssh unraid

# Clone this repository
cd /tmp
git clone https://github.com/YOUR_USERNAME/openclaw-unraid.git
cd openclaw-unraid

# Build the image (takes 10-15 minutes on first build)
docker build -t openclaw:latest .

# Verify build
docker images openclaw:latest
```

### 2. Deploy via Unraid Template

Once the image is built locally on Tower:

1. Go to Unraid WebUI: `http://10.0.0.2`
2. Navigate to **Docker** tab
3. Click **Add Container**
4. Select **openclaw** from template dropdown
5. Configure settings (volumes, ports already set)
6. Click **Apply**

Container will start and be managed by Unraid.

---

## Getting Started After First Run

### 1. Access the Control UI

**From local network:**
```
http://10.0.0.2:18789
```

**From remote (requires SWAG reverse proxy):**
```
https://openclaw.gabebryk.com
```

### 1a. Approve Device Pairing

The Control UI requires device pairing for security. When you first access it, a pairing request is generated:

```bash
# Check pending pairing requests
ssh unraid "docker exec openclaw node dist/index.js devices list"

# Approve the pending request (replace REQUEST_ID with actual ID)
ssh unraid "docker exec openclaw node dist/index.js devices approve [REQUEST_ID]"
```

Then **refresh the browser** - it should connect successfully.

**Note**: Device pairing requests expire after 5 minutes. If you miss it, just refresh the browser to generate a new request.

### 2. Run Onboarding Wizard

```bash
ssh unraid
docker exec openclaw node dist/index.js onboard
```

This interactive wizard will guide you through:
- Model provider setup (Anthropic, OpenAI, OpenRouter)
- Workspace configuration
- Optional channel setup

### 3. Configure Messaging Channels

After onboarding, add channels via CLI:

**WhatsApp (QR code linking):**
```bash
docker exec openclaw node dist/index.js channels login
```

**Telegram (bot token):**
```bash
docker exec openclaw node dist/index.js channels add --channel telegram --token "YOUR_BOT_TOKEN"
```

**Discord (bot token):**
```bash
docker exec openclaw node dist/index.js channels add --channel discord --token "YOUR_BOT_TOKEN"
```

**Slack (bot + app tokens):**
```bash
docker exec openclaw node dist/index.js channels add --channel slack --bot-token "YOUR_BOT_TOKEN" --app-token "YOUR_APP_TOKEN"
```

See official docs for complete channel setup: https://docs.openclaw.ai/install/docker#channel-setup-optional

### 4. Check Gateway Health

```bash
docker exec openclaw node dist/index.js health
```

---

## Files

- **Dockerfile** - Multi-stage build, clones official OpenClaw repo, builds with Node.js 22
- **docker-compose.yml** - Local testing configuration
- **build.sh** - Build helper script
- **README.md** - This file

---

## Configuration

### Environment Variables

Set in Unraid template or docker-compose.yml:

| Variable | Value | Purpose |
|----------|-------|---------|
| `HOME` | `/home/node` | Node.js home directory |
| `TERM` | `xterm-256color` | Terminal emulation |
| `NODE_ENV` | `production` | Runtime mode |
| `PUID` | `99` | User ID (Unraid standard) |
| `PGID` | `100` | Group ID (Unraid standard) |
| `TZ` | `America/Chicago` | Timezone |

### Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| **18789** | TCP | Gateway WebSocket (control plane, main interface) |
| **18790** | TCP | Bridge Protocol (device node pairing - iOS/Android/macOS) |

### Volumes

Mount these paths for persistent storage:

| Path | Purpose |
|------|---------|
| `/home/node/.openclaw` | Configuration files, credentials, logs |
| `/home/node/.openclaw/workspace` | Agent skills, session history, memory |

---

## Advanced Configuration

### Optional: Environment Variables for Providers

You can pre-configure API keys via environment variables, though the onboarding wizard is the recommended approach:

```bash
# Add these to Unraid template if needed
# ANTHROPIC_API_KEY=sk-ant-...
# OPENAI_API_KEY=sk-...
# OPENROUTER_API_KEY=sk-or-...
```

### Optional: Agent Sandboxing

For multi-agent or group chat safety, enable Docker sandboxing:

```bash
docker exec openclaw node dist/index.js onboard
# Select "Enable sandboxing for non-main sessions" during wizard
```

See official docs: https://docs.openclaw.ai/install/docker#agent-sandbox-host-gateway--docker-tools

### Notes on Gateway Binding

- **Gateway bind** defaults to `lan` for container use (correct for Unraid)
- Gateway container is the source of truth for sessions at `~/.openclaw/agents/<agentId>/sessions/`
- Do NOT expose port 18789 to public internet without authentication (reverse proxy recommended)

---

## Troubleshooting

### Image won't build

Check you have ~5GB disk space and Docker can access the network:
```bash
docker build -t openclaw:latest . --no-cache
```

### Gateway won't start

Check logs:
```bash
docker logs openclaw
```

Ensure sufficient disk space for appdata and workspace volumes.

### Can't reach gateway dashboard

From Tower:
```bash
# Check if port 18789 is listening
netstat -tulpn | grep 18789

# Or test with curl
curl -v http://localhost:18789
```

### Health check fails

Get gateway token and test:
```bash
docker exec openclaw node dist/index.js health
```

---

## Build Notes

- **Base Image**: `node:22-bookworm` (official Node.js LTS)
- **Package Manager**: `pnpm` (per official OpenClaw recommendations)
- **Included Dependencies**: git, curl, jq, python3, ffmpeg, build-essential
- **Final Size**: ~2-3GB
- **Build Time**: 10-15 minutes (first build), ~5 minutes (cached)
- **Source**: Cloned from https://github.com/openclaw/openclaw

### Included System Dependencies

The Dockerfile includes common skill dependencies to enable more OpenClaw skills:

| Dependency | Enables Skills | Install |
|------------|----------------|---------|
| `git` | GitHub integration, git operations | ✅ Included |
| `curl` | Web requests, API calls | ✅ Included |
| `jq` | JSON processing | ✅ Included |
| `python3` | Python-based skills, automation | ✅ Included |
| `ffmpeg` | Video/audio processing, frame extraction | ✅ Included |
| `build-essential` | Compiling tools and dependencies | ✅ Included |

### Automatically Installed at Container Startup

These tools are automatically installed on the container's first startup (not in the image layer) to keep the image lean while enabling all skills. Installation only happens once - subsequent starts skip already-installed tools.

#### NPM-based CLI Tools
| Tool | Enables Skills | Status |
|------|---|---|
| **GitHub CLI (`gh`)** | github, gist (15+ GitHub skills) | ✅ Auto-installed via apt |
| **Gemini CLI** | gemini (Google AI) | ✅ Auto-installed via npm |
| **Claude/OpenAI CLI** | model-usage, openai-whisper, openai-image-gen | ✅ Auto-installed via npm |
| **Obsidian CLI** | obsidian (vault integration) | ✅ Auto-installed via npm |

#### Go-based CLI Tools
| Tool | Enables Skills | Status |
|------|---|---|
| **Go 1.25.5 runtime** | goplaces, other Go tools | ✅ Auto-installed from official source |
| **goplaces** | goplaces (Google Places API) | ✅ Auto-installed via `go install` |

#### System Package Tools (via apt)
| Tool | Enables Skills | Status |
|------|---|---|
| **1Password CLI (`op`)** | 1password (password/secret management) | ✅ Auto-installed via apt |
| **ffprobe** | camsnap, video-frames (media analysis) | ✅ Already included (part of ffmpeg) |
| **tmux** | tmux (terminal session control) | ✅ Auto-installed via apt |

#### Rust-based CLI Tools (via Cargo)
| Tool | Enables Skills | Status |
|------|---|---|
| **Rust/Cargo** | (required for Rust tools) | ✅ Auto-installed on demand |
| **spotify-player** | spotify-player (Spotify playback control) | ✅ Auto-compiled via cargo |
| **sherpa-onnx** | sherpa-onnx-tts (offline text-to-speech) | ✅ Auto-compiled via cargo |

### Skills with External Requirements (Cannot be Fixed)

These skills are **fundamentally blocked** and cannot be enabled in Docker:

#### macOS-only Skills (No Linux Equivalent)
- **apple-notes** - Requires macOS memo CLI
- **apple-reminders** - Requires macOS remindctl
- **bear-notes** - Requires macOS Bear app + grizzly CLI
- **imsg** - Requires macOS iMessage infrastructure
- **things-mac** - Requires macOS Things 3 app
- **peekaboo** - Requires macOS UI automation

#### API Key Required (Set via Environment Variables)
Skills that are installed but require API keys to function:
- **goplaces** - Needs `GOOGLE_PLACES_API_KEY`
- **gog** - Needs Google Cloud credentials
- **notion** - Needs `NOTION_API_KEY`
- **slack** - Needs Slack workspace token
- **trello** - Needs Trello API key
- **openai-whisper-api** - Needs OpenAI API key
- **openai-image-gen** - Needs OpenAI API key

#### Hardware/Service Dependencies
- **eightctl** - Requires Eight Sleep smart bed device
- **openhue** - Requires Philips Hue smart lights
- **sonoscli** - Requires Sonos speaker system
- **blucli** - Requires BluOS compatible device
- **ordercli** - Requires Foodora/Deliveroo account
- **voice-call** - Requires OpenClaw voice plugin setup
- **wacli** - Requires WhatsApp account setup

#### Unavailable/Proprietary
- **model-usage** - CodexBar CLI (proprietary usage tracking)
- **nano-banana-pro** - Gemini 3 Pro Image generation (API-based)
- **nano-pdf** - nano-pdf CLI (availability uncertain)
- **oracle** - Oracle CLI (licensing required)
- **blogwatcher** - blogwatcher CLI (availability uncertain)
- **gifgrep** - gifsicle-based tool (availability uncertain)
- **sag** - ElevenLabs TTS (requires API key + account)
- **summarize** - Multiple fallback tools (mixed availability)
- **local-places** - Requires goplaces + local proxy setup

---

## Official Documentation

- **Main Docs**: https://docs.openclaw.ai/
- **Docker Guide**: https://docs.openclaw.ai/install/docker
- **Configuration Reference**: https://docs.openclaw.ai/gateway/configuration
- **Channel Setup**: https://docs.openclaw.ai/install/docker#channel-setup-optional
- **GitHub**: https://github.com/openclaw/openclaw

---

## Support

- Discord: https://discord.gg/YZ2YyQYW4B
- GitHub Issues: https://github.com/openclaw/openclaw/issues
