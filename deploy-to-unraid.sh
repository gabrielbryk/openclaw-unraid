#!/bin/bash
set -e

# Deploy OpenClaw Docker image to Unraid Tower server

TOWER_HOST="${TOWER_HOST:-10.0.0.2}"
TOWER_USER="${TOWER_USER:-root}"
TOWER_SSH="ssh ${TOWER_USER}@${TOWER_HOST}"

echo "🚀 Deploying OpenClaw to Tower ($TOWER_HOST)..."
echo ""

# Step 1: Check Tower connectivity
echo "1️⃣  Checking Tower connectivity..."
if ! $TOWER_SSH "echo 'Connected to Tower'" > /dev/null 2>&1; then
  echo "❌ Cannot reach Tower at $TOWER_HOST"
  echo "   Make sure Tower is running and SSH is configured"
  echo "   Try: ssh ${TOWER_USER}@${TOWER_HOST}"
  exit 1
fi
echo "✅ Tower is reachable"
echo ""

# Step 2: Clone repo to Tower
echo "2️⃣  Cloning repository to Tower..."
$TOWER_SSH "cd /tmp && rm -rf openclaw-unraid && git clone https://github.com/YOUR_USERNAME/openclaw-unraid.git"
echo "✅ Repository cloned to /tmp/openclaw-unraid"
echo ""

# Step 3: Build image on Tower
echo "3️⃣  Building Docker image on Tower..."
echo "    (This may take 10-15 minutes on first build)"
$TOWER_SSH "cd /tmp/openclaw-unraid && docker build -t openclaw:latest ."
echo "✅ Image built successfully"
echo ""

# Step 4: Verify image
echo "4️⃣  Verifying image..."
$TOWER_SSH "docker images openclaw:latest"
echo "✅ Image verified"
echo ""

echo "🎉 Deployment complete!"
echo ""
echo "Next steps:"
echo "  1. Go to Unraid WebUI (http://$TOWER_HOST)"
echo "  2. Docker → Add Container"
echo "  3. Select 'openclaw' template"
echo "  4. Configure settings"
echo "  5. Click 'Apply'"
echo ""
echo "Or use docker CLI:"
echo "  ssh ${TOWER_USER}@${TOWER_HOST}"
echo "  docker run -d --name openclaw ..."
