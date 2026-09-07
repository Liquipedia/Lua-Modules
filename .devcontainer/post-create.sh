#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Installing npm dependencies"
# node_modules is a named volume, which docker creates owned by root. Recursive
# because a volume that outlives a rebuild keeps whatever uid wrote it, and the
# user we run as has not always had the same one: fixing only the mount point
# leaves npm unable to rename anything inside it
sudo mkdir -p node_modules
sudo chown -R "$(id -u):$(id -g)" node_modules
npm install

echo "==> Installing python dependencies"
pip install --no-cache-dir -r requirements.txt

if [ ! -f .env ]; then
	echo "==> Creating .env from .env.example (fill in your bot credentials before deploying)"
	# Nobody chose these settings, we generated them, so start in dry-run and
	# leave turning off DRY_RUN as a deliberate act
	sed 's/^DRY_RUN=.*/DRY_RUN=1/' .env.example > .env
	echo "    DRY_RUN=1 is set, deploys are simulated until you change it"
fi

echo "==> Done. Try: npm run lua-test"
