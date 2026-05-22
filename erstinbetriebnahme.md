# Erstinbetriebnahme

Schritt-für-Schritt-Anleitung für den ersten Start von SilverBullet auf einem neuen Server oder lokal.

---

## Voraussetzungen

- Docker + Docker Compose (v2) installiert
- Git installiert
- SSH-Zugang zu GitHub vorhanden (oder wird hier eingerichtet)
- Reverse Proxy läuft bereits (z. B. Nginx Proxy Manager) — nur für Produktivbetrieb nötig

---

## Schritt 1 — Repository klonen

```bash
git clone git@github.com:KayBeckmann/SilverBullet.git
cd SilverBullet
```

---

## Schritt 2 — SSH-Key für GitHub-Sync generieren

Der Syncer-Container braucht einen eigenen SSH-Key, mit dem er Änderungen
nach GitHub pushen darf. Dieser Key liegt lokal im Projektordner und wird
**nicht** ins Repository committet.

```bash
bash generate-ssh-key.sh
```

Das Skript:
- erstellt `.ssh/id_ed25519` + `.ssh/id_ed25519.pub`
- trägt den GitHub-Hostkey in `.ssh/known_hosts` ein
- erstellt `.ssh/config` mit der richtigen Key-Zuordnung
- gibt den Public Key aus

Den ausgegebenen Public Key bei GitHub hinterlegen:  
**github.com → Settings → SSH and GPG keys → New SSH key**

> Titel vorschlag: `silverbullet-sync-<servername>`

---

## Schritt 3 — Notes-Repository klonen

Das `space/`-Verzeichnis ist der Arbeitsordner von SilverBullet.
Hier liegt der Vault (oder ein anderes Markdown-Repository).

```bash
git clone git@github.com:KayBeckmann/obsidian_vault.git space
```

> Alternativ ein leeres Repo klonen oder `git init space` für einen neuen Vault.

---

## Schritt 4 — Umgebungsvariablen anlegen

```bash
cp .env.example .env
```

`.env` anpassen:

| Variable | Beschreibung | Beispiel |
|----------|-------------|---------|
| `SB_USER` | Login-Name in SilverBullet | `admin` |
| `SB_PASS` | Login-Passwort (sicher wählen!) | `MeinSicheresPasswort42` |
| `GIT_AUTHOR_NAME` | Name für Sync-Commits | `SilverBullet Sync` |
| `GIT_AUTHOR_EMAIL` | E-Mail für Sync-Commits | `sync@example.com` |
| `SYNC_INTERVAL` | Sync-Intervall in Sekunden | `900` (= 15 min) |

---

## Schritt 5 — Lokal testen

Für den ersten Test ist `docker-compose.override.yml` aktiv. Sie öffnet
Port 3000 auf `localhost` und setzt das Passwort auf `localtest`.

```bash
docker compose up
```

SilverBullet ist erreichbar unter: **http://localhost:3000**  
Login: `admin` / `localtest`

Sync-Logs prüfen:
```bash
docker compose logs -f syncer
```

Wenn die Logs `[sync] Sync OK` zeigen, funktioniert der GitHub-Sync.

---

## Schritt 6 — Produktivbetrieb aktivieren

Wenn der lokale Test erfolgreich war:

1. `docker-compose.override.yml` umbenennen, damit sie nicht mehr automatisch geladen wird:

```bash
mv docker-compose.override.yml docker-compose.override.yml.disabled
```

2. Container neu starten:

```bash
docker compose down && docker compose up -d
```

3. Im Reverse Proxy (z. B. Nginx Proxy Manager) eine neue Proxy-Host-Route anlegen:

| Feld | Wert |
|------|------|
| Domain | `notes.kay-beckmann.de` |
| Forward Hostname | `silverbullet` |
| Forward Port | `3000` |
| SSL | Let's Encrypt aktivieren |

---

## Sync-Verhalten verstehen

Der `syncer`-Container läuft dauerhaft und führt folgende Schritte in einer Schleife aus:

1. **Warten** (Standard: 15 Minuten)
2. Alle lokalen Änderungen im `space/`-Verzeichnis **committen**
3. Remote-Änderungen per **`git pull --rebase`** holen
4. Lokale Commits **pushen**

Beim Start wird einmalig ein initialer Pull durchgeführt, damit lokale
und Remote-Version direkt synchron sind.

---

## Häufige Probleme

### "SB_PASS nicht gesetzt"
`.env` fehlt oder `SB_PASS` ist leer. Schritt 4 wiederholen.

### Syncer: "Push fehlgeschlagen"
- SSH-Key nicht bei GitHub eingetragen → Schritt 2 wiederholen
- `.ssh/`-Verzeichnis fehlt → `bash generate-ssh-key.sh` ausführen
- Key-Berechtigung falsch: `chmod 600 .ssh/id_ed25519`

### Syncer: "Merge-Konflikt"
Tritt auf wenn Änderungen auf zwei Geräten gleichzeitig gemacht wurden.
Im `space/`-Verzeichnis manuell auflösen:

```bash
cd space
git status
# Konflikte beheben, dann:
git add -A && git commit -m "fix: Merge-Konflikt aufgelöst"
```

### Port 3000 bereits belegt (lokal)
In `docker-compose.override.yml` den Port anpassen:
```yaml
ports:
  - "127.0.0.1:3001:3000"
```
