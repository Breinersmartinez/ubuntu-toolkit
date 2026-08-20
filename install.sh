#!/usr/bin/env bash

# ============================================================
# Ubuntu Toolkit - Installer
# Version: 0.1.0
#
# Instala Ubuntu Toolkit en:
#
#   ~/.local/share/ubuntu-toolkit
#   ~/.local/bin/ubuntu-toolkit
#
# No requiere sudo.
#
# ============================================================

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="0.1.0"

# ------------------------------------------------------------
# Colores
# ------------------------------------------------------------

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    RESET='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    RESET=''
fi

# ------------------------------------------------------------
# Directorios
# ------------------------------------------------------------

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_DIR="$HOME/.local/share/ubuntu-toolkit"
BIN_DIR="$HOME/.local/bin"

SCRIPTS_DIR="$PROJECT_ROOT/scripts"
LIB_DIR="$PROJECT_ROOT/lib"

BACKUP_DIR="$HOME/.local/share/ubuntu-toolkit-backups"

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

on_error() {

    local exit_code=$?
    local line_number=$1

    echo
    error "La instalación falló."
    error "Línea: $line_number"
    error "Código: $exit_code"

    exit "$exit_code"
}

trap 'on_error $LINENO' ERR

# ------------------------------------------------------------
# Ayuda
# ------------------------------------------------------------

show_help() {

    cat <<EOF

Ubuntu Toolkit Installer

Versión: $SCRIPT_VERSION

Uso:

    ./install.sh
    ./install.sh --uninstall
    ./install.sh --help
    ./install.sh --version

Opciones:

    --uninstall     Desinstalar Ubuntu Toolkit.
    --help          Mostrar ayuda.
    --version       Mostrar versión.

Ubicación:

    Toolkit:
        $INSTALL_DIR

    Ejecutables:
        $BIN_DIR

EOF

}

# ------------------------------------------------------------
# Argumentos
# ------------------------------------------------------------

case "${1:-}" in

    --help|-h)
        show_help
        exit 0
        ;;

    --version|-v)
        echo "$SCRIPT_VERSION"
        exit 0
        ;;

    --uninstall)
        UNINSTALL=true
        ;;

    "")
        UNINSTALL=false
        ;;

    *)
        error "Opción desconocida: $1"
        echo
        show_help
        exit 1
        ;;

esac

# ------------------------------------------------------------
# Desinstalación
# ------------------------------------------------------------

uninstall() {

    separator
    echo "UBUNTU TOOLKIT - DESINSTALADOR"
    separator

    echo
    echo "Se eliminarán:"
    echo
    echo "    $INSTALL_DIR"
    echo "    $BIN_DIR/ubuntu-toolkit"
    echo

    warning "No se eliminarán:"
    echo
    echo "    Tus proyectos"
    echo "    Tus configuraciones"
    echo "    Tus claves SSH"
    echo "    Tus repositorios Git"
    echo "    Tus archivos personales"
    echo

    read -rp "¿Continuar? [y/N]: " answer

    if [[ ! "$answer" =~ ^[Yy]$ ]]; then

        info "Desinstalación cancelada."

        exit 0

    fi

    rm -rf "$INSTALL_DIR"
    rm -f "$BIN_DIR/ubuntu-toolkit"

    success "Ubuntu Toolkit fue desinstalado."

}

if [[ "$UNINSTALL" == true ]]; then

    uninstall
    exit 0

fi

# ------------------------------------------------------------
# Banner
# ------------------------------------------------------------

clear

separator
echo "             UBUNTU TOOLKIT"
echo "             INSTALLER"
echo "             v$SCRIPT_VERSION"
separator

echo
echo "Directorio del proyecto:"
echo "$PROJECT_ROOT"

echo
echo "Destino:"
echo "$INSTALL_DIR"

echo
echo "Ejecutable:"
echo "$BIN_DIR/ubuntu-toolkit"

# ------------------------------------------------------------
# Verificar Ubuntu
# ------------------------------------------------------------

separator
echo "VERIFICACIÓN DEL SISTEMA"
separator

if ! command_exists lsb_release; then

    error "No se encontró lsb_release."

    echo
    echo "Instala:"
    echo
    echo "    sudo apt install lsb-release"

    exit 1

fi

DISTRO_ID="$(lsb_release -si)"
DISTRO_VERSION="$(lsb_release -sr)"
DISTRO_DESCRIPTION="$(lsb_release -sd)"

echo
echo "Sistema:"
echo "$DISTRO_DESCRIPTION"

if [[ "$DISTRO_ID" != "Ubuntu" ]]; then

    warning "Ubuntu Toolkit está diseñado principalmente para Ubuntu."

    echo

    read -rp "¿Deseas continuar? [y/N]: " answer

    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        exit 0
    fi

fi

# ------------------------------------------------------------
# Verificar versión
# ------------------------------------------------------------

if [[ "$DISTRO_ID" == "Ubuntu" ]]; then

    case "$DISTRO_VERSION" in

        24.04*)
            success "Ubuntu 24.04 detectado."
            ;;

        *)
            warning "Versión no probada oficialmente:"
            echo "$DISTRO_VERSION"
            ;;

    esac

fi

# ------------------------------------------------------------
# Verificar Bash
# ------------------------------------------------------------

separator
echo "VERIFICACIÓN DE BASH"
separator

BASH_MAJOR="${BASH_VERSINFO[0]}"
BASH_MINOR="${BASH_VERSINFO[1]}"

echo
echo "Bash:"
echo "$BASH_VERSION"

if (( BASH_MAJOR < 4 )); then

    error "Ubuntu Toolkit requiere Bash 4 o superior."

    exit 1

fi

success "Versión de Bash compatible."

# ------------------------------------------------------------
# Crear directorios
# ------------------------------------------------------------

separator
echo "PREPARANDO DIRECTORIOS"
separator

mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$BACKUP_DIR"

success "Directorios preparados."

# ------------------------------------------------------------
# Copiar toolkit
# ------------------------------------------------------------

separator
echo "INSTALANDO UBUNTU TOOLKIT"
separator

info "Copiando archivos..."

# Copiar scripts
if [[ -d "$SCRIPTS_DIR" ]]; then

    mkdir -p "$INSTALL_DIR/scripts"

    cp -a "$SCRIPTS_DIR/." \
        "$INSTALL_DIR/scripts/"

else

    warning "No existe el directorio scripts/."

fi

# Copiar librerías
if [[ -d "$LIB_DIR" ]]; then

    mkdir -p "$INSTALL_DIR/lib"

    cp -a "$LIB_DIR/." \
        "$INSTALL_DIR/lib/"

fi

# Copiar archivos auxiliares
for file in \
    README.md \
    LICENSE \
    CHANGELOG.md \
    CONTRIBUTING.md
do

    if [[ -f "$PROJECT_ROOT/$file" ]]; then

        cp "$PROJECT_ROOT/$file" \
            "$INSTALL_DIR/"

    fi

done

success "Archivos instalados."

# ------------------------------------------------------------
# Permisos
# ------------------------------------------------------------

separator
echo "CONFIGURANDO PERMISOS"
separator

if [[ -d "$INSTALL_DIR/scripts" ]]; then

    find "$INSTALL_DIR/scripts" \
        -type f \
        -name "*.sh" \
        -exec chmod 755 {} \;

fi

success "Permisos configurados."

# ------------------------------------------------------------
# Crear comando principal
# ------------------------------------------------------------

separator
echo "CREANDO COMANDO PRINCIPAL"
separator

TOOLKIT_BIN="$BIN_DIR/ubuntu-toolkit"

cat > "$TOOLKIT_BIN" <<'EOF'
#!/usr/bin/env bash

set -Eeuo pipefail

TOOLKIT_DIR="$HOME/.local/share/ubuntu-toolkit"
SCRIPTS_DIR="$TOOLKIT_DIR/scripts"

show_help() {

    cat <<HELP

Ubuntu Toolkit

Uso:

    ubuntu-toolkit <comando>

Comandos:

    maintenance
        Mantenimiento seguro de Ubuntu.

    system-info
        Información del sistema.

    disk-check
        Revisar almacenamiento.

    docker-cleanup
        Limpiar Docker.

    network-check
        Diagnóstico de red.

    backup-config
        Respaldar configuraciones.

    git-workflow
        Herramientas para Git.

    new-project
        Crear un nuevo proyecto.

Opciones:

    --help
        Mostrar esta ayuda.

HELP

}

run_script() {

    local script="$1"
    shift

    local script_path="$SCRIPTS_DIR/$script"

    if [[ ! -f "$script_path" ]]; then

        echo
        echo "[ERROR] Script no encontrado:"
        echo "$script_path"
        echo

        exit 1

    fi

    exec "$script_path" "$@"

}

case "${1:-}" in

    maintenance)
        shift
        run_script "maintenance.sh" "$@"
        ;;

    system-info)
        shift
        run_script "system-info.sh" "$@"
        ;;

    disk-check)
        shift
        run_script "disk-check.sh" "$@"
        ;;

    docker-cleanup)
        shift
        run_script "docker-cleanup.sh" "$@"
        ;;

    network-check)
        shift
        run_script "network-check.sh" "$@"
        ;;

    backup-config)
        shift
        run_script "backup-config.sh" "$@"
        ;;

    git-workflow)
        shift
        run_script "git-workflow.sh" "$@"
        ;;

    new-project)
        shift
        run_script "new-project.sh" "$@"
        ;;

    --help|-h)
        show_help
        ;;

    "")
        show_help
        ;;

    *)
        echo
        echo "[ERROR] Comando desconocido: $1"
        echo
        show_help
        exit 1
        ;;

esac
EOF

chmod 755 "$TOOLKIT_BIN"

success "Comando principal creado."

# ------------------------------------------------------------
# PATH
# ------------------------------------------------------------

separator
echo "VERIFICANDO PATH"
separator

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then

    warning "$BIN_DIR no está en PATH."

    echo

    SHELL_NAME="$(basename "${SHELL:-bash}")"

    case "$SHELL_NAME" in

        zsh)

            SHELL_CONFIG="$HOME/.zshrc"
            ;;

        bash)

            if [[ -f "$HOME/.bashrc" ]]; then
                SHELL_CONFIG="$HOME/.bashrc"
            else
                SHELL_CONFIG="$HOME/.profile"
            fi

            ;;

        *)

            SHELL_CONFIG="$HOME/.profile"
            ;;

    esac

    echo "Se recomienda añadir:"
    echo
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo
    echo "al archivo:"
    echo
    echo "    $SHELL_CONFIG"

    echo

    read -rp \
        "¿Añadir automáticamente ~/.local/bin al PATH? [Y/n]: " \
        answer

    if [[ ! "$answer" =~ ^[Nn]$ ]]; then

        if ! grep -Fqx \
            'export PATH="$HOME/.local/bin:$PATH"' \
            "$SHELL_CONFIG" 2>/dev/null; then

            echo 'export PATH="$HOME/.local/bin:$PATH"' \
                >> "$SHELL_CONFIG"

            success "PATH actualizado."

        else

            info "PATH ya estaba configurado."

        fi

    else

        warning "PATH no fue modificado."

    fi

else

    success "$BIN_DIR ya está en PATH."

fi

# ------------------------------------------------------------
# ShellCheck
# ------------------------------------------------------------

separator
echo "VERIFICACIÓN DE SCRIPTS"
separator

if command_exists shellcheck; then

    info "ShellCheck detectado."

    SHELLCHECK_FAILED=false

    while IFS= read -r -d '' script; do

        echo
        echo "Analizando:"
        echo "$script"

        if ! shellcheck "$script"; then
            SHELLCHECK_FAILED=true
        fi

    done < <(
        find "$INSTALL_DIR/scripts" \
            -type f \
            -name "*.sh" \
            -print0
    )

    if [[ "$SHELLCHECK_FAILED" == false ]]; then

        success "ShellCheck no encontró errores."

    else

        warning "ShellCheck encontró advertencias o errores."

    fi

else

    info "ShellCheck no está instalado."
    echo
    echo "Puedes instalarlo con:"
    echo
    echo "    sudo apt install shellcheck"

fi

# ------------------------------------------------------------
# Verificación de instalación
# ------------------------------------------------------------

separator
echo "VERIFICANDO INSTALACIÓN"
separator

if [[ -x "$TOOLKIT_BIN" ]]; then

    success "ubuntu-toolkit instalado."

else

    error "No se pudo instalar el comando principal."

    exit 1

fi

echo
echo "Ubicación:"
echo "$TOOLKIT_BIN"

echo
echo "Versión:"
echo "$SCRIPT_VERSION"

# ------------------------------------------------------------
# Final
# ------------------------------------------------------------

separator
echo "INSTALACIÓN COMPLETADA"
separator

echo
success "Ubuntu Toolkit está instalado."

echo
echo "Ejecutables:"
echo
echo "    $TOOLKIT_BIN"

echo
echo "Prueba:"
echo
echo "    ubuntu-toolkit"

echo
echo "Mantenimiento:"
echo
echo "    ubuntu-toolkit maintenance"

echo
echo "Git:"
echo
echo "    ubuntu-toolkit git-workflow"

echo
echo "Nuevo proyecto:"
echo
echo "    ubuntu-toolkit new-project"

echo

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then

    warning "Es posible que necesites abrir una nueva terminal."

    echo
    echo "O ejecutar:"
    echo
    echo "    source ~/.bashrc"

    echo "si utilizas Bash."

fi

echo
success "Ubuntu Toolkit $SCRIPT_VERSION instalado correctamente."

echo