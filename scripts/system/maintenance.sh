#!/usr/bin/env bash

# ============================================================
# Ubuntu Toolkit - Safe Maintenance
# Version: 0.1.0
#
# Ubuntu 24.04 LTS
#
# Filosofía:
#   - Safe by default
#   - No eliminar configuraciones personales
#   - No eliminar perfiles de aplicaciones
#   - No tocar /etc/fstab
#   - No tocar SSH
#   - No eliminar Docker
#   - No ejecutar apt autoremove
#   - No ejecutar apt clean automáticamente
#   - No actualizar paquetes sin confirmación
#   - Respaldar configuraciones antes de modificarlas
#   - Permitir dry-run
#   - Registrar todas las operaciones
#
# Uso:
#   sudo ./maintenance.sh
#   sudo ./maintenance.sh --dry-run
#   sudo ./maintenance.sh --help
# ============================================================

set -Eeuo pipefail


# Configuración


SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="0.1.0"

USER_NAME="${SUDO_USER:-${USER:-root}}"

if ! USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"; then
    echo "ERROR: no se pudo determinar el HOME del usuario."
    exit 1
fi

TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"

BACKUP_DIR="$USER_HOME/ubuntu-toolkit-backup-$TIMESTAMP"
LOG_FILE="$USER_HOME/ubuntu-toolkit-maintenance-$TIMESTAMP.log"

SYSCTL_FILE="/etc/sysctl.d/99-ubuntu-toolkit.conf"

DRY_RUN=false
APT_SAFE=false
BACKUP_CREATED=false


# Colores


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


# Funciones básicas


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

pause() {
    echo
    read -rp "Presiona ENTER para continuar..."
}

confirm() {
    local prompt="$1"
    local answer

    read -rp "$prompt [y/N]: " answer

    [[ "$answer" =~ ^[Yy]$ ]]
}

run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] $*"
    else
        "$@"
    fi
}


# Manejo de errores


on_error() {
    local exit_code=$?
    local line_number=$1

    error "El script encontró un error en la línea $line_number."
    error "Código de salida: $exit_code"

    if [[ -n "${LOG_FILE:-}" ]]; then
        error "Revisa el log:"
        error "$LOG_FILE"
    fi

    exit "$exit_code"
}

trap 'on_error $LINENO' ERR


# Ayuda


show_help() {
    cat <<EOF

Ubuntu Toolkit - Safe Maintenance

Versión: $SCRIPT_VERSION

Uso:

    sudo ./$SCRIPT_NAME
    sudo ./$SCRIPT_NAME --dry-run
    sudo ./$SCRIPT_NAME --help

Opciones:

    --dry-run     Mostrar las acciones sin ejecutarlas.
    --help        Mostrar esta ayuda.

El script NO:

    - ejecuta apt autoremove
    - ejecuta apt clean automáticamente
    - modifica /etc/fstab
    - elimina ~/.config
    - elimina ~/.local
    - elimina ~/.ssh
    - elimina perfiles de Brave
    - elimina configuración de VS Code
    - elimina configuración de Git
    - elimina Docker
    - elimina contenedores Docker
    - elimina imágenes Docker
    - elimina volúmenes Docker

EOF
}


# Argumentos


for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=true
            ;;

        --help|-h)
            show_help
            exit 0
            ;;

        *)
            error "Argumento desconocido: $arg"
            echo
            show_help
            exit 1
            ;;
    esac
done


# Comprobación de root


if [[ "$EUID" -ne 0 ]]; then
    error "Este script requiere privilegios de administrador."
    echo
    echo "Ejecuta:"
    echo
    echo "    sudo $SCRIPT_NAME"
    echo
    echo "O:"
    echo
    echo "    sudo $SCRIPT_NAME --dry-run"
    exit 1
fi


# Validación del sistema


if ! command_exists lsb_release; then
    error "No se encontró lsb_release."
    exit 1
fi

DISTRO_ID="$(lsb_release -si)"
DISTRO_VERSION="$(lsb_release -sr)"
DISTRO_DESCRIPTION="$(lsb_release -sd)"

if [[ "$DISTRO_ID" != "Ubuntu" ]]; then
    error "Este script está diseñado para Ubuntu."
    error "Sistema detectado: $DISTRO_DESCRIPTION"
    exit 1
fi

if [[ "${DISTRO_VERSION%%.*}" -lt 24 ]]; then
    warning "Esta versión de Ubuntu podría no estar soportada oficialmente."
    warning "Sistema detectado: $DISTRO_DESCRIPTION"

    if ! confirm "¿Deseas continuar de todas formas?"; then
        exit 0
    fi
fi


# Inicializar backup y log


if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$BACKUP_DIR"
    touch "$LOG_FILE"

    chown "$USER_NAME":"$(id -gn "$USER_NAME")" "$LOG_FILE"

    exec > >(tee -a "$LOG_FILE") 2>&1
else
    LOG_FILE="(dry-run: no se creó log)"
fi


# Encabezado


clear

separator
echo "             UBUNTU TOOLKIT"
echo "             SAFE MAINTENANCE"
separator

echo
echo "Versión:  $SCRIPT_VERSION"
echo "Sistema:  $DISTRO_DESCRIPTION"
echo "Usuario:  $USER_NAME"
echo "Home:     $USER_HOME"
echo "Inicio:   $(date)"

if [[ "$DRY_RUN" == true ]]; then
    echo
    warning "MODO DRY-RUN ACTIVADO"
    warning "No se ejecutarán cambios."
fi

if [[ "$DRY_RUN" == false ]]; then
    echo
    echo "Backup:"
    echo "$BACKUP_DIR"

    echo
    echo "Log:"
    echo "$LOG_FILE"
fi


# 1. Información del sistema


separator
echo "[1/10] INFORMACIÓN DEL SISTEMA"
separator

echo
echo "Sistema operativo:"
echo "$DISTRO_DESCRIPTION"

echo
echo "Kernel:"
uname -r

echo
echo "Arquitectura:"
uname -m

echo
echo "CPU:"

if command_exists lscpu; then
    lscpu | grep -E '^Model name:|^CPU\(s\):' | head -2 || true
fi

echo
echo "RAM:"
free -h

echo
echo "Almacenamiento:"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,ROTA

echo
echo "Uso de /:"
df -h /


# 2. Comprobar APT / DPKG


separator
echo "[2/10] COMPROBANDO APT / DPKG"
separator

apt_is_busy() {

    local locks=(
        "/var/lib/dpkg/lock-frontend"
        "/var/lib/dpkg/lock"
        "/var/lib/apt/lists/lock"
        "/var/cache/apt/archives/lock"
    )

    local lock

    for lock in "${locks[@]}"; do
        if command_exists fuser &&
           fuser "$lock" >/dev/null 2>&1; then

            return 0
        fi
    done

    if pgrep -x apt >/dev/null 2>&1; then
        return 0
    fi

    if pgrep -x apt-get >/dev/null 2>&1; then
        return 0
    fi

    if pgrep -x dpkg >/dev/null 2>&1; then
        return 0
    fi

    if pgrep -f "unattended-upgrade" >/dev/null 2>&1; then
        return 0
    fi

    return 1
}

if apt_is_busy; then

    warning "APT/Dpkg está siendo utilizado por otro proceso."

    echo
    echo "Procesos relacionados:"

    ps aux | grep -E \
        '[a]pt|[d]pkg|[u]nattended-upgrade' || true

    echo
    warning "Las operaciones de APT serán omitidas."

    APT_SAFE=false

else

    success "APT/Dpkg está libre."
    APT_SAFE=true

fi


# 3. Limpieza segura de APT


separator
echo "[3/10] LIMPIEZA SEGURA DE APT"
separator

if [[ "$APT_SAFE" == true ]]; then

    echo
    info "Se ejecutará únicamente apt autoclean."

    if [[ "$DRY_RUN" == true ]]; then

        echo "[DRY-RUN] apt autoclean"

    else

        apt autoclean -y

    fi

    echo
    echo "No se ejecutará:"
    echo "  - apt clean"
    echo "  - apt autoremove"

else

    warning "Se omitió la limpieza de APT."

fi


# 4. Actualización opcional


separator
echo "[4/10] ACTUALIZACIÓN DEL SISTEMA"
separator

if [[ "$APT_SAFE" == true ]]; then

    echo
    echo "La actualización NO se ejecutará automáticamente."

    if [[ "$DRY_RUN" == true ]]; then

        echo
        echo "[DRY-RUN] Se comprobaría:"
        echo "  apt update"
        echo "  apt upgrade"

    else

        if confirm "¿Deseas actualizar los paquetes del sistema?"; then

            info "Actualizando índices..."

            apt update

            echo
            info "Actualizando paquetes..."

            apt upgrade -y

            success "Actualización completada."

        else

            info "Actualización omitida por el usuario."

        fi

    fi

else

    warning "APT no está disponible para actualización."

fi


# 5. Verificación DPKG


separator
echo "[5/10] VERIFICACIÓN DE PAQUETES"
separator

if [[ "$APT_SAFE" == true ]]; then

    echo
    info "Buscando paquetes con problemas..."

    if [[ "$DRY_RUN" == true ]]; then

        echo "[DRY-RUN] dpkg --audit"

    else

        if dpkg --audit; then
            success "No se detectaron paquetes pendientes."
        else
            warning "dpkg --audit encontró posibles problemas."
        fi

    fi

    echo
    info "Comprobando configuración pendiente..."

    if [[ "$DRY_RUN" == true ]]; then

        echo "[DRY-RUN] dpkg --configure -a"

    else

        dpkg --configure -a

    fi

else

    warning "Se omitió la verificación de paquetes."

fi


# 6. ZRAM


separator
echo "[6/10] MEMORIA / ZRAM"
separator

if command_exists zramctl; then

    echo
    echo "Estado actual de ZRAM:"
    zramctl || true

else

    warning "zramctl no está instalado."

    echo
    echo "No se instalará automáticamente."

fi

echo
echo "Memoria:"
free -h


# 7. Sysctl opcional


separator
echo "[7/10] AJUSTES CONSERVADORES DE MEMORIA"
separator

echo
echo "Este paso modifica:"
echo
echo "  $SYSCTL_FILE"
echo
echo "Ajustes:"
echo
echo "  vm.swappiness=10"
echo "  vm.vfs_cache_pressure=50"
echo
echo "La configuración será respaldada antes de modificarla."

if [[ "$DRY_RUN" == true ]]; then

    echo
    echo "[DRY-RUN] Se realizaría:"
    echo "  Backup de $SYSCTL_FILE"
    echo "  Crear $SYSCTL_FILE"
    echo "  Aplicar sysctl --system"

else

    if confirm "¿Deseas aplicar estos ajustes conservadores?"; then

        # Backup
        if [[ -f "$SYSCTL_FILE" ]]; then

            cp -a "$SYSCTL_FILE" "$BACKUP_DIR/"
            success "Configuración anterior respaldada."

        else

            echo "No existía una configuración previa."
            echo "Se registrará esta información en el backup."

            cat > "$BACKUP_DIR/sysctl-original-state.txt" <<EOF
El archivo $SYSCTL_FILE no existía antes de ejecutar maintenance.sh.

Fecha:
$(date)
EOF

        fi

        cat > "$SYSCTL_FILE" <<'EOF'
# Ubuntu Toolkit
# Safe Maintenance
#
# Ajustes conservadores de memoria.
#
# Este archivo puede eliminarse para volver
# al comportamiento predeterminado del sistema.

vm.swappiness=10
vm.vfs_cache_pressure=50
EOF

        sysctl --system

        success "Ajustes de memoria aplicados."

    else

        info "Ajustes de memoria omitidos."

    fi

fi


# 8. SSD / TRIM


separator
echo "[8/10] SSD / TRIM"
separator

if systemctl list-unit-files 2>/dev/null |
    grep -q '^fstrim.timer'; then

    echo
    info "fstrim.timer está disponible."

    if [[ "$DRY_RUN" == true ]]; then

        echo "[DRY-RUN] systemctl enable fstrim.timer"

    else

        systemctl enable fstrim.timer

        success "fstrim.timer habilitado."

        echo
        echo "Estado:"
        systemctl status fstrim.timer --no-pager | head -15 || true

    fi

else

    warning "fstrim.timer no está disponible."

fi


# 9. Temporales


separator
echo "[9/10] LIMPIEZA DE ARCHIVOS TEMPORALES"
separator

echo
echo "Se utilizará systemd-tmpfiles para la limpieza."

echo
echo "No se tocarán manualmente:"
echo
echo "  ~/.config"
echo "  ~/.local"
echo "  ~/.ssh"
echo "  ~/.gnupg"
echo "  ~/.mozilla"
echo "  ~/.var"
echo "  ~/.docker"
echo "  ~/.vscode"
echo "  ~/snap"
echo
echo "No se eliminarán perfiles de aplicaciones."

if [[ "$DRY_RUN" == true ]]; then

    echo
    echo "[DRY-RUN] systemd-tmpfiles --clean"

else

    systemd-tmpfiles --clean

    success "Limpieza temporal completada."

fi


# 10. Diagnóstico final


separator
echo "[10/10] DIAGNÓSTICO FINAL"
separator

echo
echo "RAM:"
free -h

echo
echo "DISCO:"
df -h /

echo
echo "ZRAM:"

if command_exists zramctl; then
    zramctl || true
else
    echo "No disponible."
fi

echo
echo "TRIM:"

systemctl is-enabled fstrim.timer 2>/dev/null || true

echo
echo "PROCESOS CON MAYOR USO DE RAM:"

ps aux --sort=-%mem | head -n 11

echo
echo "PROCESOS CON MAYOR USO DE CPU:"

ps aux --sort=-%cpu | head -n 11


# Verificación de configuraciones


separator
echo "VERIFICACIÓN DE CONFIGURACIONES PRESERVADAS"
separator

echo
echo "SSH:"
if [[ -d "$USER_HOME/.ssh" ]]; then
    success "Preservado: ~/.ssh"
else
    echo "No encontrado."
fi

echo
echo "Git:"
if [[ -f "$USER_HOME/.gitconfig" ]]; then
    success "Preservado: ~/.gitconfig"
else
    echo "No encontrado."
fi

echo
echo "Brave:"
if [[ -d "$USER_HOME/.config/BraveSoftware" ]]; then
    success "Preservado: Brave"
else
    echo "No encontrado."
fi

echo
echo "VS Code:"
if [[ -d "$USER_HOME/.config/Code" ]]; then
    success "Preservado: VS Code"
else
    echo "No encontrado."
fi

echo
echo "Docker:"
if [[ -d "$USER_HOME/.docker" ]]; then
    success "Preservado: Docker"
else
    echo "No encontrado."
fi

echo
echo "GNOME:"
if [[ -d "$USER_HOME/.config/dconf" ]]; then
    success "Preservado: configuración GNOME"
else
    echo "No encontrado."
fi


# Resumen final


separator
echo "RESUMEN"
separator

echo
success "Mantenimiento finalizado."

echo
echo "No se ejecutó automáticamente:"
echo
echo "  - apt autoremove"
echo "  - apt clean"
echo "  - eliminación de ~/.config"
echo "  - eliminación de ~/.local"
echo "  - eliminación de ~/.ssh"
echo "  - eliminación de perfiles de Brave"
echo "  - eliminación de configuración de VS Code"
echo "  - eliminación de configuración de Git"
echo "  - eliminación de Docker"
echo "  - eliminación de contenedores Docker"
echo "  - eliminación de imágenes Docker"
echo "  - eliminación de volúmenes Docker"
echo "  - modificación de /etc/fstab"

if [[ "$DRY_RUN" == false ]]; then

    echo
    echo "Backup:"
    echo "$BACKUP_DIR"

    echo
    echo "Log:"
    echo "$LOG_FILE"

else

    echo
    echo "Modo dry-run:"
    echo "No se realizaron modificaciones."

fi

echo
echo "Finalizado:"
echo "$(date)"

separator
echo "UBUNTU TOOLKIT - SAFE MAINTENANCE $SCRIPT_VERSION"
separator

