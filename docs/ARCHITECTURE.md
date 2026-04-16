# MagicMirror OS - Architektur

## Übersicht

MagicMirror OS ist ein Custom Raspberry Pi OS Image, das auf dem offiziellen Raspberry Pi OS basiert und vollständig für MagicMirror vorkonfiguriert ist.

## Build-System: pi-gen

### Was ist pi-gen?

pi-gen ist das offizielle Image-Build-System der Raspberry Pi Foundation. Es wird verwendet, um die offiziellen Raspberry Pi OS Images zu erstellen.

**Vorteile:**
- ✅ Offiziell supported
- ✅ Reproduzierbare Builds
- ✅ Stage-basiertes System
- ✅ Aktiv maintained

**Repository:** https://github.com/RPi-Distro/pi-gen

### Stage-basiertes System

pi-gen baut Images in Stages (Phasen):

```
Stage 0: Bootstrap
    ├─ Debian Base System
    ├─ debootstrap
    └─ Essential Packages

Stage 1: Minimal Raspberry Pi
    ├─ Kernel
    ├─ Firmware
    └─ Basic Tools

Stage 2: Raspberry Pi OS Lite
    ├─ Networking
    ├─ SSH Server
    ├─ WiFi Tools
    └─ System Services

Stage 3: Desktop (Optional)
    ├─ X11
    ├─ Desktop Environment
    └─ GUI Tools

Stage 4: Recommended (Optional)
    ├─ LibreOffice
    ├─ Chromium
    └─ Additional Software

Stage 5: Custom (Unsere Stages)
    ├─ stage-magicmirror
    ├─ stage-wifi-setup
    └─ stage-optimizations
```

## Unser Build-Prozess

### Phase 1: Basis (Aktuell)

```
Input: Raspberry Pi OS Lite 64-Bit
    ↓
Stage 0-2: Offizielles Pi OS
    ↓
Output: Unmodifiziertes Lite Image
```

**Ziel:** Etablierung des Build-Prozesses ohne Änderungen.

### Phase 2: MagicMirror Integration (Geplant)

```
Stage 0-2: Basis Pi OS
    ↓
Stage Custom 1: User Setup
    ├─ User 'mm' erstellen
    ├─ Gruppen konfigurieren
    └─ Home-Directory
    ↓
Stage Custom 2: MagicMirror
    ├─ Node.js installieren
    ├─ MagicMirror klonen
    ├─ Dependencies installieren
    ├─ PM2 konfigurieren
    └─ Auto-Start einrichten
    ↓
Stage Custom 3: Module
    ├─ Standard-Module
    ├─ Custom-Module
    └─ Konfiguration
```

### Phase 3: WiFi-Setup (Geplant)

```
Stage Custom 4: WiFi-Setup
    ├─ HotSpot-Manager
    ├─ Network-Check Scripts
    ├─ WebUI
    ├─ MMM-WiFiSetup Modul
    └─ Systemd Services
```

### Phase 4: Optimierung (Geplant)

```
Stage Custom 5: Optimizations
    ├─ Boot-Optimierung
    ├─ Kiosk-Modus
    ├─ Splash-Screen
    ├─ Resource Limits
    └─ Cleanup
```

## Ordnerstruktur

### Aktuell (Phase 1)

```
magicmirror-os/
├── README.md                   # Projekt-Übersicht
├── build.sh                    # Haupt-Build-Script
├── build-docker.sh             # Docker Build
├── .gitignore                  # Git Ignore Rules
├── config/
│   └── build-config            # pi-gen Konfiguration
├── scripts/
│   └── setup-build-env.sh      # Environment Setup
└── docs/
    ├── BUILDING.md             # Build-Anleitung
    └── ARCHITECTURE.md         # Diese Datei
```

### Geplant (Phase 2+)

```
magicmirror-os/
├── ...
├── stages/
│   ├── stage-magicmirror/
│   │   ├── 00-packages         # APT-Pakete
│   │   ├── 01-install-nodejs.sh
│   │   ├── 02-install-mm.sh
│   │   ├── 03-configure-pm2.sh
│   │   └── files/
│   │       └── home/mm/
│   ├── stage-wifi-setup/
│   │   ├── 00-packages
│   │   ├── 01-install-scripts.sh
│   │   ├── 02-configure-services.sh
│   │   └── files/
│   │       ├── opt/wifi-setup-webui/
│   │       └── etc/systemd/system/
│   └── stage-optimizations/
│       ├── 00-boot-optimization.sh
│       ├── 01-kiosk-mode.sh
│       └── 02-cleanup.sh
└── modules/
    └── custom-modules.json     # Module-Definitionen
```

## Build-Workflow

### 1. Vorbereitung

```bash
./scripts/setup-build-env.sh
```

- Installiert Dependencies
- Klont pi-gen
- Richtet Verzeichnisse ein

### 2. Konfiguration

```bash
# Bearbeiten
nano config/build-config

# Wichtige Optionen:
# - IMG_NAME: Output-Name
# - RELEASE: bookworm/bullseye
# - ARCH: arm64/armhf
# - FIRST_USER_NAME/PASS
```

### 3. Build

```bash
./build.sh

# Oder mit Docker
./build-docker.sh
```

**Intern:**

```
build.sh
    ↓
Lade config/build-config
    ↓
Klone/Update pi-gen
    ↓
Kopiere Konfiguration → pi-gen/config
    ↓
Kopiere Custom Stages → pi-gen/
    ↓
Führe pi-gen/build.sh aus
    ↓
    ├─ Stage 0: Bootstrap
    ├─ Stage 1: Minimal
    ├─ Stage 2: Lite
    ├─ Stage Custom 1: User
    ├─ Stage Custom 2: MagicMirror
    ├─ Stage Custom 3: WiFi-Setup
    └─ Stage Custom 4: Optimizations
    ↓
Erstelle Image
    ↓
Komprimiere (xz)
    ↓
Kopiere nach deploy/
```

### 4. Output

```
deploy/
├── <date>-magicmirror-os-lite.img       # Raw Image
├── <date>-magicmirror-os-lite.img.xz    # Komprimiert
└── <date>-magicmirror-os-lite.img.sha256
```

## Technische Details

### Image-Format

- **Partitionierung**: 
  - `/boot` (FAT32, ~256 MB)
  - `/` (ext4, Rest)

- **Größe**: 
  - Basis: ~1.5 GB
  - Mit MagicMirror: ~3-4 GB
  - Empfohlen: 8 GB+ SD-Karte

### Chroot-Umgebung

pi-gen verwendet `chroot` für Package-Installation:

```bash
# In Stage-Script
on_chroot << EOF
apt-get update
apt-get install -y nodejs npm
EOF
```

### QEMU für ARM

Auf x86-Systemen wird QEMU genutzt:

```
Host (x86_64)
    ↓
QEMU User-Mode Emulation
    ↓
ARM64 Binaries (im chroot)
```

### File-Injection

Dateien können direkt ins Image kopiert werden:

```bash
# In Stage
install -m 644 files/config.js ${ROOTFS_DIR}/home/mm/MagicMirror/config/
```

## Phasen-Planung

### Phase 1: Basis ✓ (Aktuell)

**Ziel:** Erfolgreiche Builds von unmodifiziertem Pi OS

**Deliverables:**
- ✓ Build-Scripts
- ✓ Dokumentation
- ✓ Konfiguration
- ✓ Docker-Support

### Phase 2: MagicMirror

**Ziel:** Vollständige MagicMirror-Installation

**Tasks:**
- [ ] User 'mm' Setup-Stage
- [ ] Node.js Installation-Stage
- [ ] MagicMirror Installation-Stage
- [ ] PM2 Konfiguration
- [ ] Test-Image

**Timeline:** 1-2 Wochen

### Phase 3: WiFi-Setup

**Ziel:** Integration des WiFi-Setup Systems

**Tasks:**
- [ ] WiFi-Setup Scripts portieren
- [ ] WebUI installieren
- [ ] MMM-WiFiSetup Modul
- [ ] Systemd Services
- [ ] Test und Debugging

**Timeline:** 1 Woche

### Phase 4: Optimierung

**Ziel:** Production-Ready Image

**Tasks:**
- [ ] Boot-Optimierung
- [ ] Kiosk-Modus
- [ ] Auto-Update
- [ ] Monitoring
- [ ] Finale Tests

**Timeline:** 1 Woche

## Image-Releases

### Versioning

```
vMAJOR.MINOR.PATCH
```

- **MAJOR**: Breaking Changes
- **MINOR**: Neue Features
- **PATCH**: Bugfixes, Updates

Beispiel: `v1.0.0`, `v1.1.0`, `v1.1.1`

### Release-Prozess

```
1. Build Image
2. Test auf Hardware
3. Dokumentation Update
4. Git Tag erstellen
5. Image zu GitHub Releases
6. Changelog aktualisieren
```

## Testing

### Emulator (QEMU)

```bash
qemu-system-aarch64 \
  -machine raspi3b \
  -cpu cortex-a72 \
  -m 1G \
  -sd deploy/magicmirror-os.img \
  -serial stdio
```

**Limitation:** Kein echtes GPU, langsamer

### Hardware

1. Image auf SD-Karte flashen
2. In Raspberry Pi einlegen
3. Booten und testen
4. Logs prüfen

## Troubleshooting

### Build schlägt fehl

**Logs prüfen:**
```bash
# pi-gen Logs
cat pi-gen/work/*/build.log

# Stage-spezifische Logs
cat pi-gen/work/*/stage*/build.log
```

### Image bootet nicht

1. Image-Integrität prüfen
2. Partitionen untersuchen
3. Boot-Partition mounten
4. Logs in `/var/log/` prüfen

### Langsame Builds

- APT-Proxy nutzen
- SSD statt HDD
- Mehr RAM
- Mehr CPU-Cores

## Referenzen

- [pi-gen GitHub](https://github.com/RPi-Distro/pi-gen)
- [pi-gen Wiki](https://github.com/RPi-Distro/pi-gen/wiki)
- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
- [Debian ARM](https://wiki.debian.org/Arm)

## Nächste Schritte

1. ✅ Phase 1 abschließen (Basis-Builds)
2. Stage-magicmirror entwickeln
3. Stage-wifi-setup integrieren
4. Testing und Optimierung
5. Erstes Release (v1.0.0)
