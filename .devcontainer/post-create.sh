#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Installing npm dependencies"
# node_modules is a named volume, which docker creates owned by root
sudo chown "$(id -u):$(id -g)" node_modules
npm install

echo "==> Installing python dependencies"
pip install --no-cache-dir -r requirements.txt

if [ ! -f .env ]; then
	echo "==> Creating .env from .env.example (fill in your bot credentials before deploying)"
	cp .env.example .env
fi

echo "==> Done. Try: npm run lua-test"
