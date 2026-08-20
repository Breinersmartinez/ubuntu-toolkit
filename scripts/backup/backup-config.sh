#!/usr/bin/env bash

# ============================================================
# Ubuntu Toolkit - Configuration Backup
# Version: 0.1.0
#
# Ubuntu 24.04 LTS
#
# Filosofía:
#   - Backup selectivo
#   - No copiar secretos por defecto
#   - No copiar perfiles completos de aplicaciones
#   - No copiar claves privadas SSH
#   - No copiar credenciales Docker
#   - No sobrescribir backups existentes
#   - Permitir dry-run
#   - Generar manifiesto
#   - Generar checksum SHA-256
#   - Backup reproducible y fácil de restaurar
#
# Uso:
#
#   sudo ./backup-config.sh
#   sudo ./backup-config.sh --dry-run
#   sudo ./backup-config.sh --output /ruta/backup
#   sudo ./backup-config.sh --include-ssh
#   sudo ./backup-config.sh --include-brave
#   sudo ./backup-config.sh --include-vscode
#   sudo ./backup-config.sh --help
#
# ============================================================

set -Eeuo pipefail

# ------------------------------------------------------------
# Configuración
# ------------------------------------------------------------

SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="0.1.0"

USER_NAME="${SUDO_USER:-${USER:-root}}"

if ! USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"; then
    echo "ERROR: no se pudo determinar el HOME del usuario."
    exit 1
fi

TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"

DEFAULT_BACKUP_ROOT="$USER_HOME/ubuntu-toolkit-backups"
DEFAULT_BACKUP_DIR="$DEFAULT_BACKUP_ROOT/backup-$TIMESTAMP"

BACKUP_DIR="$DEFAULT_BACKUP_DIR"

DRY_RUN=false

INCLUDE_SSH=false
INCLUDE_BRAVE=false
INCLUDE_VSCODE=false

MANIFEST_FILE=""
CHECKSUM_FILE=""

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

run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] $*"
    else
        "$@"
    fi
}

# ------------------------------------------------------------
# Ayuda
# ------------------------------------------------------------

show_help() {
    cat <<EOF

Ubuntu Toolkit - Configuration Backup

Versión: $SCRIPT_VERSION

Uso:

    sudo ./$SCRIPT_NAME
    sudo ./$SCRIPT_NAME --dry-run

Opciones:

    --dry-run
        Mostrar qué se respaldaría sin crear archivos.

    --output PATH
        Especificar directorio de backup.

    --include-ssh
        Respaldar ~/.ssh/config.

        IMPORTANTE:
        No se respaldan claves privadas ni públicas.

    --include-brave
        Respaldar preferencias básicas de Brave.

        IMPORTANTE:
        No se respaldan perfiles completos,
        cookies, sesiones ni credenciales.

    --include-vscode
        Respaldar configuración de VS Code.

    --help
        Mostrar esta ayuda.

Por defecto se respaldan:

    ~/.bashrc
    ~/.profile
    ~/.bash_aliases
    ~/.gitconfig
    ~/.gitignore_global
    ~/.config/user-dirs.dirs
    ~/.config/user-dirs.locale
    ~/.config/gtk-3.0
    ~/.config/gtk-4.0
    ~/.config/dconf
    configuración básica de terminal
    listas de paquetes APT
    repositorios APT
    lista de paquetes Snap

NO se respaldan:

    ~/.ssh/id_*
    ~/.gnupg
    ~/.password-store
    ~/.docker/config.json
    ~/.config/BraveSoftware/Brave-Browser/Default/Cookies
    ~/.config/BraveSoftware/Brave-Browser/Default/Login Data
    perfiles completos de Brave
    credenciales
    tokens
    claves privadas
    archivos .env

EOF
}

# ------------------------------------------------------------
# Argumentos
# ------------------------------------------------------------

while [[ $# -gt 0 ]]; do

    case "$1" in

        --dry-run)
            DRY_RUN=true
            shift
            ;;

        --include-ssh)
            INCLUDE_SSH=true
            shift
            ;;

        --include-brave)
            INCLUDE_BRAVE=true
            shift
            ;;

        --include-vscode)
            INCLUDE_VSCODE=true
            shift
            ;;

        --output)

            if [[ $# -lt 2 ]]; then
                error "--output requiere una ruta."
                exit 1
            fi

            BACKUP_DIR="$2"
            shift 2
            ;;

        --help|-h)
            show_help
            exit 0
            ;;

        *)
            error "Argumento desconocido: $1"
            echo
            show_help
            exit 1
            ;;

    esac

done

# ------------------------------------------------------------
# Comprobación de root
# ------------------------------------------------------------

if [[ "$EUID" -ne 0 ]]; then

    error "Este script requiere privilegios de administrador."

    echo
    echo "Ejecuta:"
    echo
    echo "    sudo $SCRIPT_NAME"
    echo

    exit 1

fi

# ------------------------------------------------------------
# Validación Ubuntu
# ------------------------------------------------------------

if command_exists lsb_release; then

    DISTRO_ID="$(lsb_release -si)"
    DISTRO_VERSION="$(lsb_release -sr)"
    DISTRO_DESCRIPTION="$(lsb_release -sd)"

else

    warning "No se encontró lsb_release."

    DISTRO_ID="Unknown"
    DISTRO_VERSION="Unknown"
    DISTRO_DESCRIPTION="Unknown"

fi

if [[ "$DISTRO_ID" != "Ubuntu" ]]; then

    warning "Este script fue diseñado para Ubuntu."
    warning "Sistema detectado: $DISTRO_DESCRIPTION"

    if [[ "$DRY_RUN" == false ]]; then

        read -rp "¿Deseas continuar? [y/N]: " answer

        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
            exit 0
        fi

    fi

fi

# ------------------------------------------------------------
# Preparar backup
# ------------------------------------------------------------

if [[ "$DRY_RUN" == false ]]; then

    if [[ -e "$BACKUP_DIR" ]]; then

        error "El directorio de backup ya existe:"
        error "$BACKUP_DIR"

        echo
        echo "No se sobrescribirá."

        exit 1

    fi

    mkdir -p "$BACKUP_DIR"
    chmod 700 "$BACKUP_DIR"

    MANIFEST_FILE="$BACKUP_DIR/MANIFEST.txt"
    CHECKSUM_FILE="$BACKUP_DIR/SHA256SUMS"

    touch "$MANIFEST_FILE"
    chmod 600 "$MANIFEST_FILE"

fi

# ------------------------------------------------------------
# Funciones de backup
# ------------------------------------------------------------

backup_file() {

    local source="$1"
    local relative_path="$2"

    if [[ ! -e "$source" ]]; then

        warning "No encontrado: $source"
        return 0

    fi

    local destination="$BACKUP_DIR/$relative_path"

    if [[ "$DRY_RUN" == true ]]; then

        echo "[DRY-RUN] Backup:"
        echo "           $source"
        echo "        -> $destination"

        return 0

    fi

    mkdir -p "$(dirname "$destination")"

    cp -a "$source" "$destination"

    success "Respaldado: $relative_path"

    echo "$source -> $destination" >> "$MANIFEST_FILE"
}

backup_directory_selective() {

    local source="$1"
    local relative_path="$2"

    if [[ ! -d "$source" ]]; then

        warning "Directorio no encontrado: $source"
        return 0

    fi

    local destination="$BACKUP_DIR/$relative_path"

    if [[ "$DRY_RUN" == true ]]; then

        echo "[DRY-RUN] Backup selectivo:"
        echo "           $source"
        echo "        -> $destination"

        return 0

    fi

    mkdir -p "$destination"

    cp -a "$source" "$destination"

    success "Respaldado: $relative_path"

    echo "$source -> $destination" >> "$MANIFEST_FILE"
}

# ------------------------------------------------------------
# Encabezado
# ------------------------------------------------------------

clear

separator
echo "             UBUNTU TOOLKIT"
echo "             CONFIG BACKUP"
separator

echo
echo "Versión:"
echo "$SCRIPT_VERSION"

echo
echo "Sistema:"
echo "$DISTRO_DESCRIPTION"

echo
echo "Usuario:"
echo "$USER_NAME"

echo
echo "Home:"
echo "$USER_HOME"

echo
echo "Destino:"
echo "$BACKUP_DIR"

echo
echo "Fecha:"
echo "$(date)"

if [[ "$DRY_RUN" == true ]]; then

    echo
    warning "MODO DRY-RUN"
    warning "No se crearán archivos."

fi

# ------------------------------------------------------------
# Advertencia de seguridad
# ------------------------------------------------------------

separator
echo "SEGURIDAD"
separator

echo
echo "Este backup NO incluirá automáticamente:"
echo
echo "  - claves privadas SSH"
echo "  - claves GPG"
echo "  - credenciales Docker"
echo "  - cookies"
echo "  - sesiones de navegador"
echo "  - contraseñas guardadas"
echo "  - tokens"
echo "  - archivos .env"
echo "  - perfiles completos de navegadores"

echo
echo "El objetivo es respaldar CONFIGURACIÓN,"
echo "no secretos personales."

if [[ "$DRY_RUN" == false ]]; then

    echo

    if ! confirm "¿Deseas continuar con el backup?"; then
        info "Backup cancelado."
        exit 0
    fi

fi

# ------------------------------------------------------------
# Crear manifest inicial
# ------------------------------------------------------------

if [[ "$DRY_RUN" == false ]]; then

    cat > "$MANIFEST_FILE" <<EOF
Ubuntu Toolkit - Configuration Backup

Version:
$SCRIPT_VERSION

Date:
$(date)

User:
$USER_NAME

Home:
$USER_HOME

System:
$DISTRO_DESCRIPTION

Kernel:
$(uname -r)

Backup:
$BACKUP_DIR

------------------------------------------------------------
Files and directories:
------------------------------------------------------------

EOF

fi

# ------------------------------------------------------------
# 1. Shell
# ------------------------------------------------------------

separator
echo "[1/9] CONFIGURACIÓN DE SHELL"
separator

backup_file \
    "$USER_HOME/.bashrc" \
    "home/.bashrc"

backup_file \
    "$USER_HOME/.profile" \
    "home/.profile"

backup_file \
    "$USER_HOME/.bash_aliases" \
    "home/.bash_aliases"

# ------------------------------------------------------------
# 2. Git
# ------------------------------------------------------------

separator
echo "[2/9] CONFIGURACIÓN DE GIT"
separator

backup_file \
    "$USER_HOME/.gitconfig" \
    "home/.gitconfig"

backup_file \
    "$USER_HOME/.gitignore_global" \
    "home/.gitignore_global"

# ------------------------------------------------------------
# 3. GNOME / Desktop
# ------------------------------------------------------------

separator
echo "[3/9] CONFIGURACIÓN DEL ESCRITORIO"
separator

backup_file \
    "$USER_HOME/.config/user-dirs.dirs" \
    "config/user-dirs.dirs"

backup_file \
    "$USER_HOME/.config/user-dirs.locale" \
    "config/user-dirs.locale"

backup_directory_selective \
    "$USER_HOME/.config/gtk-3.0" \
    "config/gtk-3.0"

backup_directory_selective \
    "$USER_HOME/.config/gtk-4.0" \
    "config/gtk-4.0"

backup_directory_selective \
    "$USER_HOME/.config/dconf" \
    "config/dconf"

# ------------------------------------------------------------
# 4. Terminal
# ------------------------------------------------------------

separator
echo "[4/9] CONFIGURACIÓN DE TERMINAL"
separator

backup_directory_selective \
    "$USER_HOME/.config/tilix" \
    "config/tilix"

backup_directory_selective \
    "$USER_HOME/.config/terminator" \
    "config/terminator"

# ------------------------------------------------------------
# 5. SSH
# ------------------------------------------------------------

separator
echo "[5/9] SSH"
separator

if [[ "$INCLUDE_SSH" == true ]]; then

    if [[ -f "$USER_HOME/.ssh/config" ]]; then

        backup_file \
            "$USER_HOME/.ssh/config" \
            "ssh/config"

    else

        warning "No existe ~/.ssh/config"

    fi

    echo
    warning "Solo se respalda ~/.ssh/config."
    warning "No se respaldan claves SSH."

else

    info "SSH omitido."
    echo
    echo "Usa --include-ssh para respaldar ~/.ssh/config."

fi

# ------------------------------------------------------------
# 6. VS Code
# ------------------------------------------------------------

separator
echo "[6/9] VISUAL STUDIO CODE"
separator

if [[ "$INCLUDE_VSCODE" == true ]]; then

    VSCODE_CONFIG="$USER_HOME/.config/Code/User"

    if [[ -d "$VSCODE_CONFIG" ]]; then

        mkdir -p "$BACKUP_DIR/config/Code/User"

        if [[ "$DRY_RUN" == true ]]; then

            echo "[DRY-RUN] Backup selectivo de VS Code:"
            echo "$VSCODE_CONFIG"

        else

            # Solo configuración.
            #
            # Se excluyen:
            #   - History
            #   - workspaceStorage
            #   - globalStorage
            #   - logs

            if [[ -f "$VSCODE_CONFIG/settings.json" ]]; then
                cp -a \
                    "$VSCODE_CONFIG/settings.json" \
                    "$BACKUP_DIR/config/Code/User/"
            fi

            if [[ -f "$VSCODE_CONFIG/keybindings.json" ]]; then
                cp -a \
                    "$VSCODE_CONFIG/keybindings.json" \
                    "$BACKUP_DIR/config/Code/User/"
            fi

            if [[ -f "$VSCODE_CONFIG/tasks.json" ]]; then
                cp -a \
                    "$VSCODE_CONFIG/tasks.json" \
                    "$BACKUP_DIR/config/Code/User/"
            fi

            if [[ -f "$VSCODE_CONFIG/snippets" ]]; then
                cp -a \
                    "$VSCODE_CONFIG/snippets" \
                    "$BACKUP_DIR/config/Code/User/"
            fi

            success "Configuración básica de VS Code respaldada."

            echo \
                "$VSCODE_CONFIG -> $BACKUP_DIR/config/Code/User" \
                >> "$MANIFEST_FILE"

        fi

    else

        warning "VS Code no encontrado."

    fi

else

    info "VS Code omitido."
    echo
    echo "Usa --include-vscode para incluir configuración."

fi

# ------------------------------------------------------------
# 7. Brave
# ------------------------------------------------------------

separator
echo "[7/9] BRAVE"
separator

if [[ "$INCLUDE_BRAVE" == true ]]; then

    BRAVE_DIR="$USER_HOME/.config/BraveSoftware/Brave-Browser"

    if [[ -d "$BRAVE_DIR" ]]; then

        if [[ "$DRY_RUN" == true ]]; then

            echo "[DRY-RUN] Backup selectivo de Brave:"
            echo "$BRAVE_DIR"

        else

            mkdir -p "$BACKUP_DIR/config/BraveSoftware"

            # Solo archivos de preferencias.
            #
            # NO se copian:
            #   Cookies
            #   Login Data
            #   History
            #   Web Data
            #   Sessions
            #   Current Session
            #   Current Tabs
            #   Bookmarks
            #
            # Los perfiles completos NO se respaldan.

            if [[ -f "$BRAVE_DIR/Local State" ]]; then

                cp -a \
                    "$BRAVE_DIR/Local State" \
                    "$BACKUP_DIR/config/BraveSoftware/"

            fi

            success "Configuración básica de Brave respaldada."

            echo \
                "$BRAVE_DIR -> configuración selectiva" \
                >> "$MANIFEST_FILE"

        fi

    else

        warning "Brave no encontrado."

    fi

else

    info "Brave omitido."
    echo
    echo "Usa --include-brave para incluir configuración básica."

fi

# ------------------------------------------------------------
# 8. Paquetes y sistema
# ------------------------------------------------------------

separator
echo "[8/9] INFORMACIÓN DEL SISTEMA"
separator

if [[ "$DRY_RUN" == true ]]; then

    echo "[DRY-RUN] Se generarían:"
    echo "  - lista de paquetes APT"
    echo "  - lista de paquetes Snap"
    echo "  - repositorios APT"
    echo "  - información del kernel"

else

    # Paquetes instalados
    dpkg-query \
        -W \
        -f='${binary:Package}\t${Version}\n' \
        > "$BACKUP_DIR/apt-installed-packages.txt"

    success "Lista de paquetes APT creada."

    # Paquetes Snap
    if command_exists snap; then

        snap list \
            > "$BACKUP_DIR/snap-packages.txt" 2>/dev/null || true

        success "Lista de paquetes Snap creada."

    fi

    # Repositorios APT
    mkdir -p "$BACKUP_DIR/apt"

    if [[ -d /etc/apt/sources.list.d ]]; then

        cp -a \
            /etc/apt/sources.list.d \
            "$BACKUP_DIR/apt/"

    fi

    if [[ -f /etc/apt/sources.list ]]; then

        cp -a \
            /etc/apt/sources.list \
            "$BACKUP_DIR/apt/"

    fi

    success "Repositorios APT respaldados."

    # Kernel
    uname -a > "$BACKUP_DIR/system-info.txt"

    success "Información del sistema guardada."

fi

# ------------------------------------------------------------
# 9. Servicios habilitados
# ------------------------------------------------------------

separator
echo "[9/9] SERVICIOS DEL SISTEMA"
separator

if [[ "$DRY_RUN" == true ]]; then

    echo "[DRY-RUN] Se generaría:"
    echo "  systemd-enabled-services.txt"

else

    systemctl list-unit-files \
        --state=enabled \
        --no-pager \
        > "$BACKUP_DIR/systemd-enabled-services.txt" 2>/dev/null || true

    success "Lista de servicios habilitados creada."

fi

# ------------------------------------------------------------
# Permisos
# ------------------------------------------------------------

if [[ "$DRY_RUN" == false ]]; then

    separator
    echo "AJUSTANDO PERMISOS"
    separator

    chmod -R u+rwX,go-rwx "$BACKUP_DIR"

    success "Permisos restrictivos aplicados."

fi

# ------------------------------------------------------------
# Generar checksum
# ------------------------------------------------------------

if [[ "$DRY_RUN" == false ]]; then

    separator
    echo "CHECKSUM SHA-256"
    separator

    (
        cd "$BACKUP_DIR"

        find . \
            -type f \
            ! -name "SHA256SUMS" \
            -print0 |
            sort -z |
            xargs -0 sha256sum
    ) > "$CHECKSUM_FILE"

    chmod 600 "$CHECKSUM_FILE"

    success "SHA-256 generado."

fi

# ------------------------------------------------------------
# Resumen
# ------------------------------------------------------------

separator
echo "BACKUP COMPLETADO"
separator

if [[ "$DRY_RUN" == true ]]; then

    echo
    warning "MODO DRY-RUN"
    echo
    echo "No se creó ningún backup."
    echo
    echo "Ejecuta sin --dry-run para crear el backup."

else

    echo
    echo "Backup:"
    echo "$BACKUP_DIR"

    echo
    echo "Manifest:"
    echo "$MANIFEST_FILE"

    echo
    echo "Checksum:"
    echo "$CHECKSUM_FILE"

    echo
    echo "Tamaño:"
    du -sh "$BACKUP_DIR"

    echo
    echo "Archivos:"
    find "$BACKUP_DIR" -type f | wc -l

    echo
    echo "Permisos:"
    stat -c '%A %U:%G %n' "$BACKUP_DIR"

fi

separator
echo "UBUNTU TOOLKIT - CONFIG BACKUP $SCRIPT_VERSION"
separator

