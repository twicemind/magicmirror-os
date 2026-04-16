# Changelog

Alle wichtigen Änderungen an MagicMirror OS werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt folgt [Semantic Versioning](https://semver.org/lang/de/).

## [Unreleased]

### Phase 2 - MagicMirror Integration (Geplant)
- [ ] Automatische MagicMirror-Installation
- [ ] User 'mm' Setup
- [ ] Node.js Installation
- [ ] PM2 Auto-Start Konfiguration
- [ ] Basis Module-Konfiguration

### Phase 3 - WiFi-Setup Integration (Geplant)
- [ ] WiFi-Setup Scripts Integration
- [ ] WebUI für WLAN-Konfiguration
- [ ] MMM-WiFiSetup Modul
- [ ] QR-Code Anzeige
- [ ] HotSpot Auto-Start

### Phase 4 - Optimierung (Geplant)
- [ ] Boot-Optimierung
- [ ] Kiosk-Modus
- [ ] Custom Splash-Screen
- [ ] Auto-Update Mechanismus
- [ ] Resource Monitoring

## [0.1.0] - 2026-04-16

### Hinzugefügt - Phase 1: Basis-Setup

#### Build-System
- Vollständiges pi-gen Build-System Setup
- Native Build-Unterstützung (Linux)
- Docker-basierter Build (Cross-Platform)
- Automatisches Build-Environment Setup

#### Scripts
- `build.sh` - Haupt-Build-Script
- `build-docker.sh` - Docker-Build-Script
- `scripts/setup-build-env.sh` - Environment-Setup

#### Konfiguration
- `config/build-config` - Zentrale Build-Konfiguration
- Raspberry Pi OS 64-Bit als Basis
- Debian Bookworm (12) Support
- Deutsche Locale als Standard

#### Dokumentation
- `README.md` - Projekt-Übersicht
- `docs/BUILDING.md` - Detaillierte Build-Anleitung
- `docs/ARCHITECTURE.md` - System-Architektur
- `docs/CUSTOMIZATION.md` - Anpassungs-Guide

#### Features
- Reproduzierbare Image-Builds
- Basis: Raspberry Pi OS Lite 64-Bit
- User 'mm' mit Standard-Passwort
- SSH standardmäßig aktiviert
- Predictable Network Names deaktiviert
- XZ-Kompression für kleinere Images
- Stage-basiertes Build-System

#### Entwicklung
- .gitignore für Build-Artefakte
- Projekt-Struktur etabliert
- Entwicklungs-Workflow dokumentiert

### Technische Details
- **Basis-OS**: Raspberry Pi OS Lite (Bookworm)
- **Architektur**: ARM64 (AArch64)
- **Build-Tool**: pi-gen (official)
- **Default User**: mm
- **Default Hostname**: magicmirror
- **Locale**: de_DE.UTF-8
- **Timezone**: Europe/Berlin

### Known Limitations
- Noch keine MagicMirror-Integration
- Noch keine WiFi-Setup-Integration
- Basis-Image ohne Anpassungen (Phase 1)

## Roadmap

### v0.2.0 - Phase 2 (Q2 2026)
**MagicMirror Integration**
- Stage für User-Setup
- Stage für MagicMirror-Installation
- Stage für Module-System
- Basis-Konfiguration
- PM2 Auto-Start

Geschätzter Release: Mai 2026

### v0.3.0 - Phase 3 (Q2 2026)
**WiFi-Setup Integration**
- WiFi-Setup Scripts
- WebUI Integration
- MMM-WiFiSetup Modul
- HotSpot-Manager
- Systemd Services

Geschätzter Release: Juni 2026

### v1.0.0 - Phase 4 (Q3 2026)
**Production Release**
- Boot-Optimierung
- Kiosk-Modus
- Splash-Screen
- Auto-Update
- Finale Tests
- Release Documentation

Geschätzter Release: Juli 2026

## Versionierungs-Schema

```
vMAJOR.MINOR.PATCH[-PHASE]

Beispiele:
v0.1.0       - Phase 1 Initial Release
v0.2.0       - Phase 2 MagicMirror
v0.3.0       - Phase 3 WiFi-Setup
v1.0.0       - Production Release
v1.1.0       - Neue Features
v1.1.1       - Bugfix
v2.0.0       - Breaking Changes
```

### Regeln
- **MAJOR (X.0.0)**: Breaking Changes, nicht rückwärtskompatibel
- **MINOR (1.X.0)**: Neue Features, rückwärtskompatibel
- **PATCH (1.1.X)**: Bugfixes, rückwärtskompatibel

## Release-Prozess

1. Features entwickeln
2. Testing auf Hardware
3. Dokumentation aktualisieren
4. CHANGELOG.md updaten
5. Version bumpen
6. Git Tag erstellen
7. Image bauen
8. GitHub Release erstellen
9. Image als Asset hochladen
10. Release Notes veröffentlichen

## Support

- **Bug Reports**: GitHub Issues
- **Feature Requests**: GitHub Discussions
- **Dokumentation**: docs/ Verzeichnis

## Lizenz

MIT License - Siehe [LICENSE](../LICENSE)

---

[Unreleased]: https://github.com/youruser/magicmirror-os/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/youruser/magicmirror-os/releases/tag/v0.1.0
