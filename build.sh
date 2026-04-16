#!/bin/bash
#
# MagicMirror OS - Build Script
# Baut ein Custom Raspberry Pi OS Image mit pi-gen
#

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Konfiguration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_GEN_DIR="${SCRIPT_DIR}/pi-gen"
PI_GEN_REPO="https://github.com/RPi-Distro/pi-gen.git"
CONFIG_FILE="${SCRIPT_DIR}/config/build-config"
WORK_DIR="${SCRIPT_DIR}/work"
DEPLOY_DIR="${SCRIPT_DIR}/deploy"

# Optionen
CLEAN_BUILD=0
CUSTOM_CONFIG=""

# Parse Argumente
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                CLEAN_BUILD=1
                shift
                ;;
            --config)
                CUSTOM_CONFIG="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unbekannte Option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Hilfe anzeigen
show_help() {
    cat << EOF
MagicMirror OS Build Script

Verwendung: $0 [Optionen]

Optionen:
    --clean          Cleanup vor Build (löscht work/ und deploy/)
    --config FILE    Verwende alternative Konfigurationsdatei
    -h, --help       Zeige diese Hilfe

Beispiele:
    $0                              # Standard-Build
    $0 --clean                      # Build nach Cleanup
    $0 --config config/my.conf      # Mit eigener Konfiguration

EOF
}

# Banner
print_banner() {
    echo ""
    echo "=========================================="
    echo "  MagicMirror OS - Image Builder"
    echo "=========================================="
    echo ""
}

# Prüfe Voraussetzungen
check_prerequisites() {
    log_info "Prüfe Voraussetzungen..."
    
    # Prüfe OS
    if [[ ! -f /etc/debian_version ]]; then
        log_error "Dieses Script benötigt Debian/Ubuntu"
        log_info "Für andere Systeme verwenden Sie: ./build-docker.sh"
        exit 1
    fi
    
    # Prüfe benötigte Tools
    local required_tools=(
        "git"
        "debootstrap"
        "qemu-user-static"
        "parted"
        "kpartx"
    )
    
    local missing_tools=()
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null && ! dpkg -l | grep -q "^ii  $tool"; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Fehlende Tools: ${missing_tools[*]}"
        log_info "Installieren Sie diese mit: sudo apt-get install ${missing_tools[*]}"
        log_info "Oder verwenden Sie: ./scripts/setup-build-env.sh"
        exit 1
    fi
    
    # Prüfe Speicherplatz
    local available_space=$(df -BG "$SCRIPT_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_space" -lt 10 ]; then
        log_warning "Weniger als 10 GB freier Speicher verfügbar"
        log_warning "Build benötigt mindestens 15 GB"
        read -p "Trotzdem fortfahren? (j/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Jj]$ ]]; then
            exit 1
        fi
    fi
    
    log_success "Voraussetzungen erfüllt"
}

# pi-gen Repository klonen oder aktualisieren
setup_pigen() {
    log_info "Setup pi-gen..."
    
    if [ -d "$PI_GEN_DIR" ]; then
        log_info "pi-gen bereits vorhanden, aktualisiere..."
        cd "$PI_GEN_DIR"
        git fetch
        git reset --hard origin/master
        cd "$SCRIPT_DIR"
    else
        log_info "Klone pi-gen Repository..."
        git clone "$PI_GEN_REPO" "$PI_GEN_DIR"
    fi
    
    log_success "pi-gen bereit"
}

# Cleanup
cleanup() {
    log_info "Cleanup..."
    
    if [ -d "$WORK_DIR" ]; then
        log_info "Lösche work directory..."
        sudo rm -rf "$WORK_DIR"
    fi
    
    if [ -d "$DEPLOY_DIR" ]; then
        log_info "Lösche deploy directory..."
        sudo rm -rf "$DEPLOY_DIR"
    fi
    
    # Cleanup in pi-gen
    if [ -d "$PI_GEN_DIR/work" ]; then
        cd "$PI_GEN_DIR"
        sudo rm -rf work
        cd "$SCRIPT_DIR"
    fi
    
    log_success "Cleanup abgeschlossen"
}

# Konfiguration laden
load_config() {
    log_info "Lade Build-Konfiguration..."
    
    if [ -n "$CUSTOM_CONFIG" ]; then
        if [ ! -f "$CUSTOM_CONFIG" ]; then
            log_error "Konfigurationsdatei nicht gefunden: $CUSTOM_CONFIG"
            exit 1
        fi
        CONFIG_FILE="$CUSTOM_CONFIG"
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Keine Konfiguration gefunden: $CONFIG_FILE"
        log_info "Erstelle Standard-Konfiguration..."
        create_default_config
    fi
    
    # Export Variablen für pi-gen
    export CONFIG_FILE
    
    log_success "Konfiguration geladen: $CONFIG_FILE"
}

# Standard-Konfiguration erstellen
create_default_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    cat > "$CONFIG_FILE" << 'EOF'
# MagicMirror OS Build Configuration

# Image-Name
IMG_NAME="magicmirror-os"

# Release (bookworm=Debian 12, bullseye=Debian 11)
RELEASE="bookworm"

# Architektur (arm64 für 64-Bit)
ARCH="arm64"

# Target-Hostname
TARGET_HOSTNAME="magicmirror"

# Locale
LOCALE_DEFAULT="de_DE.UTF-8"
KEYBOARD_KEYMAP="de"
KEYBOARD_LAYOUT="German"
TIMEZONE_DEFAULT="Europe/Berlin"

# Deployment
DEPLOY_ZIP=1
DEPLOY_COMPRESSION="xz"

# Welche Stages bauen
# Stage 0-2: Basis Raspberry Pi OS Lite
# Stage 3: Desktop (überspringen)
# Stage 4: Zusätzliche Software (überspringen)
# Stage 5: Unsere Custom-Stages
SKIP_STAGE3=1
SKIP_STAGE4=1
SKIP_STAGE5=1

# Performance
PARALLEL_BUILD=1

# Image-Größe (in MB, oder "auto")
IMAGE_SIZE=""

# Erste Boot-Konfiguration
FIRST_USER_NAME="mm"
FIRST_USER_PASS="magicmirror"

# SSH default aktivieren
ENABLE_SSH=1

# Disable predictable network interface names
DISABLE_PREDICTABLE_NETWORK_NAMES=1
EOF
    
    log_success "Standard-Konfiguration erstellt"
}

# Kopiere Custom Stages
prepare_custom_stages() {
    log_info "Bereite Custom Stages vor..."
    
    # Erstelle Stage-Verzeichnisse in pi-gen
    local stages_dir="${PI_GEN_DIR}/stage-custom"
    
    if [ -d "$stages_dir" ]; then
        sudo rm -rf "$stages_dir"
    fi
    
    # Aktuell nur Platzhalter, da wir zunächst ohne Änderungen bauen
    log_info "Custom Stages werden in Phase 2 hinzugefügt"
    
    log_success "Custom Stages vorbereitet"
}

# Build starten
run_build() {
    log_info "Starte Image-Build..."
    log_info "Dies kann 30-60 Minuten dauern..."
    echo ""
    
    cd "$PI_GEN_DIR"
    
    # Verwende unsere Konfiguration
    cp "$CONFIG_FILE" config
    
    # Build starten
    log_info "Führe pi-gen Build aus..."
    
    if sudo ./build.sh; then
        log_success "Build erfolgreich abgeschlossen"
        return 0
    else
        log_error "Build fehlgeschlagen"
        log_info "Prüfen Sie die Logs in: ${PI_GEN_DIR}/work/*/build.log"
        return 1
    fi
}

# Kopiere Output
copy_output() {
    log_info "Kopiere fertige Images..."
    
    mkdir -p "$DEPLOY_DIR"
    
    if [ -d "${PI_GEN_DIR}/deploy" ]; then
        cp -v "${PI_GEN_DIR}/deploy/"* "$DEPLOY_DIR/"
        log_success "Images nach ${DEPLOY_DIR}/ kopiert"
        
        # Zeige Ergebnis
        echo ""
        log_success "Fertige Images:"
        ls -lh "$DEPLOY_DIR/"
    else
        log_warning "Kein deploy-Verzeichnis gefunden"
    fi
}

# Zeige Zusammenfassung
show_summary() {
    echo ""
    log_success "=========================================="
    log_success "  Build abgeschlossen!"
    log_success "=========================================="
    echo ""
    log_info "Fertige Images:"
    if [ -d "$DEPLOY_DIR" ]; then
        ls -lh "$DEPLOY_DIR/"
    fi
    echo ""
    log_info "Image verwenden:"
    echo "  1. Image auf SD-Karte schreiben:"
    echo "     sudo dd if=${DEPLOY_DIR}/*.img of=/dev/sdX bs=4M status=progress"
    echo ""
    echo "  2. Oder mit Raspberry Pi Imager:"
    echo "     - Wählen Sie 'Custom Image'"
    echo "     - Wählen Sie das .img/.img.xz File"
    echo ""
    log_info "Nächste Schritte:"
    echo "  - Image testen: ./scripts/test-image.sh"
    echo "  - Dokumentation: docs/BUILDING.md"
    echo ""
}

# Hauptprogramm
main() {
    print_banner
    
    parse_arguments "$@"
    
    # Cleanup wenn gewünscht
    if [ $CLEAN_BUILD -eq 1 ]; then
        cleanup
    fi
    
    check_prerequisites
    setup_pigen
    load_config
    prepare_custom_stages
    
    # Build ausführen
    if run_build; then
        copy_output
        show_summary
        exit 0
    else
        log_error "Build fehlgeschlagen"
        log_info "Für Hilfe siehe: docs/BUILDING.md"
        exit 1
    fi
}

# Script ausführen
main "$@"
