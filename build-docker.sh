#!/bin/bash
#
# Docker-basierter Build für MagicMirror OS
# Funktioniert auf allen Plattformen (macOS, Windows, Linux)
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

# Konfiguration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_IMAGE="magicmirror-os-builder"
DOCKER_TAG="latest"

# Optionen
CLEAN_BUILD=0
CUSTOM_CONFIG=""

# Parse Argumente
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
            cat << EOF
MagicMirror OS Docker Build

Verwendung: $0 [Optionen]

Optionen:
    --clean          Cleanup vor Build
    --config FILE    Alternative Konfiguration
    -h, --help       Diese Hilfe

EOF
            exit 0
            ;;
        *)
            log_error "Unbekannte Option: $1"
            exit 1
            ;;
    esac
done

# Banner
echo ""
echo "=========================================="
echo "  MagicMirror OS - Docker Build"
echo "=========================================="
echo ""

# Prüfe Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker ist nicht installiert"
    log_info "Installieren Sie Docker:"
    log_info "  - macOS:   Docker Desktop"
    log_info "  - Windows: Docker Desktop oder WSL2"
    log_info "  - Linux:   docker.io oder docker-ce"
    exit 1
fi

log_success "Docker gefunden: $(docker --version)"

# Baue Docker-Image
log_info "Baue Docker Build-Image..."

cat > "${SCRIPT_DIR}/Dockerfile.builder" << 'DOCKERFILE'
FROM debian:bookworm-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
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
    arch-test \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Setup QEMU
RUN update-binfmts --enable || true

# Create work directory
WORKDIR /build

# Default command
CMD ["/bin/bash"]
DOCKERFILE

docker build -t "${DOCKER_IMAGE}:${DOCKER_TAG}" -f "${SCRIPT_DIR}/Dockerfile.builder" "${SCRIPT_DIR}"

log_success "Docker-Image gebaut"

# Cleanup wenn gewünscht
if [ $CLEAN_BUILD -eq 1 ]; then
    log_info "Cleanup..."
    rm -rf "${SCRIPT_DIR}/work"
    rm -rf "${SCRIPT_DIR}/deploy"
    rm -rf "${SCRIPT_DIR}/pi-gen/work"
fi

# Starte Build im Container
log_info "Starte Build im Docker-Container..."
log_info "Dies kann 30-60 Minuten dauern..."
echo ""

# Build-Befehl
BUILD_CMD="cd /build && ./build.sh"
if [ -n "$CUSTOM_CONFIG" ]; then
    BUILD_CMD="$BUILD_CMD --config $CUSTOM_CONFIG"
fi

# Führe Build aus
docker run --rm \
    --privileged \
    -v "${SCRIPT_DIR}:/build" \
    -e CLEANUP=1 \
    "${DOCKER_IMAGE}:${DOCKER_TAG}" \
    bash -c "$BUILD_CMD"

if [ $? -eq 0 ]; then
    log_success "Docker-Build erfolgreich!"
    echo ""
    log_info "Fertige Images in: deploy/"
    ls -lh "${SCRIPT_DIR}/deploy/"
else
    log_error "Docker-Build fehlgeschlagen"
    exit 1
fi

# Cleanup Dockerfile
rm -f "${SCRIPT_DIR}/Dockerfile.builder"

echo ""
log_success "Build abgeschlossen!"
echo ""
