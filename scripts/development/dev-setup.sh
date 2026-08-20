#!/usr/bin/env bash

# ============================================================
# Ubuntu Toolkit - Development Environment Setup
# Version: 0.1.0
#
# Ubuntu 24.04 LTS
#
# Instala y configura:
#
#   Git
#   GitHub CLI
#   Docker Engine
#   Docker Compose
#   Visual Studio Code (NO SNAP)
#   Node.js 24.x
#   Python 3
#   Java OpenJDK
#   Maven
#   PostgreSQL
#   pgAdmin 4
#   Postman (NO SNAP)
#   Build tools
#   curl
#   wget
#   jq
#   tree
#   htop
#   btop
#   ripgrep
#   fzf
#   make
#   hping3
#   nmap
#   Apache Benchmark
#
# Filosofía:
#   - No usar Snap para VS Code
#   - No usar Snap para Postman
#   - Usar repositorios oficiales cuando sea posible
#   - No eliminar configuraciones personales
#   - No eliminar instalaciones existentes
#   - No sobrescribir claves SSH
#   - No eliminar Docker data
#   - Idempotente: puede ejecutarse varias veces
#   - Mostrar versiones al finalizar
#
# Uso:
#
#   chmod +x dev-setup.sh
#   sudo ./dev-setup.sh
#
# ============================================================

set -Eeuo pipefail

# ------------------------------------------------------------
# Configuración
# ------------------------------------------------------------

SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="0.1.0"

REAL_USER="${SUDO_USER:-${USER:-}}"

if [[ -z "$REAL_USER" || "$REAL_USER" == "root" ]]; then
    REAL_USER="$(logname 2>/dev/null || true)"
fi

if [[ -z "$REAL_USER" ]]; then
    echo "ERROR: no se pudo determinar el usuario principal."
    exit 1
fi

USER_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

if [[ -z "$USER_HOME" || ! -d "$USER_HOME" ]]; then
    echo "ERROR: no se pudo determinar el HOME de $REAL_USER."
    exit 1
fi

ARCH="$(dpkg --print-architecture)"

# ------------------------------------------------------------
# Colores
# ------------------------------------------------------------

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    RESET='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    MAGENTA=''
    RESET=''
fi

# ------------------------------------------------------------
# Funciones
# ------------------------------------------------------------

info() {
    echo -e "${CYAN}[INFO]${RESET} $*"
}

success() {
    echo -e "${GREEN}[OK]${RESET} $*"
}

warning() {
    echo -e "${YELLOW}[WARN]${RESET} $*"
}

error() {
    echo -e "${RED}[ERROR]${RESET} $*" >&2
}

separator() {
    echo
    echo "============================================================"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_apt_packages() {

    local packages=("$@")

    apt-get install -y "${packages[@]}"
}

# ------------------------------------------------------------
# Manejo de errores
# ------------------------------------------------------------

on_error() {

    local exit_code=$?
    local line_number="$1"

    echo
    error "El instalador encontró un error."
    error "Línea: $line_number"
    error "Código: $exit_code"

    echo
    error "Revisa el estado de APT antes de volver a ejecutar."

    exit "$exit_code"
}

trap 'on_error $LINENO' ERR

# ------------------------------------------------------------
# Root
# ------------------------------------------------------------

if [[ "$EUID" -ne 0 ]]; then

    error "Este script requiere privilegios de administrador."

    echo
    echo "Ejecuta:"
    echo
    echo "    sudo $SCRIPT_NAME"

    exit 1
fi

# ------------------------------------------------------------
# Validar Ubuntu
# ------------------------------------------------------------

if [[ ! -f /etc/os-release ]]; then
    error "No se encontró /etc/os-release."
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

if [[ "${ID:-}" != "ubuntu" ]]; then

    error "Este script está diseñado para Ubuntu."

    echo
    echo "Sistema detectado:"
    echo "${PRETTY_NAME:-desconocido}"

    exit 1
fi

if [[ "${VERSION_ID:-}" != "24.04" ]]; then

    warning "Este script fue diseñado para Ubuntu 24.04 LTS."

    echo
    echo "Versión detectada:"
    echo "${VERSION_ID:-desconocida}"

    echo

    read -rp "¿Deseas continuar? [y/N]: " answer

    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# ------------------------------------------------------------
# Información inicial
# ------------------------------------------------------------

clear

separator
echo "             UBUNTU TOOLKIT"
echo "             DEVELOPMENT SETUP"
separator

echo
echo "Versión:     $SCRIPT_VERSION"
echo "Usuario:     $REAL_USER"
echo "Home:        $USER_HOME"
echo "Arquitectura: $ARCH"
echo "Sistema:     ${PRETTY_NAME:-Ubuntu}"
echo

echo "Este instalador NO utilizará Snap para:"
echo
echo "  - Visual Studio Code"
echo "  - Postman"
echo

# ------------------------------------------------------------
# Confirmación
# ------------------------------------------------------------

echo
warning "Se instalarán múltiples herramientas de desarrollo."

echo
echo "Componentes principales:"
echo
echo "  Git"
echo "  GitHub CLI"
echo "  Docker + Compose"
echo "  VS Code"
echo "  Node.js 24"
echo "  Python"
echo "  Java + Maven"
echo "  PostgreSQL + pgAdmin"
echo "  Postman"
echo "  Build tools"
echo "  Network tools"
echo "  CLI utilities"

echo

read -rp "¿Deseas continuar? [y/N]: " answer

if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo
    info "Instalación cancelada."
    exit 0
fi

# ------------------------------------------------------------
# 1. Preparar APT
# ------------------------------------------------------------

separator
echo "[1/12] PREPARANDO APT"
separator

info "Actualizando índices..."

apt-get update

info "Instalando dependencias básicas..."

install_apt_packages \
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https

success "APT preparado."

# ------------------------------------------------------------
# 2. Herramientas base
# ------------------------------------------------------------

separator
echo "[2/12] HERRAMIENTAS BASE"
separator

install_apt_packages \
    git \
    jq \
    tree \
    htop \
    btop \
    ripgrep \
    fzf \
    make \
    build-essential \
    gcc \
    g++ \
    pkg-config \
    unzip \
    zip \
    tar \
    gzip \
    xz-utils \
    shellcheck

success "Herramientas base instaladas."

# ------------------------------------------------------------
# 3. Git
# ------------------------------------------------------------

separator
echo "[3/12] GIT"
separator

install_apt_packages git

echo
echo "Git:"
git --version

# ------------------------------------------------------------
# 4. GitHub CLI
# ------------------------------------------------------------

separator
echo "[4/12] GITHUB CLI"
separator

GITHUB_KEYRING="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
GITHUB_REPO="/etc/apt/sources.list.d/github-cli.list"

mkdir -p -m 0755 /etc/apt/keyrings
mkdir -p -m 0755 /etc/apt/sources.list.d

curl -fsSL \
    https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    -o "$GITHUB_KEYRING"

chmod 0644 "$GITHUB_KEYRING"

cat > "$GITHUB_REPO" <<EOF
deb [arch=$ARCH signed-by=$GITHUB_KEYRING] https://cli.github.com/packages stable main
EOF

apt-get update

install_apt_packages gh

success "GitHub CLI instalado."

echo
gh --version | head -n 1

# ------------------------------------------------------------
# 5. Docker Engine + Compose
# ------------------------------------------------------------

separator
echo "[5/12] DOCKER + DOCKER COMPOSE"
separator

DOCKER_KEYRING="/etc/apt/keyrings/docker.asc"
DOCKER_REPO="/etc/apt/sources.list.d/docker.sources"

mkdir -p -m 0755 /etc/apt/keyrings

curl -fsSL \
    https://download.docker.com/linux/ubuntu/gpg \
    -o "$DOCKER_KEYRING"

chmod a+r "$DOCKER_KEYRING"

cat > "$DOCKER_REPO" <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Architectures: $ARCH
Signed-By: $DOCKER_KEYRING
EOF

apt-get update

# No eliminamos docker.io ni instalaciones existentes.
# Si existe una versión de Docker del repositorio Ubuntu,
# apt resolverá la instalación según los paquetes disponibles.

install_apt_packages \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

systemctl enable docker
systemctl start docker

# ------------------------------------------------------------
# Agregar usuario al grupo Docker
# ------------------------------------------------------------

if getent group docker >/dev/null 2>&1; then

    usermod -aG docker "$REAL_USER"

else

    groupadd docker
    usermod -aG docker "$REAL_USER"

fi

success "Docker instalado."

echo
docker --version

echo
echo "Docker Compose:"
docker compose version

echo
warning "El usuario $REAL_USER fue agregado al grupo docker."

echo
echo "Para que el cambio de grupo tenga efecto:"
echo
echo "    cerrar sesión y volver a entrar"
echo
echo "o ejecutar:"
echo
echo "    newgrp docker"

# ------------------------------------------------------------
# 6. Node.js 24
# ------------------------------------------------------------

separator
echo "[6/12] NODE.JS 24"
separator

NODESOURCE_KEYRING="/usr/share/keyrings/nodesource.gpg"
NODESOURCE_REPO="/etc/apt/sources.list.d/nodesource.sources"

curl -fsSL \
    https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key |
    gpg --dearmor --yes \
    -o "$NODESOURCE_KEYRING"

chmod 0644 "$NODESOURCE_KEYRING"

cat > "$NODESOURCE_REPO" <<EOF
Types: deb
URIs: https://deb.nodesource.com/node_24.x
Suites: nodistro
Components: main
Architectures: $ARCH
Signed-By: $NODESOURCE_KEYRING
EOF

apt-get update

install_apt_packages nodejs

success "Node.js instalado."

echo
echo "Node:"
node --version

echo
echo "npm:"
npm --version

# ------------------------------------------------------------
# 7. Python
# ------------------------------------------------------------

separator
echo "[7/12] PYTHON"
separator

install_apt_packages \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev

success "Python instalado."

echo
python3 --version

echo
pip3 --version || true

# ------------------------------------------------------------
# 8. Java + Maven
# ------------------------------------------------------------

separator
echo "[8/12] JAVA + MAVEN"
separator

install_apt_packages \
    default-jdk \
    maven

success "Java y Maven instalados."

echo
echo "Java:"
java -version 2>&1 | head -n 1

echo
echo "Maven:"
mvn --version | head -n 3

# ------------------------------------------------------------
# 9. PostgreSQL
# ------------------------------------------------------------

separator
echo "[9/12] POSTGRESQL"
separator

install_apt_packages \
    postgresql \
    postgresql-contrib \
    libpq-dev

systemctl enable postgresql
systemctl start postgresql

success "PostgreSQL instalado."

echo
echo "PostgreSQL:"
psql --version

echo
echo "Servicio:"
systemctl is-active postgresql || true

# ------------------------------------------------------------
# 10. pgAdmin 4
# ------------------------------------------------------------

separator
echo "[10/12] PGADMIN 4"
separator

PGADMIN_KEYRING="/etc/apt/keyrings/packages-pgadmin-org.gpg"
PGADMIN_REPO="/etc/apt/sources.list.d/pgadmin4.list"

mkdir -p -m 0755 /etc/apt/keyrings

curl -fsS \
    https://www.pgadmin.org/static/packages_pgadmin_org.pub |
    gpg --dearmor --yes \
    -o "$PGADMIN_KEYRING"

chmod 0644 "$PGADMIN_KEYRING"

cat > "$PGADMIN_REPO" <<EOF
deb [signed-by=$PGADMIN_KEYRING] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/${VERSION_CODENAME} pgadmin4 main
EOF

apt-get update

# Solo desktop.
# Evitamos instalar el modo web porque el usuario pidió
# una herramienta de desarrollo local.

install_apt_packages pgadmin4-desktop

success "pgAdmin 4 instalado."

# ------------------------------------------------------------
# 11. Visual Studio Code
# ------------------------------------------------------------

separator
echo "[11/12] VISUAL STUDIO CODE"
separator

# ------------------------------------------------------------
# IMPORTANTE:
# No se utiliza Snap.
#
# Usamos el paquete .deb oficial de Microsoft.
# ------------------------------------------------------------

VSCODE_TMP="$(mktemp --suffix=.deb)"

cleanup_vscode() {
    rm -f "$VSCODE_TMP"
}

trap cleanup_vscode EXIT

case "$ARCH" in

    amd64)
        VSCODE_URL="https://update.code.visualstudio.com/latest/linux-deb-x64/stable"
        ;;

    arm64)
        VSCODE_URL="https://update.code.visualstudio.com/latest/linux-deb-arm64/stable"
        ;;

    *)
        error "Arquitectura no soportada para VS Code: $ARCH"
        exit 1
        ;;

esac

info "Descargando VS Code oficial..."

curl -fL \
    "$VSCODE_URL" \
    -o "$VSCODE_TMP"

info "Instalando paquete .deb..."

apt-get install -y "$VSCODE_TMP"

success "VS Code instalado sin Snap."

echo
code --version | head -n 1

# ------------------------------------------------------------
# 12. Postman
# ------------------------------------------------------------

separator
echo "[12/12] POSTMAN"
separator

# ------------------------------------------------------------
# Postman no se instala mediante Snap.
#
# Se utiliza el paquete oficial Linux de Postman.
# ------------------------------------------------------------

POSTMAN_DIR="/opt/Postman"
POSTMAN_ARCHIVE="/tmp/postman.tar.gz"

case "$ARCH" in

    amd64)
        POSTMAN_URL="https://dl.pstmn.io/download/latest/linux_64"
        ;;

    arm64)
        POSTMAN_URL="https://dl.pstmn.io/download/latest/linux_arm64"
        ;;

    *)
        error "Arquitectura no soportada para Postman: $ARCH"
        exit 1
        ;;

esac

info "Descargando Postman..."

curl -fL \
    "$POSTMAN_URL" \
    -o "$POSTMAN_ARCHIVE"

# No eliminamos configuraciones del usuario.
# Solo reemplazamos la aplicación en /opt/Postman.

if [[ -d "$POSTMAN_DIR" ]]; then

    mv "$POSTMAN_DIR" "${POSTMAN_DIR}.backup-$(date +%Y%m%d_%H%M%S)"

fi

mkdir -p /opt

tar -xzf "$POSTMAN_ARCHIVE" -C /opt

ln -sf /opt/Postman/Postman /usr/local/bin/postman

rm -f "$POSTMAN_ARCHIVE"

# ------------------------------------------------------------
# Crear .desktop
# ------------------------------------------------------------

DESKTOP_FILE="/usr/share/applications/postman.desktop"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Postman
Comment=API development platform
Exec=/opt/Postman/Postman
Icon=/opt/Postman/app/resources/app/assets/icon.png
Terminal=false
Type=Application
Categories=Development;Network;
StartupWMClass=Postman
EOF

chmod 0644 "$DESKTOP_FILE"

success "Postman instalado sin Snap."

echo
echo "Ejecutable:"
echo
echo "    /usr/local/bin/postman"

# ------------------------------------------------------------
# Herramientas de red
# ------------------------------------------------------------

separator
echo "HERRAMIENTAS DE RED"
separator

install_apt_packages \
    hping3 \
    nmap \
    apache2-utils

success "Herramientas de red instaladas."

# ------------------------------------------------------------
# Verificación general
# ------------------------------------------------------------

separator
echo "VERIFICACIÓN DE INSTALACIÓN"
separator

declare -A TOOLS

TOOLS["Git"]="git"
TOOLS["GitHub CLI"]="gh"
TOOLS["Docker"]="docker"
TOOLS["Node.js"]="node"
TOOLS["Python"]="python3"
TOOLS["Java"]="java"
TOOLS["Maven"]="mvn"
TOOLS["PostgreSQL"]="psql"
TOOLS["VS Code"]="code"
TOOLS["Postman"]="postman"
TOOLS["curl"]="curl"
TOOLS["wget"]="wget"
TOOLS["jq"]="jq"
TOOLS["tree"]="tree"
TOOLS["htop"]="htop"
TOOLS["btop"]="btop"
TOOLS["ripgrep"]="rg"
TOOLS["fzf"]="fzf"
TOOLS["make"]="make"
TOOLS["hping3"]="hping3"
TOOLS["nmap"]="nmap"
TOOLS["Apache Benchmark"]="ab"

for name in "${!TOOLS[@]}"; do

    command="${TOOLS[$name]}"

    if command_exists "$command"; then
        success "$name"
    else
        warning "$name no encontrado"
    fi

done

# ------------------------------------------------------------
# Versiones
# ------------------------------------------------------------

separator
echo "VERSIONES"
separator

echo

echo "Git:"
git --version || true

echo
echo "GitHub CLI:"
gh --version | head -n 1 || true

echo
echo "Docker:"
docker --version || true

echo
echo "Docker Compose:"
docker compose version || true

echo
echo "Node.js:"
node --version || true

echo
echo "npm:"
npm --version || true

echo
echo "Python:"
python3 --version || true

echo
echo "Java:"
java -version 2>&1 | head -n 1 || true

echo
echo "Maven:"
mvn --version | head -n 1 || true

echo
echo "PostgreSQL:"
psql --version || true

echo
echo "VS Code:"
code --version | head -n 1 || true

echo
echo "Postman:"
if [[ -x /usr/local/bin/postman ]]; then
    echo "Instalado en /opt/Postman"
else
    echo "No encontrado"
fi

echo
echo "Nmap:"
nmap --version | head -n 1 || true

echo
echo "Apache Benchmark:"
ab -V 2>&1 | head -n 1 || true

# ------------------------------------------------------------
# Verificar Snap
# ------------------------------------------------------------

separator
echo "VERIFICACIÓN DE SNAP"
separator

echo

if command_exists snap; then

    echo "Snap está instalado en el sistema."

    echo
    echo "Verificando VS Code:"

    if snap list 2>/dev/null | grep -qi '^code[[:space:]]'; then

        warning "VS Code está instalado mediante Snap."

    else

        success "VS Code NO está instalado mediante Snap."

    fi

    echo
    echo "Verificando Postman:"

    if snap list 2>/dev/null | grep -qi '^postman[[:space:]]'; then

        warning "Postman está instalado mediante Snap."

    else

        success "Postman NO está instalado mediante Snap."

    fi

else

    success "Snap no está instalado."

fi

# ------------------------------------------------------------
# Docker post-install
# ------------------------------------------------------------

separator
echo "CONFIGURACIÓN FINAL DE DOCKER"
separator

echo
echo "Usuario:"
echo "$REAL_USER"

echo
echo "Grupo docker:"
id "$REAL_USER" | grep -o 'docker' || true

echo
echo "IMPORTANTE:"
echo
echo "El grupo docker puede requerir cerrar sesión."
echo
echo "Después de volver a iniciar sesión prueba:"
echo
echo "    docker run hello-world"
echo
echo "o:"
echo
echo "    docker ps"

# ------------------------------------------------------------
# Python
# ------------------------------------------------------------

separator
echo "RECOMENDACIÓN PYTHON"
separator

echo
echo "Para proyectos Python se recomienda utilizar entornos virtuales:"
echo
echo "    python3 -m venv .venv"
echo
echo "    source .venv/bin/activate"
echo
echo "Evita instalar dependencias de proyectos directamente"
echo "en el Python global del sistema."

# ------------------------------------------------------------
# PostgreSQL
# ------------------------------------------------------------

separator
echo "POSTGRESQL"
separator

echo
echo "Servicio:"
systemctl status postgresql --no-pager | head -n 8 || true

echo
echo "Para entrar como administrador PostgreSQL:"
echo
echo "    sudo -u postgres psql"

# ------------------------------------------------------------
# Git
# ------------------------------------------------------------

separator
echo "GIT"
separator

echo
echo "Configuración actual:"
echo

echo "Nombre:"
git config --global user.name 2>/dev/null || echo "No configurado"

echo
echo "Correo:"
git config --global user.email 2>/dev/null || echo "No configurado"

echo
echo "Puedes configurar Git con:"
echo
echo "    git config --global user.name \"Tu Nombre\""
echo "    git config --global user.email \"tu@email.com\""

# ------------------------------------------------------------
# GitHub CLI
# ------------------------------------------------------------

separator
echo "GITHUB CLI"
separator

echo
echo "Para autenticar GitHub CLI:"
echo
echo "    gh auth login"

# ------------------------------------------------------------
# Final
# ------------------------------------------------------------

separator
echo "DESARROLLO - INSTALACIÓN COMPLETADA"
separator

echo
success "Ubuntu Toolkit Development Setup finalizado."

echo
echo "Herramientas instaladas/configuradas:"
echo
echo "  ✓ Git"
echo "  ✓ GitHub CLI"
echo "  ✓ Docker"
echo "  ✓ Docker Compose"
echo "  ✓ VS Code (NO Snap)"
echo "  ✓ Node.js 24"
echo "  ✓ Python"
echo "  ✓ Java"
echo "  ✓ Maven"
echo "  ✓ PostgreSQL"
echo "  ✓ pgAdmin 4"
echo "  ✓ Postman (NO Snap)"
echo "  ✓ Build tools"
echo "  ✓ curl"
echo "  ✓ wget"
echo "  ✓ jq"
echo "  ✓ tree"
echo "  ✓ htop"
echo "  ✓ btop"
echo "  ✓ ripgrep"
echo "  ✓ fzf"
echo "  ✓ make"
echo "  ✓ hping3"
echo "  ✓ nmap"
echo "  ✓ Apache Benchmark"

echo
warning "RECOMENDACIÓN:"
echo
echo "Cierra sesión y vuelve a entrar para que el grupo"
echo "docker tenga efecto para $REAL_USER."

echo
echo "Después puedes verificar Docker con:"
echo
echo "    docker run hello-world"

echo
echo "Y GitHub CLI con:"
echo
echo "    gh auth login"

echo
echo "Postman:"
echo
echo "    postman"

echo
echo "VS Code:"
echo
echo "    code"

echo
echo "Finalizado:"
echo "$(date)"

separator
echo "UBUNTU TOOLKIT - DEVELOPMENT SETUP $SCRIPT_VERSION"
separator