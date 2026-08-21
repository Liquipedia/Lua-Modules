#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Installing npm dependencies"
# these are named volumes, which docker creates owned by root
sudo chown "$(id -u):$(id -g)" node_modules ~/.mitmproxy
npm install

echo "==> Installing python dependencies"
pip install --no-cache-dir -r requirements.txt

echo "==> Building css and js"
# The proxy serves these, and without them it silently passes requests through
npm run build

if [ ! -f .env ]; then
	echo "==> Creating .env from .env.example (fill in your bot credentials before deploying)"
	# Nobody chose these settings, we generated them, so start in dry-run and
	# leave turning off DRY_RUN as a deliberate act
	sed 's/^DRY_RUN=.*/DRY_RUN=1/' .env.example > .env
	echo "    DRY_RUN=1 is set, deploys are simulated until you change it"
fi

echo "==> Done. Try: npm run lua-test"
