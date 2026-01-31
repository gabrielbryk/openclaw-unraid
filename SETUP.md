# OpenClaw Setup Guide for Unraid

Complete step-by-step setup for running OpenClaw on Unraid Tower server.

## Prerequisites

- Tower server at 10.0.0.2 with SSH access
- Docker installed on Tower (standard Unraid)
- ~5GB disk space for build
- ~2-3GB for final image
- ~100MB for appdata + workspace volumes

## Step 1: Build Docker Image

Build happens ONCE on Tower, then the image persists.

```bash
# SSH to Tower
ssh unraid

# Clone repository
cd /tmp
git clone https://github.com/YOUR_USERNAME/openclaw-unraid.git
cd openclaw-unraid

# Build image (first time takes 10-15 minutes)
docker build -t openclaw:latest .

# Verify
docker images openclaw:latest
```

**Expected output:**
```
REPOSITORY    TAG       IMAGE ID      CREATED        SIZE
openclaw      latest    abc123...     2 minutes ago   2.8GB
```

## Step 2: Deploy Container on Unraid

### Via Unraid WebUI (Recommended)

1. Open Unraid: `http://10.0.0.2`
2. Go to **Settings** → **Search** → search for "openclaw"
3. Add template to Unraid
4. Go to **Docker** tab
5. Click **Add Container**
6. Select **openclaw** from template dropdown
7. Volumes and ports already configured:
   - AppData: `/mnt/user/appdata/openclaw/`
   - Workspace: `/mnt/user/appdata/openclaw/workspace`
   - Ports: 18789, 18790
8. Click **Apply**

### Via Command Line

```bash
ssh unraid

docker run -d \
  --name openclaw \
  --net bridge \
  -p 18789:18789 \
  -p 18790:18790 \
  -e HOME=/home/node \
  -e TERM=xterm-256color \
  -e NODE_ENV=production \
  -e PUID=99 \
  -e PGID=100 \
  -e TZ=America/Chicago \
  -v /mnt/user/appdata/openclaw:/home/node/.openclaw \
  -v /mnt/user/appdata/openclaw/workspace:/home/node/.openclaw/workspace \
  --restart unless-stopped \
  openclaw:latest
```

## Step 3: First Run & Onboarding

Container will start and initialize. Check status:

```bash
docker ps | grep openclaw
docker logs openclaw --tail 50
```

When you see startup complete, access the Gateway:

```
http://10.0.0.2:18789
```

It will ask for authentication token (auto-generated, check logs):

```bash
docker logs openclaw | grep -i token
```

## Step 4: Run Onboarding Wizard

The wizard configures your AI model provider and workspace:

```bash
docker exec openclaw node dist/index.js onboard
```

Follow prompts for:
- **Model Provider** (Anthropic Claude recommended, or OpenAI/OpenRouter)
- **API Key** (required to use the assistant)
- **Workspace** (where agents/skills are stored)
- **Channels** (optional, configure later if preferred)

## Step 5: Configure Messaging Channels

Add WhatsApp, Telegram, Discord, or Slack to receive messages.

### WhatsApp (Device Linking)

```bash
docker exec openclaw node dist/index.js channels login
```

Scan QR code with your phone. Done!

### Telegram (Bot Token)

Create bot via @BotFather on Telegram, get token, then:

```bash
docker exec openclaw node dist/index.js channels add --channel telegram --token "YOUR_BOT_TOKEN"
```

### Discord (Bot Token)

Create bot in Discord Developer Portal:
1. Go to https://discord.com/developers/applications
2. New Application
3. Bot → Add Bot
4. Copy token

Then add to OpenClaw:

```bash
docker exec openclaw node dist/index.js channels add --channel discord --token "YOUR_BOT_TOKEN"
```

### Slack (App + Bot Token)

Create Slack app at https://api.slack.com/apps:
1. New App → From scratch
2. Name and pick workspace
3. OAuth & Permissions → get Bot Token (starts with `xoxb-`)
4. Socket Mode → Enable & get App Token (starts with `xapp-`)

Add to OpenClaw:

```bash
docker exec openclaw node dist/index.js channels add --channel slack \
  --bot-token "xoxb-..." \
  --app-token "xapp-..."
```

## Step 6: Verify Everything Works

Health check:

```bash
docker exec openclaw node dist/index.js health
```

Expected: `✓ Gateway OK`

Test by messaging the bot on any configured channel. The assistant should respond!

---

## Common Issues & Solutions

### "Image not found"

Image wasn't built. Go back to Step 1:

```bash
cd /tmp/openclaw-unraid
docker build -t openclaw:latest .
```

### "Address already in use"

Port conflict. Check what's using 18789:

```bash
ss -tulpn | grep 18789
```

Pick a different port in Unraid template (e.g., 18799) and redeploy.

### Gateway won't start

Check logs:

```bash
docker logs openclaw
```

Common causes:
- Disk full: `df -h` to check
- Permission issues: Check appdata folder ownership
- Build incomplete: Verify image exists: `docker images openclaw:latest`

### Can't connect to Gateway

Verify port is exposed and listening:

```bash
curl http://10.0.0.2:18789
```

If nothing: container might be crashing. Check logs: `docker logs openclaw --tail 100`

### Can't send to channels

Verify tokens are correct and channel is configured:

```bash
docker exec openclaw node dist/index.js status
```

Shows active channels and any errors.

---

## Persistent Configuration

All settings saved in volumes:

- **Credentials**: `/home/node/.openclaw/` (never loses config)
- **Sessions**: `/home/node/.openclaw/agents/*/sessions/`
- **Skills**: `/home/node/.openclaw/workspace/skills/`

To backup:

```bash
tar czf openclaw-backup-$(date +%s).tar.gz \
  /mnt/user/appdata/openclaw/
```

---

## Updating OpenClaw

When new versions come out:

```bash
# Stop container
docker stop openclaw

# Delete old image
docker rmi openclaw:latest

# Rebuild (pulls latest from GitHub)
cd /tmp/openclaw-unraid
docker build -t openclaw:latest .

# Restart container (via Unraid or docker run)
```

---

## Advanced: Multi-Agent Setup

You can run isolated agents with different configurations. See:
https://docs.openclaw.ai/core-concepts/multi-agent-routing

Example: Personal agent with full access + Family agent with restricted tools.

Configure in `~/.openclaw/openclaw.json`:

```json
{
  "agents": {
    "list": [
      {
        "id": "personal",
        "model": "anthropic/claude-opus-4-5",
        "workspace": "~/.openclaw/workspace"
      },
      {
        "id": "family",
        "model": "anthropic/claude-opus-4-5",
        "workspace": "~/.openclaw/workspace",
        "tools": {
          "sandbox": {
            "tools": {
              "allow": ["read"],
              "deny": ["exec", "write", "browser"]
            }
          }
        }
      }
    ]
  }
}
```

---

## Support & Resources

- **Official Docs**: https://docs.openclaw.ai/
- **Docker Guide**: https://docs.openclaw.ai/install/docker
- **GitHub**: https://github.com/openclaw/openclaw
- **Discord Community**: https://discord.gg/YZ2YyQYW4B
- **Getting Started**: https://docs.openclaw.ai/getting-started

---

## What's Next?

- Add more channels (WhatsApp, Discord, Slack, Signal, iMessage, Teams, etc.)
- Create custom skills in workspace
- Configure multiple agents with different personalities
- Set up browser automation for web tasks
- Enable voice input/output
