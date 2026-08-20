#!/usr/bin/env bash

# ============================================================
# Ubuntu Toolkit - Disk Check
# Version: 0.1.0
#
# Ubuntu 24.04 LTS
#
# Filosofía:
#   - Solo diagnóstico
#   - No borrar archivos
#   - No modificar particiones
#   - No montar/desmontar dispositivos
#   - No reparar sistemas de archivos
#   - No modificar configuraciones
#   - No ejecutar operaciones destructivas
#
# Uso:
#   ./disk-check.sh
#   ./disk-check.sh --save
#   ./disk-check.sh --output reporte.txt
#   ./disk-check.sh --path /home
#   ./disk-check.sh --help
# ============================================================

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="0.1.0"

SAVE_REPORT=false
OUTPUT_FILE=""
SCAN_PATH="/"


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

Ubuntu Toolkit - Disk Check

Versión: $SCRIPT_VERSION

Herramienta de diagnóstico de almacenamiento.

Uso:

    ./$SCRIPT_NAME
    ./$SCRIPT_NAME --save
    ./$SCRIPT_NAME --output archivo.txt
    ./$SCRIPT_NAME --path /home
    ./$SCRIPT_NAME --help

Opciones:

    --save              Guardar reporte automáticamente.
    --output <archivo>  Guardar reporte en una ruta específica.
    --path <ruta>       Analizar una ruta específica.
    --help              Mostrar esta ayuda.

Ejemplos:

    ./$SCRIPT_NAME
    ./$SCRIPT_NAME --path /home
    ./$SCRIPT_NAME --path /var
    ./$SCRIPT_NAME --save

El script NO:

    - elimina archivos
    - modifica particiones
    - formatea discos
    - monta dispositivos
    - desmonta dispositivos
    - repara sistemas de archivos
    - modifica /etc/fstab
    - modifica Docker

EOF
}

on_error() {
    local exit_code=$?
    local line_number="$1"

    error "Se produjo un error en la línea $line_number."
    error "Código de salida: $exit_code"

    if [[ -n "${OUTPUT_FILE:-}" ]]; then
        error "El reporte puede estar incompleto."
    fi

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

        --path)

            if [[ $# -lt 2 ]]; then
                error "Falta la ruta después de --path."
                exit 1
            fi

            SCAN_PATH="$2"
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


# Validación de ruta


if [[ ! -d "$SCAN_PATH" ]]; then
    error "La ruta no existe o no es un directorio:"
    error "$SCAN_PATH"
    exit 1
fi

SCAN_PATH="$(realpath "$SCAN_PATH")"


# Reporte


if [[ "$SAVE_REPORT" == true && -z "$OUTPUT_FILE" ]]; then

    REPORT_DIR="${HOME}/ubuntu-toolkit-reports"

    mkdir -p "$REPORT_DIR"

    OUTPUT_FILE="$REPORT_DIR/disk-check-$(date '+%Y%m%d_%H%M%S').txt"

fi


# Encabezado


clear

separator
echo -e "${MAGENTA}           UBUNTU TOOLKIT${RESET}"
echo -e "${MAGENTA}              DISK CHECK${RESET}"
separator

echo
echo "Versión: $SCRIPT_VERSION"
echo "Fecha:   $(date)"
echo "Usuario: $(whoami)"
echo "Ruta:    $SCAN_PATH"

if [[ "$SAVE_REPORT" == true ]]; then
    echo "Reporte: $OUTPUT_FILE"
fi

echo
info "Modo diagnóstico: solo lectura."


# 1. Resumen de almacenamiento


title "[1] RESUMEN DE ALMACENAMIENTO"

echo
echo "Sistemas de archivos:"

df -hT

echo
echo "Inodos:"

df -ih


# 2. Dispositivos físicos


title "[2] DISPOSITIVOS DE ALMACENAMIENTO"

if command_exists lsblk; then

    lsblk -e7 -o \
        NAME,PATH,SIZE,TYPE,FSTYPE,FSVER,LABEL,UUID,MOUNTPOINTS,ROTA,MODEL

else

    warning "lsblk no está disponible."

fi


# 3. Discos montados


title "[3] SISTEMAS DE ARCHIVOS MONTADOS"

if command_exists findmnt; then

    findmnt \
        -o TARGET,SOURCE,FSTYPE,SIZE,USED,AVAIL,USE%,OPTIONS \
        2>/dev/null || true

else

    warning "findmnt no está disponible."

fi


# 4. Uso de la raíz


title "[4] USO DE /"

ROOT_USAGE="$(df -P / | awk 'NR==2 {print $5}')"
ROOT_USAGE_VALUE="${ROOT_USAGE%\%}"

echo
echo "Uso actual de /:"
echo "$ROOT_USAGE"

if [[ "$ROOT_USAGE_VALUE" -ge 95 ]]; then

    warning "CRÍTICO: el sistema tiene menos de 5% de espacio disponible."

elif [[ "$ROOT_USAGE_VALUE" -ge 85 ]]; then

    warning "ALERTA: el sistema utiliza más del 85% del almacenamiento."

elif [[ "$ROOT_USAGE_VALUE" -ge 70 ]]; then

    warning "ATENCIÓN: el sistema utiliza más del 70% del almacenamiento."

else

    success "Uso del almacenamiento dentro de un rango normal."

fi


# 5. Directorios principales


title "[5] DIRECTORIOS QUE MÁS OCUPAN"

echo
echo "Analizando:"
echo "$SCAN_PATH"

echo
echo "Principales directorios:"

if command_exists du; then

    du -xhd1 "$SCAN_PATH" 2>/dev/null |
        sort -h -r |
        head -n 20 || true

else

    warning "du no está disponible."

fi


# 6. Directorios críticos de Ubuntu


title "[6] DIRECTORIOS IMPORTANTES"

DIRECTORIES=(
    "/home"
    "/var"
    "/var/log"
    "/var/cache"
    "/var/lib"
    "/tmp"
    "/usr"
    "/opt"
)

for directory in "${DIRECTORIES[@]}"; do

    if [[ -d "$directory" ]]; then

        SIZE="$(du -shx "$directory" 2>/dev/null |
            awk '{print $1}' || echo "N/A")"

        printf "%-20s %s\n" "$directory" "$SIZE"

    fi

done


# 7. /home


title "[7] USO DE /HOME"

if [[ -d "/home" ]]; then

    echo
    echo "Usuarios:"

    du -xhd1 /home 2>/dev/null |
        sort -h -r |
        head -n 20 || true

else

    echo "/home no existe."

fi


# 8. /var


title "[8] USO DE /VAR"

if [[ -d "/var" ]]; then

    echo
    echo "Principales directorios dentro de /var:"

    du -xhd1 /var 2>/dev/null |
        sort -h -r |
        head -n 20 || true

else

    echo "/var no existe."

fi


# 9. Logs


title "[9] LOGS"

if [[ -d "/var/log" ]]; then

    echo
    echo "Tamaño total de /var/log:"

    du -shx /var/log 2>/dev/null || true

    echo
    echo "Logs más grandes:"

    find /var/log \
        -xdev \
        -type f \
        -printf '%s\t%p\n' \
        2>/dev/null |
        sort -nr |
        head -n 20 |
        awk '{
            size=$1;
            $1="";
            sub(/^[ \t]+/, "", $0);

            if (size >= 1073741824)
                printf "%.2f GB\t%s\n", size/1073741824, $0;
            else if (size >= 1048576)
                printf "%.2f MB\t%s\n", size/1048576, $0;
            else if (size >= 1024)
                printf "%.2f KB\t%s\n", size/1024, $0;
            else
                printf "%d B\t%s\n", size, $0;
        }' || true

else

    echo "/var/log no existe."

fi


# 10. Caché de APT


title "[10] CACHÉ DE APT"

APT_CACHE="/var/cache/apt/archives"

if [[ -d "$APT_CACHE" ]]; then

    echo
    echo "Tamaño:"
    du -sh "$APT_CACHE" 2>/dev/null || true

    echo
    echo "Paquetes almacenados:"

    find "$APT_CACHE" \
        -maxdepth 1 \
        -type f \
        -name '*.deb' \
        2>/dev/null |
        wc -l

else

    echo "Caché de APT no encontrada."

fi


# 11. Docker


title "[11] DOCKER"

if command_exists docker; then

    echo
    echo "Docker:"
    docker --version

    echo
    echo "Uso de Docker:"

    docker system df 2>/dev/null ||
        warning "No fue posible consultar Docker."

else

    echo "Docker no está instalado."

fi


# 12. Snap


title "[12] SNAP"

if [[ -d "/var/lib/snapd" ]]; then

    echo
    echo "Tamaño de /var/lib/snapd:"

    du -sh /var/lib/snapd 2>/dev/null || true

    echo
    echo "Revisando snaps instalados:"

    if command_exists snap; then
        snap list 2>/dev/null || true
    fi

else

    echo "Snap no está instalado."

fi


# 13. Flatpak


title "[13] FLATPAK"

if command_exists flatpak; then

    echo
    echo "Instalaciones Flatpak:"

    flatpak list --columns=application,size 2>/dev/null ||
        flatpak list 2>/dev/null ||
        true

else

    echo "Flatpak no está instalado."

fi


# 14. Archivos grandes


title "[14] ARCHIVOS GRANDES"

echo
echo "Buscando archivos mayores de 1 GB dentro de:"
echo "$SCAN_PATH"

echo
echo "Esto puede tardar dependiendo del tamaño del disco."

if command_exists find; then

    find "$SCAN_PATH" \
        -xdev \
        -type f \
        -size +1G \
        -printf '%s\t%p\n' \
        2>/dev/null |
        sort -nr |
        head -n 30 |
        awk '{
            size=$1;
            $1="";
            sub(/^[ \t]+/, "", $0);

            if (size >= 1073741824)
                printf "%.2f GB\t%s\n", size/1073741824, $0;
            else
                printf "%.2f MB\t%s\n", size/1048576, $0;
        }' || true

else

    warning "find no está disponible."

fi


# 15. Archivos grandes en HOME


title "[15] ARCHIVOS GRANDES EN HOME"

if [[ -d "$HOME" ]]; then

    echo
    echo "Archivos mayores de 500 MB:"

    find "$HOME" \
        -xdev \
        -type f \
        -size +500M \
        -printf '%s\t%p\n' \
        2>/dev/null |
        sort -nr |
        head -n 30 |
        awk '{
            size=$1;
            $1="";
            sub(/^[ \t]+/, "", $0);

            if (size >= 1073741824)
                printf "%.2f GB\t%s\n", size/1073741824, $0;
            else
                printf "%.2f MB\t%s\n", size/1048576, $0;
        }' || true

else

    warning "No se pudo analizar HOME."

fi


# 16. Archivos eliminados pero abiertos


title "[16] ARCHIVOS ELIMINADOS PERO ABIERTOS"

if command_exists lsof; then

    echo
    echo "Buscando archivos eliminados que todavía consumen espacio..."

    DELETED_FILES="$(
        lsof +L1 2>/dev/null |
        head -n 30 || true
    )"

    if [[ -n "$DELETED_FILES" ]]; then

        echo "$DELETED_FILES"

        echo
        warning "Estos archivos pueden seguir ocupando espacio hasta que"
        warning "el proceso que los mantiene abiertos sea reiniciado."

    else

        success "No se detectaron archivos eliminados abiertos."

    fi

else

    warning "lsof no está instalado."

    echo
    echo "No se instalará automáticamente."

fi


# 17. Inodos


title "[17] INODOS"

df -ih

echo
echo "Particiones con posible presión de inodos:"

while read -r filesystem size used available percentage mountpoint; do

    if [[ "$percentage" =~ ^([0-9]+)%$ ]]; then

        value="${BASH_REMATCH[1]}"

        if [[ "$value" -ge 85 ]]; then
            warning "$mountpoint utiliza $percentage de sus inodos."
        fi

    fi

done < <(df -Pih | tail -n +2)


# 18. TRIM


title "[18] SSD / TRIM"

if command_exists systemctl; then

    echo "fstrim.timer:"

    if systemctl is-enabled fstrim.timer >/dev/null 2>&1; then
        success "Habilitado."
    else
        warning "No está habilitado."
    fi

    echo
    echo "Último estado:"

    systemctl status fstrim.timer \
        --no-pager \
        2>/dev/null |
        grep -E 'Active:|Trigger:' ||
        echo "No disponible."

else

    warning "systemctl no está disponible."

fi


# 19. Resumen de almacenamiento


title "[19] RESUMEN"

ROOT_LINE="$(df -hP / | awk 'NR==2')"

ROOT_SIZE="$(awk '{print $2}' <<< "$ROOT_LINE")"
ROOT_USED="$(awk '{print $3}' <<< "$ROOT_LINE")"
ROOT_AVAILABLE="$(awk '{print $4}' <<< "$ROOT_LINE")"
ROOT_PERCENT="$(awk '{print $5}' <<< "$ROOT_LINE")"

echo
echo "Partición /:"
echo "  Total:       $ROOT_SIZE"
echo "  Utilizado:   $ROOT_USED"
echo "  Disponible:  $ROOT_AVAILABLE"
echo "  Uso:         $ROOT_PERCENT"

echo
echo "Estado:"

ROOT_VALUE="${ROOT_PERCENT%\%}"

if [[ "$ROOT_VALUE" -ge 95 ]]; then

    warning "CRÍTICO"

elif [[ "$ROOT_VALUE" -ge 85 ]]; then

    warning "ALTO"

elif [[ "$ROOT_VALUE" -ge 70 ]]; then

    warning "MODERADO"

else

    success "NORMAL"

fi

echo
echo "Docker:"

if command_exists docker; then
    success "Detectado"
else
    echo "No instalado"
fi

echo
echo "APT cache:"

if [[ -d "$APT_CACHE" ]]; then
    du -sh "$APT_CACHE" 2>/dev/null || true
else
    echo "No disponible."
fi

echo
echo "Logs:"

if [[ -d "/var/log" ]]; then
    du -sh /var/log 2>/dev/null || true
else
    echo "No disponible."
fi

echo
echo "Inodos:"

df -ih / | awk 'NR==2 {print "  Uso: " $5}'


# Final


separator
echo -e "${GREEN}DISK CHECK COMPLETADO${RESET}"
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

