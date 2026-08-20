```bash
#!/usr/bin/env bash


# Ubuntu Toolkit - Docker Info
# Version: 0.1.0
#
# Descripción:
#   Muestra información detallada del entorno Docker.
#
# Filosofía:
#   - Solo lectura
#   - No elimina contenedores
#   - No elimina imágenes
#   - No elimina volúmenes
#   - No elimina redes
#   - No modifica Docker
#   - No ejecuta docker prune
#
# Uso:
#   ./info.sh
#   ./info.sh --help
#   ./info.sh --verbose


set -Eeuo pipefail

# ------------------------------------------------------------
# Configuración
# ------------------------------------------------------------

SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="0.1.0"

VERBOSE=false

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

section() {
    separator
    echo "$1"
    separator
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

show_help() {
    cat <<EOF

Docker Toolkit - Info

Versión: $SCRIPT_VERSION

Uso:

    ./$SCRIPT_NAME
    ./$SCRIPT_NAME --verbose
    ./$SCRIPT_NAME --help

Opciones:

    --verbose     Mostrar información adicional.
    --help        Mostrar esta ayuda.

Este script es SOLO de lectura.

No ejecuta:

    - docker rm
    - docker rmi
    - docker volume rm
    - docker network rm
    - docker system prune
    - docker image prune
    - docker container prune
    - docker volume prune

EOF
}

# ------------------------------------------------------------
# Manejo de errores
# ------------------------------------------------------------

on_error() {
    local exit_code=$?
    local line_number=$1

    error "Se produjo un error en la línea $line_number."
    error "Código de salida: $exit_code"

    exit "$exit_code"
}

trap 'on_error $LINENO' ERR

# ------------------------------------------------------------
# Argumentos
# ------------------------------------------------------------

for arg in "$@"; do

    case "$arg" in

        --verbose|-v)
            VERBOSE=true
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

# ------------------------------------------------------------
# Comprobar Docker
# ------------------------------------------------------------

if ! command_exists docker; then

    error "Docker no está instalado o no está disponible en PATH."

    echo
    echo "Puedes comprobarlo con:"
    echo
    echo "    command -v docker"

    exit 1

fi

# ------------------------------------------------------------
# Comprobar conexión con Docker daemon
# ------------------------------------------------------------

if ! docker info >/dev/null 2>&1; then

    error "No se pudo conectar con el Docker daemon."

    echo
    echo "Posibles causas:"
    echo
    echo "  - Docker no está ejecutándose."
    echo "  - El usuario no tiene permisos sobre Docker."
    echo "  - El servicio Docker tiene algún problema."

    echo
    echo "Puedes comprobar el servicio con:"
    echo
    echo "    systemctl status docker"

    echo
    echo "O probar:"
    echo
    echo "    sudo docker info"

    exit 1

fi

# ------------------------------------------------------------
# Encabezado
# ------------------------------------------------------------

clear

separator
echo "             UBUNTU TOOLKIT"
echo "             DOCKER INFO"
separator

echo
echo "Versión del script: $SCRIPT_VERSION"
echo "Fecha:              $(date)"


# 1. Información general


section "[1/9] INFORMACIÓN GENERAL"

echo
echo "Docker:"
docker --version

echo
echo "Docker Compose:"
if docker compose version >/dev/null 2>&1; then
    docker compose version
else
    echo "Docker Compose no disponible."
fi

echo
echo "Docker Root Directory:"
docker info --format '{{.DockerRootDir}}'

echo
echo "Server Version:"
docker info --format '{{.ServerVersion}}'

echo
echo "Storage Driver:"
docker info --format '{{.Driver}}'

echo
echo "Logging Driver:"
docker info --format '{{.LoggingDriver}}'

echo
echo "Cgroup Driver:"
docker info --format '{{.CgroupDriver}}'

echo
echo "Cgroup Version:"
docker info --format '{{.CgroupVersion}}'


# 2. Estado del servicio


section "[2/9] ESTADO DEL SERVICIO"

if command_exists systemctl; then

    echo
    echo "Docker service:"

    systemctl is-active docker 2>/dev/null || true

    echo
    echo "Docker enabled at boot:"

    systemctl is-enabled docker 2>/dev/null || true

    if [[ "$VERBOSE" == true ]]; then

        echo
        echo "Servicio Docker:"

        systemctl status docker \
            --no-pager \
            --full \
            | head -30 || true

    fi

else

    warning "systemctl no está disponible."

fi


# 3. Contenedores


section "[3/9] CONTENEDORES"

CONTAINER_TOTAL="$(
    docker ps -a --format '{{.ID}}' | wc -l
)"

CONTAINER_RUNNING="$(
    docker ps --format '{{.ID}}' | wc -l
)"

CONTAINER_STOPPED="$(
    docker ps -a \
        --filter "status=exited" \
        --format '{{.ID}}' \
        | wc -l
)"

echo
echo "Total:       $CONTAINER_TOTAL"
echo "Ejecutándose: $CONTAINER_RUNNING"
echo "Detenidos:    $CONTAINER_STOPPED"

echo
echo "Lista de contenedores:"

if [[ "$CONTAINER_TOTAL" -gt 0 ]]; then

    docker ps -a \
        --format 'table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'

else

    echo "No hay contenedores."

fi


# 4. Imágenes


section "[4/9] IMÁGENES"

IMAGE_COUNT="$(
    docker image ls -q | sort -u | wc -l
)"

echo
echo "Imágenes únicas: $IMAGE_COUNT"

echo
echo "Listado:"

if [[ "$IMAGE_COUNT" -gt 0 ]]; then

    docker image ls

else

    echo "No hay imágenes."

fi


# 5. Volúmenes


section "[5/9] VOLÚMENES"

VOLUME_COUNT="$(
    docker volume ls -q | wc -l
)"

echo
echo "Volúmenes: $VOLUME_COUNT"

if [[ "$VOLUME_COUNT" -gt 0 ]]; then

    echo
    docker volume ls

else

    echo
    echo "No hay volúmenes."

fi


# 6. Redes


section "[6/9] REDES"

NETWORK_COUNT="$(
    docker network ls -q | wc -l
)"

echo
echo "Redes: $NETWORK_COUNT"

echo
docker network ls


# 7. Uso de almacenamiento


section "[7/9] USO DE ALMACENAMIENTO"

echo
echo "Docker system df:"

docker system df

echo
echo "Detalle:"

docker system df -v


# 8. Recursos de contenedores


section "[8/9] RECURSOS DE CONTENEDORES"

if [[ "$CONTAINER_RUNNING" -gt 0 ]]; then

    echo
    echo "CPU / RAM / Red / Bloques:"

    docker stats --no-stream

else

    echo
    echo "No hay contenedores ejecutándose."

fi


# 9. Información detallada


section "[9/9] INFORMACIÓN DEL SISTEMA DOCKER"

if [[ "$VERBOSE" == true ]]; then

    echo
    docker info

else

    echo
    echo "Para obtener información completa:"
    echo
    echo "    ./$SCRIPT_NAME --verbose"

    echo
    echo "Información resumida:"

    docker info --format \
        'Containers: {{.Containers}}
Running: {{.ContainersRunning}}
Paused: {{.ContainersPaused}}
Stopped: {{.ContainersStopped}}
Images: {{.Images}}
Server Version: {{.ServerVersion}}
Storage Driver: {{.Driver}}
Docker Root Dir: {{.DockerRootDir}}
Operating System: {{.OperatingSystem}}
Architecture: {{.Architecture}}
CPUs: {{.NCPU}}
Total Memory: {{.MemTotal}}'

fi


# Resumen


section "RESUMEN"

echo
echo "Docker:"
docker --version

echo
echo "Contenedores:"
echo "  Total:       $CONTAINER_TOTAL"
echo "  Ejecutándose: $CONTAINER_RUNNING"
echo "  Detenidos:    $CONTAINER_STOPPED"

echo
echo "Imágenes:"
echo "  $IMAGE_COUNT"

echo
echo "Volúmenes:"
echo "  $VOLUME_COUNT"

echo
echo "Redes:"
echo "  $NETWORK_COUNT"

echo
echo "Docker storage:"
docker system df | tail -n +2

echo
success "Diagnóstico Docker completado."

echo
echo "IMPORTANTE:"
echo "Este script no modificó ni eliminó ningún recurso Docker."

separator
echo "UBUNTU TOOLKIT - DOCKER INFO $SCRIPT_VERSION"
separator
```
