# Image Customization Guide

## Übersicht

Diese Anleitung zeigt, wie Sie MagicMirror OS nach Ihren Wünschen anpassen können.

## Build-Konfiguration anpassen

### Basis-Einstellungen

Bearbeiten Sie `config/build-config`:

```bash
nano config/build-config
```

#### Image-Name ändern

```bash
IMG_NAME="my-custom-magicmirror"
```

#### Locale und Timezone

```bash
LOCALE_DEFAULT="en_GB.UTF-8"
KEYBOARD_KEYMAP="gb"
KEYBOARD_LAYOUT="English (UK)"
TIMEZONE_DEFAULT="Europe/London"
```

#### User-Credentials

```bash
FIRST_USER_NAME="admin"
FIRST_USER_PASS="secure-password-123"
```

**Wichtig:** Credentials sollten nach erstem Boot geändert werden!

#### WiFi vorkonfigurieren

```bash
WPA_SSID="MeinWLAN"
WPA_PASSWORD="MeinPasswort"
WPA_COUNTRY="DE"
```

Das Image verbindet sich beim ersten Boot automatisch.

## Custom Stages erstellen

### Stage-Struktur

Eine Stage ist ein Verzeichnis in `stages/` mit Scripts und Dateien:

```
stages/
└── stage-myfeature/
    ├── 00-packages         # APT-Pakete (optional)
    ├── 01-run.sh           # Setup-Script
    ├── 02-run-chroot.sh    # Im Chroot ausführen
    └── files/              # Dateien zum Kopieren
        └── etc/
            └── myconfig.conf
```

### Neue Stage anlegen

```bash
mkdir -p stages/stage-myfeature
```

### APT-Pakete definieren

`stages/stage-myfeature/00-packages`:
```
vim
htop
tmux
git
```

### Setup-Script

`stages/stage-myfeature/01-run.sh`:
```bash
#!/bin/bash -e
# Stage: My Feature

log "Installing my feature..."

# Installiere aus 00-packages
on_chroot << EOF
apt-get update
apt-get install -y $(cat ${STAGE_DIR}/00-packages)
EOF

log "My feature installed"
```

### Chroot-Script

`stages/stage-myfeature/02-run-chroot.sh`:
```bash
#!/bin/bash -e
# Wird im Chroot ausgeführt (als Root im Image)

# Beispiel: Service konfigurieren
systemctl enable myservice

# User erstellen
useradd -m -s /bin/bash myuser

# Konfiguration anpassen
echo "my_setting=value" >> /etc/myconfig.conf
```

### Dateien kopieren

Legen Sie Dateien in `files/` ab mit der Ziel-Struktur:

```
stages/stage-myfeature/files/
├── etc/
│   └── myconfig.conf
├── home/
│   └── mm/
│       └── .bashrc
└── usr/
    └── local/
        └── bin/
            └── myscript.sh
```

Diese werden automatisch ins Image kopiert.

### Stage in Build integrieren

In `config/build-config`:

```bash
# Custom Stages aktivieren
SKIP_STAGE5=0

# Stage-Liste erweitern
CUSTOM_STAGES="stage-myfeature"
```

Oder mehrere:
```bash
CUSTOM_STAGES="stage-myfeature stage-another"
```

## Beispiele

### Beispiel 1: Extra Pakete installieren

`stages/stage-extras/00-packages`:
```
vim
git
htop
tmux
curl
wget
```

`stages/stage-extras/01-run.sh`:
```bash
#!/bin/bash -e

log "Installing extra packages..."

on_chroot << EOF
apt-get update
apt-get install -y $(cat ${STAGE_DIR}/00-packages)
apt-get clean
EOF

log "Extra packages installed"
```

### Beispiel 2: Custom Service

`stages/stage-myservice/01-run.sh`:
```bash
#!/bin/bash -e

log "Installing my service..."

# Kopiere Service-Datei
install -m 644 ${STAGE_DIR}/files/etc/systemd/system/myservice.service \
    ${ROOTFS_DIR}/etc/systemd/system/

# Kopiere Binary
install -m 755 ${STAGE_DIR}/files/usr/local/bin/myservice \
    ${ROOTFS_DIR}/usr/local/bin/

# Aktiviere Service
on_chroot << EOF
systemctl enable myservice
EOF

log "My service installed"
```

### Beispiel 3: User-Konfiguration

`stages/stage-userconfig/01-run-chroot.sh`:
```bash
#!/bin/bash -e

# Erstelle zusätzlichen User
if ! id "developer" &>/dev/null; then
    useradd -m -s /bin/bash -G sudo developer
    echo "developer:dev123" | chpasswd
fi

# Konfiguriere bashrc
cat >> /home/mm/.bashrc << 'EOF'
# Custom aliases
alias ll='ls -lah'
alias update='sudo apt-get update && sudo apt-get upgrade'
EOF

chown mm:mm /home/mm/.bashrc
```

### Beispiel 4: Pre-Download von Dateien

`stages/stage-predownload/01-run.sh`:
```bash
#!/bin/bash -e

log "Pre-downloading files..."

# Download im Build-Host (nicht im Image)
wget -O ${STAGE_DIR}/files/opt/myapp.tar.gz \
    https://example.com/myapp.tar.gz

# Kopiere ins Image
install -m 644 ${STAGE_DIR}/files/opt/myapp.tar.gz \
    ${ROOTFS_DIR}/opt/

# Entpacke im Image
on_chroot << EOF
cd /opt
tar xzf myapp.tar.gz
rm myapp.tar.gz
EOF

log "Files pre-downloaded"
```

## Erweiterte Anpassungen

### Kernel-Konfiguration

```bash
# In build-config
KERNEL_BRANCH="rpi-6.1.y"  # Spezifische Version
```

### Boot-Konfiguration

Erstellen Sie `stages/stage-boot/files/boot/config.txt`:

```ini
# GPU Memory
gpu_mem=128

# Disable Bluetooth
dtoverlay=disable-bt

# Enable Camera
start_x=1

# Overclock (Pi 4)
over_voltage=2
arm_freq=1750
```

### Splash-Screen

`stages/stage-splash/01-run.sh`:
```bash
#!/bin/bash -e

# Kopiere Splash-Image
install -m 644 ${STAGE_DIR}/files/boot/splash.png \
    ${ROOTFS_DIR}/boot/

# Konfiguriere
on_chroot << EOF
# Plymouth Splash installieren
apt-get install -y plymouth plymouth-themes

# Custom Theme
plymouth-set-default-theme -R mylogo
EOF
```

### Auto-Login konfigurieren

`stages/stage-autologin/01-run-chroot.sh`:
```bash
#!/bin/bash -e

# Auto-Login für User 'mm'
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin mm --noclear %I \$TERM
EOF
```

## Debugging

### Logs während Build

```bash
# In Stage-Script
log "Debug info: $VARIABLE"
```

Logs finden Sie in:
```
pi-gen/work/<stage>/build.log
```

### Interactive Debugging

Fügen Sie in einem Stage-Script ein:

```bash
# Pausiert Build für Inspektion
echo "Paused. Press Enter to continue..."
read
```

### Chroot für Tests

```bash
# Nach fehlgeschlagenem Build
cd pi-gen/work/stage-X/rootfs
sudo chroot . /bin/bash

# Jetzt können Sie im Image-Dateisystem arbeiten
```

## Best Practices

1. **Kleine Stages**: Jede Stage sollte eine klare Aufgabe haben
2. **Idempotenz**: Scripts sollten mehrfach ausführbar sein
3. **Fehlerbehandlung**: `set -e` in allen Scripts
4. **Logging**: Nutzen Sie `log` für Ausgaben
5. **Cleanup**: Entfernen Sie temporäre Dateien
6. **Testing**: Testen Sie jede Änderung einzeln

## Referenz

### Verfügbare Variablen in Stage-Scripts

```bash
${STAGE_DIR}       # Aktuelles Stage-Verzeichnis
${ROOTFS_DIR}      # Root-Dateisystem des Images
${IMG_NAME}        # Image-Name
${RELEASE}         # Debian Release
${ARCH}            # Architektur
```

### Hilfs-Funktionen

```bash
log "message"                          # Logging
on_chroot << EOF ... EOF               # Im Chroot ausführen
install -m 644 src dest                # Datei kopieren mit Rechten
```

## Troubleshooting

### Stage wird nicht ausgeführt

- Prüfen Sie `SKIP_STAGE5` in build-config
- Prüfen Sie `CUSTOM_STAGES` Liste
- Stage-Name muss mit `stage-` beginnen

### Pakete nicht gefunden

```bash
# In Stage-Script apt-update hinzufügen
on_chroot << EOF
apt-get update
apt-get install -y mypackage
EOF
```

### Berechtigungsfehler

```bash
# Rechte korrekt setzen
install -m 755 script.sh ${ROOTFS_DIR}/usr/local/bin/
chown mm:mm ${ROOTFS_DIR}/home/mm/.bashrc
```

## Weitere Ressourcen

- [pi-gen Examples](https://github.com/RPi-Distro/pi-gen/tree/master/stage2)
- [Debian Policy](https://www.debian.org/doc/debian-policy/)
- [systemd Documentation](https://www.freedesktop.org/software/systemd/man/)
