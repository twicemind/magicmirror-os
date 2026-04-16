#!/bin/bash
#
# Setup Build Environment für MagicMirror OS
# Installiert alle benötigten Pakete und Tools
#

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo ""
echo "=========================================="
echo "  Build Environment Setup"
echo "=========================================="
echo ""

# Prüfe Root
if [ "$EUID" -ne 0 ]; then
    log_error "Dieses Script muss als root ausgeführt werden (sudo)"
    exit 1
fi

# Prüfe OS
if [[ ! -f /etc/debian_version ]]; then
    log_error "Dieses Script unterstützt nur Debian/Ubuntu"
    log_info "Für andere Systeme verwenden Sie Docker: ./build-docker.sh"
    exit 1
fi

log_info "Installiere Build-Dependencies..."

# Update Package Liste
log_info "Aktualisiere Package-Liste..."
apt-get update

# Installiere benötigte Pakete
log_info "Installiere Pakete (das kann einige Minuten dauern)..."

apt-get install -y \
    git \
    quilt \
    parted \
    qemu-user-static \
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
    qemu-user-binfmt \
    arch-test

log_success "Alle Pakete installiert"

# Prüfe QEMU
log_info "Konfiguriere QEMU..."

# Registriere ARM binaries mit binfmt
if [ -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
    log_success "QEMU ARM64 bereits registriert"
else
    log_info "Registriere QEMU ARM64..."
    update-binfmts --enable qemu-aarch64 || true
fi

# Test QEMU
if qemu-aarch64-static --version &> /dev/null; then
    log_success "QEMU funktioniert"
else
    log_error "QEMU nicht funktionsfähig"
    exit 1
fi

# Empfehlungen
echo ""
log_success "=========================================="
log_success "  Setup abgeschlossen!"
log_success "=========================================="
echo ""
log_info "Nächste Schritte:"
echo "  1. Build starten:     ./build.sh"
echo "  2. Mit Cleanup:       ./build.sh --clean"
echo "  3. Docker-Build:      ./build-docker.sh"
echo ""
log_info "Empfehlungen:"
echo "  - Mindestens 15 GB freier Speicher"
echo "  - SSD für schnellere Builds"
echo "  - 4+ CPU Cores empfohlen"
echo ""
log_info "Dokumentation:"
echo "  - Build-Guide:  docs/BUILDING.md"
echo "  - Architektur:  docs/ARCHITECTURE.md"
echo ""
