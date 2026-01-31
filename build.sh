#!/bin/bash
set -e

echo "🔨 Building OpenClaw Docker image..."
docker build -t openclaw:latest .

if [ $? -eq 0 ]; then
  echo "✅ Build successful!"
  echo ""
  echo "Image details:"
  docker images openclaw:latest
  echo ""
  echo "Next steps:"
  echo "  • Local test: docker-compose up -d"
  echo "  • Check logs: docker-compose logs -f openclaw"
  echo "  • Access: http://localhost:18789"
else
  echo "❌ Build failed"
  exit 1
fi
