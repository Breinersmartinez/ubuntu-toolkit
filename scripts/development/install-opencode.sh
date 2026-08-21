#!/usr/bin/env bash

# ============================================================
# OpenCode Installer for Ubuntu
# ============================================================
# Instala y verifica OpenCode usando el instalador oficial.
#
# Características:
# - Compatible con Ubuntu 24.04+
# - No requiere sudo para instalar OpenCode
# - Instalación en ~/.local/bin
# - No elimina configuraciones personales
# - Verifica dependencias
# - Verifica PATH
# - Detecta instalaciones existentes
# - Puede actualizar una instalación existente
# ============================================================

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly OPENCODE_INSTALL_URL="https://opencode.ai/install"
readonly INSTALL_DIR="${XDG_BIN_DIR:-$HOME/.local/bin}"

# ------------------------------------------------------------
# Colores
# ------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ------------------------------------------------------------
# Funciones
# ------------------------------------------------------------

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_step() {
    echo
    echo -e "${CYAN}==> $1${NC}"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------
# Manejo de errores
# ------------------------------------------------------------

error_handler() {
    local exit_code=$?
    local line_number=$1

    log_error "El script falló en la línea ${line_number}."
    log_error "Código de salida: ${exit_code}"

    exit "$exit_code"
}

trap 'error_handler $LINENO' ERR

# ------------------------------------------------------------
# Banner
# ------------------------------------------------------------

show_banner() {
    clear

    echo
    echo "============================================================"
    echo "              OPENCODE INSTALLER - UBUNTU"
    echo "============================================================"
    echo
    echo "  Agente de IA para desarrollo de software"
    echo
    echo "  Instalación:"
    echo "    ${INSTALL_DIR}"
    echo
    echo "============================================================"
    echo
}

# ------------------------------------------------------------
# Verificar sistema operativo
# ------------------------------------------------------------

check_os() {
    log_step "Verificando sistema operativo"

    if [[ ! -f /etc/os-release ]]; then
        log_error "No se pudo determinar el sistema operativo."
        exit 1
    fi

    # shellcheck disable=SC1091
    source /etc/os-release

    if [[ "${ID:-}" != "ubuntu" ]]; then
        log_warning "Este script fue diseñado para Ubuntu."
        log_warning "Sistema detectado: ${PRETTY_NAME:-desconocido}"

        read -rp "¿Deseas continuar? [y/N]: " response

        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Instalación cancelada."
            exit 0
        fi
    else
        log_success "Ubuntu detectado: ${PRETTY_NAME}"
    fi
}

# ------------------------------------------------------------
# Verificar arquitectura
# ------------------------------------------------------------

check_architecture() {
    log_step "Verificando arquitectura"

    local architecture
    architecture="$(uname -m)"

    case "$architecture" in
        x86_64)
            log_success "Arquitectura compatible: x86_64"
            ;;

        aarch64|arm64)
            log_success "Arquitectura ARM64 detectada."
            ;;

        *)
            log_warning "Arquitectura detectada: $architecture"
            log_warning "Verifica la compatibilidad antes de continuar."
            ;;
    esac
}

# ------------------------------------------------------------
# Dependencias
# ------------------------------------------------------------

check_dependencies() {
    log_step "Verificando dependencias"

    local dependencies=(
        "curl"
        "bash"
    )

    local missing=()

    for dependency in "${dependencies[@]}"; do
        if command_exists "$dependency"; then
            log_success "$dependency encontrado."
        else
            missing+=("$dependency")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warning "Faltan dependencias: ${missing[*]}"

        if command_exists apt; then
            log_info "Instalando dependencias necesarias..."

            sudo apt update
            sudo apt install -y "${missing[@]}"
        else
            log_error "No se encontró apt."
            exit 1
        fi
    fi
}

# ------------------------------------------------------------
# Preparar directorio
# ------------------------------------------------------------

prepare_install_directory() {
    log_step "Preparando directorio de instalación"

    if [[ ! -d "$INSTALL_DIR" ]]; then
        mkdir -p "$INSTALL_DIR"
        log_success "Directorio creado: $INSTALL_DIR"
    else
        log_success "Directorio existente: $INSTALL_DIR"
    fi
}

# ------------------------------------------------------------
# Verificar PATH
# ------------------------------------------------------------

configure_path() {
    log_step "Verificando PATH"

    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        log_success "$INSTALL_DIR ya está en PATH."
        return
    fi

    log_warning "$INSTALL_DIR no está actualmente en PATH."

    local shell_name
    shell_name="$(basename "${SHELL:-bash}")"

    local shell_config=""

    case "$shell_name" in
        bash)
            shell_config="$HOME/.bashrc"
            ;;

        zsh)
            shell_config="$HOME/.zshrc"
            ;;

        *)
            shell_config="$HOME/.profile"
            ;;
    esac

    local path_line
    path_line='export PATH="$HOME/.local/bin:$PATH"'

    if [[ -f "$shell_config" ]] &&
       grep -Fqx "$path_line" "$shell_config"; then

        log_success "PATH ya está configurado en $shell_config."
        return
    fi

    {
        echo
        echo "# OpenCode"
        echo "$path_line"
    } >> "$shell_config"

    export PATH="$INSTALL_DIR:$PATH"

    log_success "PATH actualizado en $shell_config."
}

# ------------------------------------------------------------
# Detectar OpenCode existente
# ------------------------------------------------------------

detect_existing_installation() {
    log_step "Buscando instalación existente"

    if command_exists opencode; then
        local current_version

        current_version="$(opencode --version 2>/dev/null || true)"

        log_success "OpenCode ya está instalado."
        echo
        echo "  Versión actual: ${current_version:-desconocida}"
        echo "  Ubicación:      $(command -v opencode)"
        echo

        return 0
    fi

    log_info "No se encontró una instalación activa de OpenCode."
}

# ------------------------------------------------------------
# Instalar OpenCode
# ------------------------------------------------------------

install_opencode() {
    log_step "Instalando OpenCode"

    log_info "Usando instalador oficial:"
    echo "  $OPENCODE_INSTALL_URL"
    echo

    log_info "Directorio:"
    echo "  $INSTALL_DIR"
    echo

    export XDG_BIN_DIR="$INSTALL_DIR"

    curl -fsSL "$OPENCODE_INSTALL_URL" | bash

    log_success "Instalación de OpenCode completada."
}

# ------------------------------------------------------------
# Actualizar PATH actual
# ------------------------------------------------------------

refresh_path() {
    if [[ -d "$INSTALL_DIR" ]]; then
        export PATH="$INSTALL_DIR:$PATH"
    fi

    # Posibles ubicaciones oficiales/fallback
    if [[ -d "$HOME/.opencode/bin" ]]; then
        export PATH="$HOME/.opencode/bin:$PATH"
    fi

    if [[ -d "$HOME/bin" ]]; then
        export PATH="$HOME/bin:$PATH"
    fi
}

# ------------------------------------------------------------
# Verificación
# ------------------------------------------------------------

verify_installation() {
    log_step "Verificando instalación"

    refresh_path

    if ! command_exists opencode; then
        log_error "OpenCode no está disponible en PATH."
        echo
        log_info "Prueba abrir una nueva terminal."
        log_info "También puedes ejecutar:"
        echo
        echo "  source ~/.bashrc"
        echo
        exit 1
    fi

    local version
    version="$(opencode --version 2>/dev/null || true)"

    if [[ -z "$version" ]]; then
        log_warning "OpenCode está instalado pero no devolvió una versión."
    else
        log_success "OpenCode instalado correctamente."
        echo
        echo "  Versión:  $version"
        echo "  Binario:  $(command -v opencode)"
    fi
}

# ------------------------------------------------------------
# Mostrar configuración
# ------------------------------------------------------------

show_configuration_info() {
    log_step "Configuración"

    echo
    echo "OpenCode utiliza su propia configuración."
    echo
    echo "Importante:"
    echo
    echo "  Este instalador NO configura ninguna API key."
    echo "  Tampoco sobrescribe credenciales existentes."
    echo
    echo "Esto permite configurar posteriormente el proveedor"
    echo "y modelo que prefieras."
    echo
}

# ------------------------------------------------------------
# Mostrar próximos pasos
# ------------------------------------------------------------

show_next_steps() {
    echo
    echo "============================================================"
    echo "                  INSTALACIÓN COMPLETADA"
    echo "============================================================"
    echo
    echo "OpenCode está disponible mediante:"
    echo
    echo "  opencode"
    echo
    echo "Para trabajar sobre un proyecto:"
    echo
    echo "  cd ~/ruta/de/tu/proyecto"
    echo "  opencode"
    echo
    echo "También puedes comprobar la instalación:"
    echo
    echo "  opencode --version"
    echo
    echo "Si el comando no aparece inmediatamente:"
    echo
    echo "  source ~/.bashrc"
    echo
    echo "o abre una nueva terminal."
    echo
    echo "============================================================"
    echo
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

main() {
    show_banner

    check_os
    check_architecture
    check_dependencies
    prepare_install_directory
    configure_path
    detect_existing_installation
    install_opencode
    refresh_path
    verify_installation
    show_configuration_info
    show_next_steps
}

main "$@"
