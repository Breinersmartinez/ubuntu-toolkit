#!/usr/bin/env bash

# ============================================================
# Ubuntu Toolkit - System Information
# Version: 0.1.0
#
# Ubuntu 24.04 LTS
#
# Filosofía:
#   - Solo diagnóstico
#   - No modificar el sistema
#   - No instalar paquetes
#   - No eliminar archivos
#   - No modificar configuraciones
#   - No ejecutar comandos destructivos
#
# Uso:
#   ./system-info.sh
#   ./system-info.sh --save
#   ./system-info.sh --output reporte.txt
#   ./system-info.sh --help
# ============================================================

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="0.1.0"

SAVE_REPORT=false
OUTPUT_FILE=""


# Colores


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


# Funciones


command_exists() {
    command -v "$1" >/dev/null 2>&1
}

separator() {
    echo
    echo "============================================================"
}

title() {
    separator
    echo -e "${BLUE}$1${RESET}"
    separator
}

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

show_help() {
    cat <<EOF

Ubuntu Toolkit - System Information

Versión: $SCRIPT_VERSION

Herramienta de diagnóstico de solo lectura.

Uso:

    ./$SCRIPT_NAME
    ./$SCRIPT_NAME --save
    ./$SCRIPT_NAME --output archivo.txt
    ./$SCRIPT_NAME --help

Opciones:

    --save              Guardar reporte automáticamente.
    --output <archivo>  Guardar reporte en una ruta específica.
    --help              Mostrar esta ayuda.

El script NO:

    - instala paquetes
    - elimina paquetes
    - modifica configuraciones
    - modifica /etc
    - modifica /etc/fstab
    - modifica sysctl
    - modifica Docker
    - modifica usuarios
    - elimina archivos

EOF
}


# Manejo de errores


on_error() {
    local exit_code=$?
    local line_number="$1"

    error "Se produjo un error en la línea $line_number."
    error "Código de salida: $exit_code"

    exit "$exit_code"
}

trap 'on_error $LINENO' ERR


# Argumentos


while [[ $# -gt 0 ]]; do

    case "$1" in

        --save)
            SAVE_REPORT=true
            shift
            ;;

        --output)
            if [[ $# -lt 2 ]]; then
                error "Falta la ruta después de --output."
                exit 1
            fi

            OUTPUT_FILE="$2"
            SAVE_REPORT=true
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


# Configuración del reporte


if [[ "$SAVE_REPORT" == true && -z "$OUTPUT_FILE" ]]; then

    REPORT_DIR="${HOME}/ubuntu-toolkit-reports"

    mkdir -p "$REPORT_DIR"

    OUTPUT_FILE="$REPORT_DIR/system-info-$(date '+%Y%m%d_%H%M%S').txt"

fi


# Encabezado


clear

separator
echo -e "${MAGENTA}           UBUNTU TOOLKIT${RESET}"
echo -e "${MAGENTA}           SYSTEM INFORMATION${RESET}"
separator

echo
echo "Versión del script: $SCRIPT_VERSION"
echo "Fecha: $(date)"
echo "Usuario: $(whoami)"

if [[ "$SAVE_REPORT" == true ]]; then
    echo "Reporte: $OUTPUT_FILE"
fi

echo
info "Modo diagnóstico: solo lectura."


# 1. Sistema operativo


title "[1] SISTEMA OPERATIVO"

if command_exists lsb_release; then

    echo "Distribución:"
    lsb_release -ds

    echo "Release:"
    lsb_release -rs

    echo "Codename:"
    lsb_release -cs

else

    if [[ -f /etc/os-release ]]; then
        cat /etc/os-release
    else
        warning "No se pudo determinar la distribución."
    fi

fi

echo
echo "Kernel:"
uname -r

echo
echo "Kernel completo:"
uname -a

echo
echo "Arquitectura:"
uname -m


# 2. CPU


title "[2] CPU"

if command_exists lscpu; then

    echo "Modelo:"
    lscpu | awk -F: '/Model name/ {
        gsub(/^[ \t]+/, "", $2);
        print $2;
        exit
    }'

    echo
    echo "CPUs lógicas:"
    nproc

    echo
    echo "Núcleos físicos:"
    lscpu | awk -F: '/Core\(s\) per socket/ {
        gsub(/^[ \t]+/, "", $2);
        print $2;
        exit
    }'

    echo
    echo "Threads por núcleo:"
    lscpu | awk -F: '/Thread\(s\) per core/ {
        gsub(/^[ \t]+/, "", $2);
        print $2;
        exit
    }'

    echo
    echo "Socket(s):"
    lscpu | awk -F: '/Socket\(s\)/ {
        gsub(/^[ \t]+/, "", $2);
        print $2;
        exit
    }'

    echo
    echo "Arquitectura:"
    lscpu | awk -F: '/Architecture/ {
        gsub(/^[ \t]+/, "", $2);
        print $2;
        exit
    }'

else

    warning "lscpu no está disponible."

fi


# 3. RAM / SWAP


title "[3] MEMORIA"

echo "RAM:"

free -h

echo
echo "Swap:"

if swapon --show --noheadings 2>/dev/null | grep -q .; then
    swapon --show
else
    warning "No hay swap activa."
fi

echo
echo "ZRAM:"

if command_exists zramctl; then

    if zramctl --noheadings 2>/dev/null | grep -q .; then
        zramctl
    else
        echo "No hay dispositivos ZRAM activos."
    fi

else

    echo "zramctl no está disponible."

fi

echo
echo "Swappiness:"

if [[ -r /proc/sys/vm/swappiness ]]; then
    cat /proc/sys/vm/swappiness
else
    echo "No disponible."
fi

echo
echo "VFS cache pressure:"

if [[ -r /proc/sys/vm/vfs_cache_pressure ]]; then
    cat /proc/sys/vm/vfs_cache_pressure
else
    echo "No disponible."
fi


# 4. GPU


title "[4] GPU"

if command_exists lspci; then

    GPU_INFO="$(lspci | grep -Ei 'vga|3d|display' || true)"

    if [[ -n "$GPU_INFO" ]]; then
        echo "$GPU_INFO"
    else
        warning "No se detectó GPU mediante PCI."
    fi

else

    warning "lspci no está disponible."

fi

echo
echo "Controladores gráficos:"

if command_exists lspci; then

    lspci -k 2>/dev/null |
        grep -A3 -Ei 'vga|3d|display' || true

fi


# 5. Almacenamiento


title "[5] ALMACENAMIENTO"

echo "Dispositivos:"

if command_exists lsblk; then

    lsblk -o \
        NAME,SIZE,TYPE,FSTYPE,FSVER,LABEL,UUID,MOUNTPOINTS,ROTA,MODEL

else

    warning "lsblk no está disponible."

fi

echo
echo "Uso de sistemas de archivos:"

df -hT

echo
echo "Inodos:"

df -ih


# 6. Montajes


title "[6] SISTEMAS MONTADOS"

findmnt \
    -o TARGET,SOURCE,FSTYPE,OPTIONS \
    2>/dev/null || true


# 7. SSD / TRIM


title "[7] SSD / TRIM"

if command_exists systemctl; then

    echo "Estado de fstrim.timer:"

    systemctl is-enabled fstrim.timer 2>/dev/null ||
        echo "No habilitado"

    echo
    echo "Estado de ejecución:"

    systemctl is-active fstrim.timer 2>/dev/null ||
        echo "No activo"

    echo
    echo "Última ejecución registrada:"

    systemctl status fstrim.timer --no-pager 2>/dev/null |
        grep -E 'Active:|Trigger:' ||
        echo "No disponible."

else

    warning "systemctl no está disponible."

fi


# 8. Temperaturas


title "[8] TEMPERATURAS"

if command_exists sensors; then

    sensors

else

    warning "lm-sensors no está instalado."

    echo
    echo "No se instalará automáticamente."

fi


# 9. Batería


title "[9] BATERÍA"

BATTERY_FOUND=false

for battery in /sys/class/power_supply/BAT*; do

    if [[ -d "$battery" ]]; then

        BATTERY_FOUND=true

        echo "Dispositivo:"
        basename "$battery"

        if [[ -r "$battery/status" ]]; then
            echo "Estado: $(cat "$battery/status")"
        fi

        if [[ -r "$battery/capacity" ]]; then
            echo "Carga: $(cat "$battery/capacity")%"
        fi

        echo

    fi

done

if [[ "$BATTERY_FOUND" == false ]]; then
    echo "No se detectó batería."
fi


# 10. Red


title "[10] RED"

echo "Interfaces:"

if command_exists ip; then
    ip -brief address
else
    warning "ip no está disponible."
fi

echo
echo "Rutas:"

if command_exists ip; then
    ip route
fi

echo
echo "DNS:"

if command_exists resolvectl; then

    resolvectl status 2>/dev/null |
        grep -E 'DNS Servers|Current DNS Server' ||
        echo "No disponible."

elif [[ -f /etc/resolv.conf ]]; then

    grep -E '^nameserver' /etc/resolv.conf || true

else

    echo "No disponible."

fi

echo
echo "Conectividad:"

if command_exists ping; then

    if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
        success "IPv4: conectividad disponible."
    else
        warning "IPv4: no se pudo comprobar conectividad."
    fi

else

    warning "ping no está disponible."

fi


# 11. Uptime / carga


title "[11] ACTIVIDAD DEL SISTEMA"

echo "Uptime:"

uptime -p

echo
echo "Carga:"

uptime

echo
echo "Load average:"

cat /proc/loadavg


# 12. Procesos


title "[12] PROCESOS"

echo "Mayor consumo de CPU:"

ps -eo \
    pid,user,comm,%cpu,%mem \
    --sort=-%cpu |
    head -n 11

echo
echo "Mayor consumo de RAM:"

ps -eo \
    pid,user,comm,%cpu,%mem \
    --sort=-%mem |
    head -n 11


# 13. Servicios fallidos


title "[13] SERVICIOS FALLIDOS"

if command_exists systemctl; then

    FAILED_SERVICES="$(systemctl --failed --no-legend 2>/dev/null || true)"

    if [[ -n "$FAILED_SERVICES" ]]; then

        warning "Se encontraron servicios fallidos:"
        echo
        echo "$FAILED_SERVICES"

    else

        success "No hay servicios fallidos."

    fi

else

    warning "systemctl no está disponible."

fi


# 14. APT


title "[14] APT / PAQUETES"

if command_exists apt; then

    echo "APT:"
    apt --version | head -n 1

    echo
    echo "Paquetes instalados:"

    dpkg-query -W \
        -f='${binary:Package}\n' \
        2>/dev/null |
        wc -l

    echo
    echo "Paquetes pendientes de actualización:"

    if command_exists apt; then

        UPGRADABLE="$(apt list --upgradable 2>/dev/null |
            grep -v '^Listing...' || true)"

        if [[ -n "$UPGRADABLE" ]]; then
            echo "$UPGRADABLE"
        else
            success "No se detectaron paquetes actualizables."
        fi

    fi

else

    warning "APT no está disponible."

fi


# 15. Snap


title "[15] SNAP"

if command_exists snap; then

    echo "Versión:"
    snap version

    echo
    echo "Snaps instalados:"

    snap list 2>/dev/null || true

else

    echo "Snap no está instalado."

fi


# 16. Flatpak


title "[16] FLATPAK"

if command_exists flatpak; then

    echo "Versión:"
    flatpak --version

    echo
    echo "Aplicaciones instaladas:"

    flatpak list 2>/dev/null || true

else

    echo "Flatpak no está instalado."

fi


# 17. Docker


title "[17] DOCKER"

if command_exists docker; then

    echo "Versión:"
    docker --version

    echo
    echo "Estado del servicio:"

    if command_exists systemctl; then
        systemctl is-active docker 2>/dev/null ||
            echo "Docker no está activo."
    fi

    echo
    echo "Uso de Docker:"

    docker system df 2>/dev/null ||
        warning "No fue posible consultar Docker."

else

    echo "Docker no está instalado."

fi


# 18. Entorno gráfico


title "[18] ENTORNO GRÁFICO"

echo "Desktop:"
echo "${XDG_CURRENT_DESKTOP:-No detectado}"

echo
echo "Session:"
echo "${XDG_SESSION_DESKTOP:-No detectada}"

echo
echo "Tipo de sesión:"
echo "${XDG_SESSION_TYPE:-No detectado}"

echo
echo "Display server:"

if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    echo "Wayland"
elif [[ -n "${DISPLAY:-}" ]]; then
    echo "X11"
else
    echo "No detectado."
fi


# 19. Kernel / systemd


title "[19] KERNEL / SYSTEMD"

echo "Kernel:"
uname -r

echo
echo "Systemd:"

if command_exists systemctl; then
    systemctl --version | head -n 1
else
    echo "systemd no disponible."
fi

echo
echo "Boot actual:"

if command_exists systemd-analyze; then

    systemd-analyze

    echo
    echo "Servicios que más tardaron en iniciar:"

    systemd-analyze blame 2>/dev/null |
        head -n 10 || true

else

    echo "systemd-analyze no está disponible."

fi


# 20. Errores recientes


title "[20] ERRORES RECIENTES DEL SISTEMA"

if command_exists journalctl; then

    echo "Errores de prioridad alta desde el último boot:"

    journalctl \
        -b \
        -p 0..3 \
        --no-pager \
        -n 30 \
        2>/dev/null || true

else

    warning "journalctl no está disponible."

fi


# Resumen


title "RESUMEN"

echo
echo "Sistema:"
echo "$DISTRO_DESCRIPTION"

echo
echo "Kernel:"
uname -r

echo
echo "CPU:"
if command_exists lscpu; then
    lscpu | awk -F: '/Model name/ {
        gsub(/^[ \t]+/, "", $2);
        print $2;
        exit
    }'
fi

echo
echo "RAM:"
free -h | awk '/^Mem:/ {print $0}'

echo
echo "Disco /:"
df -h / | awk 'NR==2 {print $0}'

echo
echo "Uptime:"
uptime -p

echo
echo "Servicios fallidos:"

if command_exists systemctl; then

    FAILED_COUNT="$(
        systemctl --failed --no-legend 2>/dev/null |
        grep -c . || true
    )"

    if [[ "$FAILED_COUNT" -eq 0 ]]; then
        success "0"
    else
        warning "$FAILED_COUNT"
    fi

else

    echo "No disponible."

fi

echo
echo "ZRAM:"

if command_exists zramctl &&
   zramctl --noheadings 2>/dev/null | grep -q .; then
    success "Activa"
else
    echo "No activa/no disponible."
fi

echo
echo "TRIM:"

if systemctl is-enabled fstrim.timer >/dev/null 2>&1; then
    success "Habilitado"
else
    echo "No habilitado."
fi


# Final


separator
echo -e "${GREEN}SYSTEM INFORMATION COMPLETADO${RESET}"
separator

echo
echo "Este script solamente recopiló información."
echo "No se realizaron modificaciones en el sistema."

if [[ "$SAVE_REPORT" == true ]]; then

    echo
    echo "Reporte guardado en:"
    echo "$OUTPUT_FILE"

fi

echo
echo "Finalizado:"
echo "$(date)"

separator
