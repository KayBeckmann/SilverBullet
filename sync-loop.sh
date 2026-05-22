#!/bin/sh
set -e

SPACE=/space
INTERVAL=${SYNC_INTERVAL:-900}

git config --global user.name  "${GIT_AUTHOR_NAME:-SilverBullet Sync}"
git config --global user.email "${GIT_AUTHOR_EMAIL:-sync@silverbullet}"
git config --global --add safe.directory "$SPACE"
git config --global pull.rebase true

log() { echo "[sync] $(date '+%Y-%m-%d %H:%M:%S') $*"; }

log "Starte – Intervall: ${INTERVAL}s"

# Initialer Pull
cd "$SPACE"
BRANCH=$(git branch --show-current)
git pull origin "$BRANCH" 2>&1 || log "Initialer Pull fehlgeschlagen – weiter"

sync_once() {
  cd "$SPACE"
  BRANCH=$(git branch --show-current)

  # Lokale Änderungen committen
  if ! git diff --quiet || ! git diff --cached --quiet; then
    git add -A
    git commit -m "sync: $(date '+%Y-%m-%d %H:%M:%S')"
    log "Commit erstellt"
  fi

  # Remote holen und rebasen
  git pull origin "$BRANCH" 2>&1 || { log "Pull fehlgeschlagen"; return 1; }

  # Pushen
  git push origin "$BRANCH" 2>&1 || { log "Push fehlgeschlagen"; return 1; }

  log "Sync OK"
}

while true; do
  sleep "$INTERVAL"
  sync_once || true
done
