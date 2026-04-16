# Building MagicMirror OS

Diese Anleitung zeigt, wie Sie ein Custom MagicMirror OS Image bauen.

## Übersicht

Das Image wird mit **pi-gen** gebaut, dem offiziellen Tool der Raspberry Pi Foundation für Custom OS Images.

## Voraussetzungen

### Hardware
- Mindestens 25 GB freier Speicherplatz
- 4 GB RAM (8 GB empfohlen)
- Schnelle CPU (Multi-Core empfohlen)

### Software
- **Linux**: Ubuntu 20.04+ oder Debian 11+ (empfohlen)
- Alternatives: Docker (für Builds auf anderen Systemen)

### Pakete (für native Builds)

```bash
sudo apt-get install -y \
    git \
    quilt \
    parted \
    debootstrap \
    zerofree \
    zip \
    dosfstools \
    libarchive-tools \
    libcap2-bin \
    grep \
    rsync \
    xz-utils \
    file \
    curl \
    bc \
    gpg \
    pigz \
    kpartx \
    binfmt-support \
    arch-test

# pi-gen benötigt explizit qemu-user-binfmt
# Falls qemu-user-static installiert ist, zuerst entfernen:
sudo apt-get remove -y qemu-user-static || true
sudo apt-get install -y qemu-user-binfmt
```

**Wichtig:** pi-gen prüft explizit auf `qemu-user-binfmt`, daher muss dieses Paket installiert sein, auch wenn es mit `qemu-user-static` konfliktiert.

## Methode 1: Nativer Build (Empfohlen auf Linux)

### 1. Build-Environment einrichten

```bash
# Repository klonen
git clone <your-repo-url>
cd magicmirror-os

# Build-Environment Setup ausführen
./scripts/setup-build-env.sh
```

Das Script:
- Installiert benötigte Pakete
- Klont pi-gen Repository
- Richtet Build-Verzeichnisse ein

### 2. Konfiguration (Optional)

Bearbeiten Sie `config/build-config` um Build-Parameter anzupassen:

```bash
nano config/build-config
```

Wichtige Optionen:
- `IMG_NAME`: Name des Output-Images
- `RELEASE`: Raspberry Pi OS Release (bookworm, bullseye)
- `DEPLOY_ZIP`: Image komprimieren (0/1)
- `LOCALE_DEFAULT`: Standard-Locale
- `KEYBOARD_LAYOUT`: Tastatur-Layout

### 3. Build starten

```bash
# Standard-Build
./build.sh

# Mit spezifischer Konfiguration
./build.sh --config config/my-custom-config

# Cleanup vor Build (empfohlen bei Problemen)
./build.sh --clean
```

### 4. Build-Prozess

Der Build durchläuft folgende Phasen:

```
1. Vorbereitung
   ├─ Downloads prüfen
   ├─ Verzeichnisse erstellen
   └─ Konfiguration laden

2. Stage 0: Bootstrap
   ├─ Basis-System
   └─ APT-Setup

3. Stage 1: Minimal
   ├─ Kernel
   └─ Grundlegende Tools

4. Stage 2: Lite (Unser Basis)
   ├─ Raspberry Pi OS Lite
   ├─ Netzwerk-Tools
   └─ SSH

5. Stage Custom: MagicMirror
   ├─ User 'mm' erstellen
   ├─ MagicMirror installieren
   ├─ WiFi-Setup
   └─ Optimierungen

6. Finalisierung
   ├─ Image erstellen
   ├─ Komprimieren
   └─ Checksummen
```

### 5. Output

Nach erfolgreichem Build finden Sie:

```
deploy/
├── image_<date>-magicmirror-os-lite.img      # Raw Image
├── image_<date>-magicmirror-os-lite.img.zip  # Komprimiert
└── image_<date>-magicmirror-os-lite.img.sha256
```

**Typische Build-Zeit**: 30-60 Minuten

## Methode 2: Docker-Build (Für macOS/Windows)

### 1. Docker installieren

- macOS: Docker Desktop
- Windows: Docker Desktop oder WSL2 + Docker
- Linux: Docker Engine

### 2. Build mit Docker

```bash
# Einfacher Docker-Build
./build-docker.sh

# Mit Custom-Config
./build-docker.sh --config config/my-config

# Cleanup
./build-docker.sh --clean
```

### 3. Docker-Build-Prozess

Das `build-docker.sh` Script:
1. Baut Docker-Image für Build-Environment
2. Startet Container mit Volume-Mounts
3. Führt Build im Container aus
4. Kopiert fertiges Image nach `deploy/`

**Vorteil**: Funktioniert auf jedem System mit Docker  
**Nachteil**: Langsamer als nativer Build

## Methode 3: GitHub Actions (CI/CD)

Für automatisierte Builds steht ein GitHub Actions Workflow bereit.

### Setup

1. Fork des Repositories
2. Aktiviere GitHub Actions
3. Konfiguriere Secrets (falls nötig)

### Trigger

```bash
# Manual Trigger
git tag v1.0.0
git push origin v1.0.0

# Oder über GitHub UI: Actions → Build Image → Run workflow
```

### Output

Fertiges Image wird als Release-Asset hochgeladen.

## Build-Konfiguration

### Basis-Konfiguration: `config/build-config`

```bash
# Image-Name
IMG_NAME="magicmirror-os"

# Raspberry Pi OS Release
RELEASE="bookworm"  # oder "bullseye"

# Architektur
ARCH="arm64"  # 64-Bit

# Deployment
DEPLOY_ZIP=1          # ZIP erstellen
DEPLOY_COMPRESSION=xz # Kompression (zip, xz, gz)

# Locale
LOCALE_DEFAULT="de_DE.UTF-8"
KEYBOARD_LAYOUT="de"
TIMEZONE_DEFAULT="Europe/Berlin"

# Hostname
HOSTNAME="magicmirror"

# User (wird in Stage erstellt)
FIRST_USER_NAME="mm"
FIRST_USER_PASS="magicmirror"

# WiFi (für Ersteinrichtung, optional)
# WPA_SSID="YourSSID"
# WPA_PASSWORD="YourPassword"

# Disable/Enable Stages
SKIP_STAGE3=1  # Kein Desktop
SKIP_STAGE4=1  # Keine zusätzliche Software
SKIP_STAGE5=1  # Wird für unsere Stages verwendet

# Performance
PARALLEL_BUILD=1      # Parallel builds
BUILD_THREADS=4       # CPU Cores
```

### Erweiterte Optionen

```bash
# Kernel
KERNEL_BRANCH="stable"  # oder "rpi-<version>"

# APT
APT_PROXY=""           # Proxy für schnellere Downloads

# Image
IMAGE_SIZE="4GB"       # oder "8GB", "auto"

# Extra Pakete
EXTRA_PACKAGES="vim htop tmux"
```

## Stage-System

### Stage-Struktur

Jede Stage hat folgende Struktur:

```
stage-name/
├── 00-run.sh           # Setup-Script
├── 01-packages         # APT-Pakete
├── 02-run-chroot.sh    # Im Chroot ausführen
└── files/              # Dateien zum Kopieren
    └── etc/
        └── ...
```

### Eigene Stage erstellen

```bash
# Neue Stage erstellen
mkdir -p stages/stage-custom

# Basis-Script
cat > stages/stage-custom/00-run.sh << 'EOF'
#!/bin/bash -e
# Stage: Custom modifications
log "Installing custom packages..."
# Hier Ihre Befehle
EOF

chmod +x stages/stage-custom/00-run.sh
```

### Stage in Build integrieren

```bash
# In build-config
CUSTOM_STAGES="stage-magicmirror stage-wifi-setup stage-custom"
```

## Troubleshooting

### Problem: "Required dependencies not installed" - qemu-user-binfmt

**Fehlermeldung:**
```
Required dependencies not installed
This can be resolved on Debian/Raspbian systems by installing:
qemu-user-binfmt
```

**Ursache:** pi-gen prüft explizit auf das Paket `qemu-user-binfmt`.

**Lösung:**
```bash
# Entferne qemu-user-static (konfliktiert mit qemu-user-binfmt)
sudo apt-get remove -y qemu-user-static || true

# Installiere qemu-user-binfmt
sudo apt-get install -y qemu-user-binfmt binfmt-support arch-test

# Registriere QEMU binfmt
sudo systemctl restart systemd-binfmt.service
sudo update-binfmts --enable

# Prüfe Registrierung
update-binfmts --display | grep qemu-aarch64

# Erneut versuchen
sudo ./build.sh --clean
```

**Hinweis:** Obwohl `qemu-user-static` funktional äquivalent ist, benötigt pi-gen spezifisch `qemu-user-binfmt` für seinen Dependency-Check.

### Problem: Build schlägt fehl mit "Permission denied"

**Lösung**:
```bash
# Berechtigungen prüfen
ls -la pi-gen/

# Scripts ausführbar machen
chmod +x build.sh
chmod +x scripts/*.sh

# Als sudo bauen (falls nötig)
sudo ./build.sh
```

### Problem: "No space left on device"

**Lösung**:
```bash
# Speicherplatz prüfen
df -h

# Alte Builds löschen
./build.sh --clean

# /tmp aufräumen
sudo rm -rf /tmp/pi-gen-*
```

### Problem: Build ist sehr langsam

**Lösungen**:

1. **Mehr CPU-Kerne nutzen**:
   ```bash
   # In build-config
   BUILD_THREADS=8
   ```

2. **APT-Proxy verwenden**:
   ```bash
   # In build-config
   APT_PROXY="http://your-proxy:3142"
   ```

3. **SSD statt HDD nutzen**

### Problem: "QEMU errors"

**Lösung**:
```bash
# QEMU neu installieren
sudo apt-get install --reinstall qemu-user-binfmt

# Binfmt Registrierung prüfen
update-binfmts --display
```

### Problem: Image bootet nicht

**Diagnose**:

1. **Image-Integrität prüfen**:
   ```bash
   sha256sum deploy/*.img
   ```

2. **Partitionen prüfen**:
   ```bash
   fdisk -l deploy/*.img
   ```

3. **Mount und untersuchen**:
   ```bash
   sudo losetup -P /dev/loop0 deploy/*.img
   sudo mount /dev/loop0p2 /mnt
   ls -la /mnt
   sudo umount /mnt
   sudo losetup -d /dev/loop0
   ```

## Image testen

### Test mit QEMU (ohne Hardware)

```bash
# Script verwenden
./scripts/test-image.sh deploy/magicmirror-os.img

# Oder manuell
qemu-system-aarch64 \
  -machine type=raspi3b \
  -cpu cortex-a72 \
  -m 1G \
  -sd deploy/magicmirror-os.img \
  -serial stdio
```

### Test auf Hardware

1. **Image flashen**:
   ```bash
   sudo dd if=deploy/magicmirror-os.img of=/dev/sdX bs=4M status=progress
   sync
   ```

2. **SD-Karte in Pi einlegen**

3. **Booten und testen**

## Performance-Optimierung

### Schnellerer Build

```bash
# ccache nutzen
sudo apt-get install ccache
export PATH="/usr/lib/ccache:$PATH"

# tmpfs für Build (wenn genug RAM)
sudo mount -t tmpfs -o size=10G tmpfs /tmp/pi-gen-work

# Build
./build.sh
```

### Kleineres Image

```bash
# In Stage-Script
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
find /var/log -type f -delete
```

## Continuous Integration

Beispiel GitHub Actions Workflow:

```yaml
name: Build MagicMirror OS

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Image
        run: |
          sudo ./scripts/setup-build-env.sh
          sudo./build.sh
      - name: Upload Release
        uses: actions/upload-artifact@v3
        with:
          name: magicmirror-os-image
          path: deploy/*.zip
```

## Best Practices

1. ✅ **Immer cleanen zwischen Builds**: `./build.sh --clean`
2. ✅ **Versionierung nutzen**: Tags für Releases
3. ✅ **Logs aufbewahren**: Build-Logs sind wertvoll für Debugging
4. ✅ **Images testen**: Vor Veröffentlichung testen
5. ✅ **Checksummen verifizieren**: SHA256 immer prüfen

## Weitere Ressourcen

- [pi-gen GitHub](https://github.com/RPi-Distro/pi-gen)
- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
- [Custom Raspberry Pi OS Tutorial](https://github.com/RPi-Distro/pi-gen/blob/master/README.md)

## Support

Bei Problemen:
1. Logs prüfen: `work/*/build.log`
2. GitHub Issues
3. Community Forum
