#!/usr/bin/env bash

# ============================================================
# Ubuntu Toolkit - Network Check
# Version: 0.1.0
#
# Ubuntu 24.04 LTS
#
# Filosofía:
#   - Solo diagnóstico
#   - No modificar configuración de red
#   - No cambiar DNS
#   - No reiniciar NetworkManager
#   - No modificar rutas
#   - No desconectar interfaces
#   - No realizar cambios permanentes
#
# Uso:
#   ./network-check.sh
#   ./network-check.sh --verbose
#   ./network-check.sh --save
#   ./network-check.sh --help
#
# Código de salida:
#   0 = red funcionando correctamente
#   1 = se detectó algún problema
#   2 = error de ejecución / dependencia
# ============================================================

set -Eeuo pipefail

# ------------------------------------------------------------
# Configuración
# ------------------------------------------------------------

SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="0.1.0"

VERBOSE=false
SAVE_REPORT=false

TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
REPORT_FILE="network-check-$TIMESTAMP.txt"

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
# Estado
# ------------------------------------------------------------

CHECKS_OK=0
CHECKS_WARN=0
CHECKS_FAIL=0

# ------------------------------------------------------------
# Funciones
# ------------------------------------------------------------

info() {
    echo -e "${CYAN}[INFO]${RESET} $*"
}

success() {
    echo -e "${GREEN}[ OK ]${RESET} $*"
    ((CHECKS_OK+=1))
}

warning() {
    echo -e "${YELLOW}[WARN]${RESET} $*"
    ((CHECKS_WARN+=1))
}

failure() {
    echo -e "${RED}[FAIL]${RESET} $*"
    ((CHECKS_FAIL+=1))
}

separator() {
    echo
    echo "============================================================"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

show_help() {
    cat <<EOF

Ubuntu Toolkit - Network Check

Versión: $SCRIPT_VERSION

Uso:

    ./$SCRIPT_NAME
    ./$SCRIPT_NAME --verbose
    ./$SCRIPT_NAME --save
    ./$SCRIPT_NAME --help

Opciones:

    --verbose     Mostrar información adicional.
    --save        Guardar el diagnóstico en un archivo.
    --help        Mostrar esta ayuda.

El script NO:

    - modifica DNS
    - modifica NetworkManager
    - modifica /etc/resolv.conf
    - modifica rutas
    - reinicia servicios
    - desconecta interfaces
    - modifica firewall
    - cambia configuración permanente

Código de salida:

    0    Red funcionando correctamente
    1    Se detectó algún problema
    2    Error de ejecución o dependencia

EOF
}

# ------------------------------------------------------------
# Argumentos
# ------------------------------------------------------------

for arg in "$@"; do
    case "$arg" in

        --verbose)
            VERBOSE=true
            ;;

        --save)
            SAVE_REPORT=true
            ;;

        --help|-h)
            show_help
            exit 0
            ;;

        *)
            echo "Argumento desconocido: $arg"
            echo
            show_help
            exit 2
            ;;

    esac
done

# ------------------------------------------------------------
# Dependencias
# ------------------------------------------------------------

REQUIRED_COMMANDS=(
    ip
    ping
    getent
    awk
    grep
    sed
)

MISSING_COMMANDS=()

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command_exists "$cmd"; then
        MISSING_COMMANDS+=("$cmd")
    fi
done

if (( ${#MISSING_COMMANDS[@]} > 0 )); then

    echo
    echo "ERROR: faltan comandos necesarios:"
    printf '  - %s\n' "${MISSING_COMMANDS[@]}"
    echo

    exit 2
fi

# ------------------------------------------------------------
# Sistema
# ------------------------------------------------------------

if command_exists lsb_release; then
    DISTRO="$(lsb_release -sd 2>/dev/null || true)"
else
    DISTRO="Linux"
fi

HOSTNAME_VALUE="$(hostname 2>/dev/null || echo "unknown")"

# ------------------------------------------------------------
# Encabezado
# ------------------------------------------------------------

clear

separator
echo "             UBUNTU TOOLKIT"
echo "             NETWORK CHECK"
separator

echo
echo "Versión:    $SCRIPT_VERSION"
echo "Sistema:    $DISTRO"
echo "Hostname:   $HOSTNAME_VALUE"
echo "Fecha:      $(date)"

if [[ "$VERBOSE" == true ]]; then
    echo
    info "Modo verbose activado."
fi

if [[ "$SAVE_REPORT" == true ]]; then
    echo
    info "El reporte se guardará en:"
    echo "$REPORT_FILE"

    exec > >(tee "$REPORT_FILE") 2>&1
fi

# ------------------------------------------------------------
# 1. Interfaces de red
# ------------------------------------------------------------

separator
echo "[1/10] INTERFACES DE RED"
separator

INTERFACES="$(ip -o link show | awk -F': ' '{print $2}' | sed 's/@.*//')"

if [[ -z "$INTERFACES" ]]; then

    failure "No se encontraron interfaces de red."

else

    echo
    echo "Interfaces detectadas:"
    echo

    while IFS= read -r interface; do

        [[ -z "$interface" ]] && continue

        STATE="$(cat "/sys/class/net/$interface/operstate" 2>/dev/null || echo "unknown")"

        case "$STATE" in
            up)
                echo -e "  ${GREEN}UP${RESET}      $interface"
                ;;

            down)
                echo -e "  ${YELLOW}DOWN${RESET}    $interface"
                ;;

            *)
                echo -e "  ${YELLOW}$STATE${RESET}    $interface"
                ;;
        esac

    done <<< "$INTERFACES"

fi

# ------------------------------------------------------------
# 2. Interfaz utilizada para Internet
# ------------------------------------------------------------

separator
echo "[2/10] INTERFAZ PRINCIPAL"
separator

DEFAULT_ROUTE="$(ip route show default 2>/dev/null | head -n 1 || true)"

if [[ -z "$DEFAULT_ROUTE" ]]; then

    failure "No existe una ruta IPv4 por defecto."

    DEFAULT_INTERFACE=""

else

    DEFAULT_INTERFACE="$(awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' <<< "$DEFAULT_ROUTE" | head -n 1)"

    echo
    echo "Ruta por defecto:"
    echo "$DEFAULT_ROUTE"

    echo

    if [[ -n "$DEFAULT_INTERFACE" ]]; then
        success "Interfaz principal: $DEFAULT_INTERFACE"
    else
        warning "No se pudo determinar la interfaz principal."
    fi

fi

# ------------------------------------------------------------
# 3. Direcciones IP
# ------------------------------------------------------------

separator
echo "[3/10] DIRECCIONES IP"
separator

if [[ -n "${DEFAULT_INTERFACE:-}" ]]; then

    echo
    echo "IPv4:"
    ip -4 addr show dev "$DEFAULT_INTERFACE" 2>/dev/null |
        awk '/inet / {print "  " $2}'

    echo
    echo "IPv6:"
    ip -6 addr show dev "$DEFAULT_INTERFACE" 2>/dev/null |
        awk '/inet6 / {print "  " $2}'

else

    warning "No se puede determinar la interfaz principal."

fi

# ------------------------------------------------------------
# 4. Gateway
# ------------------------------------------------------------

separator
echo "[4/10] GATEWAY"
separator

GATEWAY="$(ip route show default 2>/dev/null |
    awk '/default/ {print $3; exit}')"

if [[ -z "$GATEWAY" ]]; then

    failure "No se encontró gateway IPv4."

else

    echo
    echo "Gateway: $GATEWAY"

    if ping -c 2 -W 2 "$GATEWAY" >/dev/null 2>&1; then

        success "Gateway accesible."

    else

        failure "No se puede alcanzar el gateway."

    fi

fi

# ------------------------------------------------------------
# 5. DNS
# ------------------------------------------------------------

separator
echo "[5/10] DNS"
separator

DNS_SERVERS=()

if command_exists resolvectl; then

    while IFS= read -r dns; do

        [[ -z "$dns" ]] && continue

        DNS_SERVERS+=("$dns")

    done < <(
        resolvectl dns 2>/dev/null |
        awk '
        {
            for (i=2; i<=NF; i++)
                print $i
        }
        ' |
        sort -u
    )

fi

if (( ${#DNS_SERVERS[@]} == 0 )); then

    if [[ -f /etc/resolv.conf ]]; then

        while IFS= read -r dns; do
            DNS_SERVERS+=("$dns")
        done < <(
            awk '/^nameserver / {print $2}' /etc/resolv.conf
        )

    fi

fi

if (( ${#DNS_SERVERS[@]} == 0 )); then

    warning "No se encontraron servidores DNS."

else

    echo
    echo "Servidores DNS:"

    printf '  %s\n' "${DNS_SERVERS[@]}"

    echo

    if getent hosts archive.ubuntu.com >/dev/null 2>&1; then

        success "Resolución DNS funcionando."

    else

        failure "La resolución DNS no funciona."

    fi

fi

# ------------------------------------------------------------
# 6. Conectividad IPv4
# ------------------------------------------------------------

separator
echo "[6/10] CONECTIVIDAD IPv4"
separator

IPV4_TARGET="1.1.1.1"

echo
echo "Destino: $IPV4_TARGET"

if ping -4 -c 3 -W 3 "$IPV4_TARGET" >/dev/null 2>&1; then

    success "Conectividad IPv4 funcionando."

    echo
    echo "Latencia:"

    ping -4 -c 4 -W 3 "$IPV4_TARGET" 2>/dev/null |
        tail -n 2 || true

else

    failure "No hay conectividad IPv4 con $IPV4_TARGET."

fi

# ------------------------------------------------------------
# 7. Conectividad IPv6
# ------------------------------------------------------------

separator
echo "[7/10] CONECTIVIDAD IPv6"
separator

IPV6_TARGET="2606:4700:4700::1111"

if ip -6 route show default >/dev/null 2>&1; then

    echo
    echo "Destino: $IPV6_TARGET"

    if ping -6 -c 3 -W 3 "$IPV6_TARGET" >/dev/null 2>&1; then

        success "Conectividad IPv6 funcionando."

    else

        warning "IPv6 está configurado pero no responde."

    fi

else

    warning "No existe una ruta IPv6 por defecto."

fi

# ------------------------------------------------------------
# 8. Prueba DNS + Internet
# ------------------------------------------------------------

separator
echo "[8/10] PRUEBA DNS + INTERNET"
separator

TEST_DOMAINS=(
    "ubuntu.com"
    "github.com"
    "google.com"
)

for domain in "${TEST_DOMAINS[@]}"; do

    echo
    echo "Probando: $domain"

    if getent hosts "$domain" >/dev/null 2>&1; then

        success "$domain resuelve correctamente."

    else

        failure "$domain no pudo resolverse."

    fi

done

# ------------------------------------------------------------
# 9. NetworkManager
# ------------------------------------------------------------

separator
echo "[9/10] NETWORKMANAGER"
separator

if command_exists systemctl; then

    if systemctl is-active --quiet NetworkManager; then

        success "NetworkManager está activo."

    else

        warning "NetworkManager no está activo."

    fi

fi

if command_exists nmcli; then

    echo
    echo "Estado general:"
    nmcli general status 2>/dev/null || true

    if [[ "$VERBOSE" == true ]]; then

        echo
        echo "Dispositivos:"
        nmcli device status 2>/dev/null || true

        echo
        echo "Conexiones activas:"
        nmcli connection show --active 2>/dev/null || true

    fi

else

    warning "nmcli no está disponible."

fi

# ------------------------------------------------------------
# 10. Rutas y resumen
# ------------------------------------------------------------

separator
echo "[10/10] RUTAS DE RED"
separator

echo
echo "IPv4:"
ip -4 route show

if [[ "$VERBOSE" == true ]]; then

    echo
    echo "IPv6:"
    ip -6 route show

    echo
    echo "Tabla de vecinos:"
    ip neigh show

fi

# ------------------------------------------------------------
# Resumen
# ------------------------------------------------------------

separator
echo "RESUMEN DEL DIAGNÓSTICO"
separator

echo
echo "Comprobaciones correctas: $CHECKS_OK"
echo "Advertencias:             $CHECKS_WARN"
echo "Fallos:                   $CHECKS_FAIL"

echo

if (( CHECKS_FAIL == 0 && CHECKS_WARN == 0 )); then

    echo -e "${GREEN}✓ RED FUNCIONANDO CORRECTAMENTE${RESET}"

elif (( CHECKS_FAIL == 0 )); then

    echo -e "${YELLOW}⚠ RED FUNCIONANDO CON ADVERTENCIAS${RESET}"

else

    echo -e "${RED}✗ SE DETECTARON PROBLEMAS DE RED${RESET}"

fi

echo
echo "Este script no modificó:"
echo
echo "  - DNS"
echo "  - NetworkManager"
echo "  - /etc/resolv.conf"
echo "  - rutas"
echo "  - interfaces"
echo "  - firewall"
echo "  - configuración permanente"

if [[ "$SAVE_REPORT" == true ]]; then

    echo
    echo "Reporte:"
    echo "$REPORT_FILE"

fi

echo
echo "Finalizado:"
echo "$(date)"

separator
echo "UBUNTU TOOLKIT - NETWORK CHECK $SCRIPT_VERSION"
separator

# ------------------------------------------------------------
# Código de salida
# ------------------------------------------------------------

if (( CHECKS_FAIL > 0 )); then
    exit 1
fi

exit 0

