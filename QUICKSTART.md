# Quick Start - MagicMirror OS

Die schnellste Methode, um ein MagicMirror OS Image zu bauen.

## Voraussetzungen

- Linux-System (Ubuntu/Debian empfohlen)
- Oder Docker (für macOS/Windows)
- 25 GB freier Speicher
- Internet-Verbindung

## 3-Schritte Installation

### Schritt 1: Repository klonen

```bash
git clone https://github.com/youruser/magicmirror-os.git
cd magicmirror-os
```

### Schritt 2: Build-Environment einrichten

**Auf Linux:**
```bash
sudo ./scripts/setup-build-env.sh
```

**Mit Docker (alle Plattformen):**
```bash
# Keine Installation nötig, geht direkt zu Schritt 3
```

### Schritt 3: Image bauen

**Native Build (Linux):**
```bash
sudo ./build.sh
```

**Docker Build (alle Plattformen):**
```bash
./build-docker.sh
```

⏱️ **Build-Zeit:** 30-60 Minuten

## Ergebnis

Nach erfolgreichem Build:

```
deploy/
├── 2026-04-16-magicmirror-os-lite.img       # Raw Image (~2 GB)
├── 2026-04-16-magicmirror-os-lite.img.xz    # Komprimiert (~500 MB)
└── 2026-04-16-magicmirror-os-lite.img.sha256 # Checksum
```

## Image auf SD-Karte schreiben

### Methode 1: Raspberry Pi Imager (Empfohlen)

1. Download: https://www.raspberrypi.com/software/
2. Öffnen Sie Raspberry Pi Imager
3. Wählen Sie "Custom Image"
4. Wählen Sie die `.img` oder `.img.xz` Datei
5. Wählen Sie Ihre SD-Karte
6. Klicken Sie auf "Write"

### Methode 2: dd (Linux/macOS)

```bash
# .img.xz Datei
xzcat deploy/*.img.xz | sudo dd of=/dev/sdX bs=4M status=progress

# Oder .img Datei
sudo dd if=deploy/*.img of=/dev/sdX bs=4M status=progress conv=fsync

# Sync
sync
```

**⚠️ WICHTIG:** Ersetzen Sie `/dev/sdX` mit Ihrem tatsächlichen SD-Karten-Device!

Finden Sie das richtige Device:
```bash
# Vor dem Einstecken
lsblk

# Nach dem Einstecken der SD-Karte
lsblk

# Der neue Eintrag ist Ihre SD-Karte (z.B. /dev/sdb)
```

### Methode 3: Etcher

1. Download: https://www.balena.io/etcher/
2. Öffnen Sie Etcher
3. "Flash from file" → Wählen Sie `.img.xz`
4. "Select target" → Wählen Sie SD-Karte
5. "Flash!"

## Erster Boot

1. **SD-Karte einlegen** in Raspberry Pi
2. **Strom anschließen**
3. **Warten** (~1-2 Minuten für ersten Boot)
4. **Login:**
   - User: `mm`
   - Passwort: `magicmirror`

**🔒 Ändern Sie das Passwort sofort:**
```bash
passwd
```

## Standard-Konfiguration

Das Image kommt mit:
- ✅ User `mm` (Passwort: `magicmirror`)
- ✅ SSH aktiviert
- ✅ Deutsche Locale (de_DE.UTF-8)
- ✅ Timezone: Europe/Berlin
- ✅ Hostname: `magicmirror`

## Nächste Schritte

### SSH-Verbindung

```bash
# IP-Adresse finden
hostname -I

# Von anderem Computer
ssh mm@<raspberry-pi-ip>
```

### WiFi konfigurieren

```bash
sudo raspi-config
# → System Options → Wireless LAN
```

Oder editieren:
```bash
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
```

### System aktualisieren

```bash
sudo apt update
sudo apt upgrade
```

## Anpassungen vor Build

Wenn Sie das Image **vor** dem Build anpassen möchten:

### Sprache/Tastatur ändern

`config/build-config`:
```bash
LOCALE_DEFAULT="en_GB.UTF-8"
KEYBOARD_KEYMAP="gb"
KEYBOARD_LAYOUT="English (UK)"
TIMEZONE_DEFAULT="Europe/London"
```

### User/Passwort ändern

`config/build-config`:
```bash
FIRST_USER_NAME="admin"
FIRST_USER_PASS="secure-password"
```

### WiFi vorkonfigurieren

`config/build-config`:
```bash
WPA_SSID="YourWiFiSSID"
WPA_PASSWORD="YourWiFiPassword"
WPA_COUNTRY="DE"
```

Dann neu bauen:
```bash
sudo ./build.sh
```

## Troubleshooting

### Build schlägt fehl

```bash
# Cleanup und erneut versuchen
sudo ./build.sh --clean
```

### Permission denied

```bash
# Scripts ausführbar machen
chmod +x build.sh build-docker.sh scripts/*.sh
```

### Nicht genug Speicher

```bash
# Freien Speicher prüfen
df -h

# Mindestens 15 GB nötig
```

### Docker-Build langsam

Das ist normal - Docker-Builds sind langsamer als native Builds.
Für schnellere Builds verwenden Sie Linux mit nativem Build.

## Weitere Hilfe

- **Detaillierte Build-Anleitung:** [docs/BUILDING.md](docs/BUILDING.md)
- **Architektur:** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Anpassungen:** [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md)
- **GitHub Issues:** Für Bugs und Feature-Requests

## Support

Bei Problemen:
1. Prüfen Sie [docs/BUILDING.md](docs/BUILDING.md)
2. Suchen Sie in GitHub Issues
3. Erstellen Sie ein neues Issue mit:
   - OS-Version
   - Build-Log
   - Fehlermeldung

## Was kommt als Nächstes?

**Phase 1 (Aktuell):** ✅ Basis Raspberry Pi OS Image  
**Phase 2 (Geplant):** MagicMirror-Installation  
**Phase 3 (Geplant):** WiFi-Setup Integration  
**Phase 4 (Geplant):** Optimierungen & Release v1.0.0

Siehe [CHANGELOG.md](CHANGELOG.md) für Details.
