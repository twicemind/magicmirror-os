# MagicMirror OS

Ein vollständig vorkonfiguriertes Raspberry Pi OS Image für MagicMirror mit automatischem WiFi-Setup.

## Übersicht

MagicMirror OS ist ein Custom Raspberry Pi OS 64-Bit Image, das:
- Komplett vorkonfiguriert ist
- MagicMirror vorinstalliert hat
- WiFi-Setup mit QR-Code Integration enthält
- Sofort einsatzbereit ist nach dem Flashen

## Konzept

Statt nachträglicher Installation von MagicMirror auf einem Standard Raspberry Pi OS, wird ein komplettes, bootfähiges Image erstellt, das alle Komponenten bereits enthält.

### Vorteile

✅ **Plug & Play**: Image flashen, SD-Karte einlegen, fertig  
✅ **Konsistenz**: Alle Installationen sind identisch  
✅ **Geschwindigkeit**: Keine langwierige Installation nötig  
✅ **Versionskontrolle**: Jedes Release ist getestet und reproduzierbar  
✅ **Updates**: Neue Images können einfach verteilt werden  

## Basis

- **Base OS**: Raspberry Pi OS Lite 64-Bit (aktuellste Version)
- **Build-Tool**: pi-gen (offizielles Tool der Raspberry Pi Foundation)
- **Ziel-Hardware**: Raspberry Pi 3/4/5

## Projekt-Status

### Phase 1: Basis-Setup ✓ (Aktuell)
- [ ] pi-gen Setup und Dokumentation
- [ ] Basis Raspberry Pi OS 64-Bit Image Building
- [ ] Build-Environment einrichten
- [ ] Erste Test-Builds durchführen

### Phase 2: MagicMirror Integration (Geplant)
- [ ] MagicMirror Auto-Installation
- [ ] User 'mm' Konfiguration
- [ ] Module-System Integration
- [ ] PM2 Auto-Start

### Phase 3: WiFi-Setup Integration (Geplant)
- [ ] WiFi-Setup Scripts
- [ ] WebUI Integration
- [ ] QR-Code Modul
- [ ] HotSpot Auto-Start

### Phase 4: Optimierung (Geplant)
- [ ] Boot-Optimierung
- [ ] Kiosk-Modus
- [ ] Splash-Screen
- [ ] Auto-Update Mechanismus

## Schnellstart

### Voraussetzungen

- Linux-System (Ubuntu/Debian empfohlen)
- Mindestens 25 GB freier Speicherplatz
- sudo-Rechte
- Git, Docker (optional)

### Image bauen

```bash
# Repository klonen
git clone <repository-url>
cd magicmirror-os

# Build starten
./build.sh

# Oder mit Docker
./build-docker.sh
```

Das fertige Image liegt dann unter: `deploy/`

### Image verwenden

```bash
# Image auf SD-Karte schreiben (z.B. mit Raspberry Pi Imager)
# Oder mit dd:
sudo dd if=deploy/magicmirror-os.img of=/dev/sdX bs=4M status=progress
```

## Struktur

```
magicmirror-os/
├── README.md                   # Diese Datei
├── build.sh                    # Haupt-Build-Script
├── build-docker.sh             # Docker-basierter Build
├── config                      # Build-Konfiguration
│   └── build-config            # pi-gen Konfiguration
├── stages/                     # Build-Stages
│   ├── stage-magicmirror/      # MagicMirror Installation
│   ├── stage-wifi-setup/       # WiFi-Setup Integration
│   └── stage-optimizations/    # System-Optimierungen
├── scripts/                    # Helper-Scripts
│   ├── setup-build-env.sh      # Build-Environment Setup
│   └── test-image.sh           # Image-Testing
└── docs/                       # Dokumentation
    ├── BUILDING.md             # Build-Anleitung
    ├── ARCHITECTURE.md         # System-Architektur
    └── CUSTOMIZATION.md        # Anpassungen
```

## Dokumentation

- [BUILDING.md](docs/BUILDING.md) - Detaillierte Build-Anleitung
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - System-Architektur
- [CUSTOMIZATION.md](docs/CUSTOMIZATION.md) - Image anpassen

## Technische Details

### Was ist pi-gen?

pi-gen ist das offizielle Tool der Raspberry Pi Foundation zum Erstellen von Custom Raspberry Pi OS Images. Es verwendet ein Stage-basiertes System:

- **Stage 0**: Basis-System (apt, kernel)
- **Stage 1**: Minimales System
- **Stage 2**: Raspberry Pi OS Lite
- **Stage 3**: Desktop-Environment (Optional)
- **Stage 4**: Empfohlene Software (Optional)
- **Stage 5**: Custom Stages (Unsere Anpassungen)

### Unser Ansatz

Wir bauen auf Stage 2 (Lite) auf und fügen eigene Stages hinzu:
- **stage-magicmirror**: Installation von MagicMirror
- **stage-wifi-setup**: WiFi-Setup Integration
- **stage-optimizations**: System-Optimierungen

## Entwicklung

### Build-Environment lokal einrichten

```bash
cd magicmirror-os
./scripts/setup-build-env.sh
```

### Build-Prozess

Der Build-Prozess:
1. Lädt aktuelles Raspberry Pi OS Lite 64-Bit
2. Führt alle Stages aus
3. Erstellt bootfähiges Image
4. Komprimiert das Image

Dauer: ~30-60 Minuten (abhängig von Hardware)

## Lizenz

MIT

## Autor

TwiceMind