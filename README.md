# SilverBullet

Self-hosted Markdown-Wiki im Browser, synchronisiert mit GitHub.

## Einrichtung (einmalig)

### 1. SSH-Key generieren

```bash
bash generate-ssh-key.sh
```

Den ausgegebenen Public Key bei GitHub hinterlegen:  
**Settings → SSH and GPG keys → New SSH key**

### 2. Notes-Repository klonen

```bash
git clone git@github.com:DEIN_USER/DEIN_VAULT_REPO.git space
```

### 3. Umgebungsvariablen anlegen

```bash
cp .env.example .env
# .env anpassen: SB_PASS, GIT_AUTHOR_EMAIL
```

### 4. Lokal testen

```bash
docker compose up
```

SilverBullet läuft dann unter **http://localhost:3000**  
Login: Wert aus `SB_USER` / `SB_PASS` (lokal: `admin` / `localtest`).

Der Syncer schreibt alle 5 Minuten Änderungen zurück nach GitHub.

### 5. Produktiv schalten

`docker-compose.override.yml` entfernen oder umbenennen — dann läuft
der Container ohne exposed Port. Der Reverse Proxy (NPM o.ä.) leitet
intern auf `silverbullet:3000`.

## Dateistruktur

| Pfad | Inhalt |
|------|--------|
| `space/` | SilverBullet-Daten (eigenes Git-Repo, gitignored) |
| `.ssh/` | SSH-Key für GitHub-Sync (gitignored) |
| `.env` | Zugangsdaten (gitignored) |
| `sync-loop.sh` | Sync-Skript das im `syncer`-Container läuft |

## Sync-Intervall anpassen

In `.env`:
```
SYNC_INTERVAL=1800   # alle 30 Minuten
```

## Services

| Service | Zweck |
|---------|-------|
| `app` | SilverBullet-App (Port intern: 3000) |
| `syncer` | Git-Sync-Loop (pull → commit → push) |
