#!/usr/bin/env bash

# ============================================================
# Ubuntu Toolkit - TXT to Markdown
# Version: 0.1.0
#
# Convierte archivos TXT a Markdown.
#
# Uso:
#
#   ./txt2md.sh archivo.txt
#   ./txt2md.sh archivo.txt archivo.md
#   ./txt2md.sh archivo.txt --preview
#   ./txt2md.sh archivo.txt --stdout
#   ./txt2md.sh --recursive ./documentos
#
# Características:
#   - Conversión TXT -> Markdown
#   - Preserva el contenido original
#   - Detección básica de títulos
#   - Detección de listas
#   - Detección de URLs
#   - Detección de bloques de código
#   - Preview
#   - stdout
#   - Conversión recursiva
#   - No sobrescribe archivos sin confirmación
#   - Compatible con espacios en nombres
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
# Variables
# ------------------------------------------------------------

INPUT_FILE=""
OUTPUT_FILE=""

PREVIEW=false
STDOUT_MODE=false
RECURSIVE=false
FORCE=false

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

confirm() {

    local prompt="$1"
    local answer

    read -rp "$prompt [y/N]: " answer

    [[ "$answer" =~ ^[Yy]$ ]]
}

# ------------------------------------------------------------
# Help
# ------------------------------------------------------------

show_help() {

    cat <<EOF

$SCRIPT_NAME v$SCRIPT_VERSION

Convierte archivos TXT a Markdown.

USO

    $SCRIPT_NAME archivo.txt

    $SCRIPT_NAME archivo.txt archivo.md

    $SCRIPT_NAME archivo.txt --preview

    $SCRIPT_NAME archivo.txt --stdout

    $SCRIPT_NAME --recursive ./documentos

OPCIONES

    -o, --output FILE
        Especificar archivo Markdown de salida.

    -p, --preview
        Mostrar una vista previa sin crear archivos.

    -s, --stdout
        Mostrar el Markdown por stdout.

    -r, --recursive DIR
        Convertir todos los archivos .txt encontrados
        dentro del directorio.

    -f, --force
        Sobrescribir archivos de salida existentes.

    -h, --help
        Mostrar esta ayuda.

EJEMPLOS

    $SCRIPT_NAME notas.txt

    $SCRIPT_NAME notas.txt notas.md

    $SCRIPT_NAME notas.txt --preview

    $SCRIPT_NAME notas.txt --stdout

    $SCRIPT_NAME notas.txt -o documento.md

    $SCRIPT_NAME --recursive ./notas

EOF
}

# ------------------------------------------------------------
# Validar archivo
# ------------------------------------------------------------

validate_input() {

    local file="$1"

    if [[ ! -f "$file" ]]; then

        error "El archivo no existe:"
        echo "$file"

        return 1

    fi

    if [[ ! -r "$file" ]]; then

        error "No se puede leer el archivo:"
        echo "$file"

        return 1

    fi

    return 0
}

# ------------------------------------------------------------
# Detectar extensión
# ------------------------------------------------------------

get_output_file() {

    local input="$1"

    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "$OUTPUT_FILE"
        return
    fi

    local base="${input%.*}"

    echo "${base}.md"
}

# ------------------------------------------------------------
# Escapar caracteres Markdown
# ------------------------------------------------------------

escape_markdown() {

    local text="$1"

    # No escapamos todo el Markdown porque queremos conservar
    # estructuras que el usuario ya haya escrito.

    printf '%s\n' "$text"
}

# ------------------------------------------------------------
# Detectar URL
# ------------------------------------------------------------

convert_url() {

    local line="$1"

    if [[ "$line" =~ ^(https?://[^[:space:]]+)$ ]]; then

        printf '<%s>\n' "$line"

    else

        printf '%s\n' "$line"

    fi
}

# ------------------------------------------------------------
# Detectar listas
# ------------------------------------------------------------

convert_list_item() {

    local line="$1"

    # Lista con guion
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.+)$ ]]; then

        printf '%s\n' "$line"
        return 0

    fi

    # Lista con asterisco
    if [[ "$line" =~ ^[[:space:]]*\*[[:space:]]+(.+)$ ]]; then

        printf '%s\n' "$line"
        return 0

    fi

    # Lista numérica
    if [[ "$line" =~ ^[[:space:]]*[0-9]+[.)][[:space:]]+(.+)$ ]]; then

        local content="${BASH_REMATCH[1]}"

        printf '%s\n' "$line"

        return 0

    fi

    return 1
}

# ------------------------------------------------------------
# Detectar títulos
# ------------------------------------------------------------

is_possible_title() {

    local line="$1"

    [[ -z "$line" ]] && return 1

    # No convertir líneas demasiado largas en títulos.
    if (( ${#line} > 80 )); then
        return 1
    fi

    # No convertir listas en títulos.
    if [[ "$line" =~ ^[[:space:]]*[-*] ]]; then
        return 1
    fi

    if [[ "$line" =~ ^[[:space:]]*[0-9]+[.)][[:space:]] ]]; then
        return 1
    fi

    # Detectar líneas tipo:
    #
    # Introducción:
    # Instalación:
    # Configuración:

    if [[ "$line" =~ ^[[:alnum:][:space:]_-]+:$ ]]; then
        return 0
    fi

    return 1
}

# ------------------------------------------------------------
# Convertir contenido
# ------------------------------------------------------------

convert_content() {

    local input="$1"

    local line
    local previous_blank=true
    local code_block=false

    while IFS= read -r line || [[ -n "$line" ]]; do

        # ----------------------------------------------------
        # Bloques de código
        # ----------------------------------------------------

        if [[ "$line" =~ ^[[:space:]]{4,}(.+)$ ]]; then

            if [[ "$code_block" == false ]]; then

                echo '```text'
                code_block=true

            fi

            echo "$line"

            previous_blank=false

            continue

        else

            if [[ "$code_block" == true ]]; then

                echo '```'

                code_block=false

                echo

            fi

        fi

        # ----------------------------------------------------
        # Línea vacía
        # ----------------------------------------------------

        if [[ -z "${line//[[:space:]]/}" ]]; then

            echo

            previous_blank=true

            continue

        fi

        # ----------------------------------------------------
        # Markdown ya existente
        # ----------------------------------------------------

        if [[ "$line" =~ ^#{1,6}[[:space:]] ]]; then

            echo "$line"

            previous_blank=false

            continue

        fi

        # ----------------------------------------------------
        # Títulos
        # ----------------------------------------------------

        if is_possible_title "$line"; then

            local title="${line%:}"

            if [[ "$previous_blank" == true ]]; then

                echo "## $title"

            else

                echo "### $title"

            fi

            previous_blank=false

            continue

        fi

        # ----------------------------------------------------
        # Listas
        # ----------------------------------------------------

        if convert_list_item "$line"; then

            previous_blank=false

            continue

        fi

        # ----------------------------------------------------
        # URLs
        # ----------------------------------------------------

        if [[ "$line" =~ ^https?:// ]]; then

            convert_url "$line"

            previous_blank=false

            continue

        fi

        # ----------------------------------------------------
        # Texto normal
        # ----------------------------------------------------

        escape_markdown "$line"

        previous_blank=false

    done < "$input"

    # Cerrar bloque de código si quedó abierto.
    if [[ "$code_block" == true ]]; then

        echo '```'

    fi
}

# ------------------------------------------------------------
# Crear Markdown
# ------------------------------------------------------------

convert_file() {

    local input="$1"
    local output="$2"

    validate_input "$input" || return 1

    echo
    info "Entrada:"
    echo "$input"

    echo
    info "Salida:"
    echo "$output"

    # --------------------------------------------------------
    # Preview
    # --------------------------------------------------------

    if [[ "$PREVIEW" == true ]]; then

        separator
        echo "PREVIEW"
        separator

        convert_content "$input"

        separator

        return 0

    fi

    # --------------------------------------------------------
    # stdout
    # --------------------------------------------------------

    if [[ "$STDOUT_MODE" == true ]]; then

        convert_content "$input"

        return 0

    fi

    # --------------------------------------------------------
    # Verificar archivo existente
    # --------------------------------------------------------

    if [[ -e "$output" && "$FORCE" != true ]]; then

        warning "El archivo de salida ya existe:"
        echo
        echo "$output"

        echo

        if ! confirm "¿Sobrescribirlo?"; then

            info "Conversión cancelada."

            return 0

        fi

    fi

    # --------------------------------------------------------
    # Crear directorio
    # --------------------------------------------------------

    local output_dir

    output_dir="$(dirname "$output")"

    mkdir -p "$output_dir"

    # --------------------------------------------------------
    # Archivo temporal
    # --------------------------------------------------------

    local temp_file

    temp_file="$(mktemp)"

    trap 'rm -f "$temp_file"' RETURN

    convert_content "$input" > "$temp_file"

    mv "$temp_file" "$output"

    success "Markdown creado:"
    echo
    echo "$output"

}

# ------------------------------------------------------------
# Conversión recursiva
# ------------------------------------------------------------

convert_recursive() {

    local directory="$1"

    if [[ ! -d "$directory" ]]; then

        error "El directorio no existe:"
        echo "$directory"

        return 1

    fi

    echo
    info "Buscando archivos TXT..."

    local found=false

    while IFS= read -r -d '' file; do

        found=true

        local output="${file%.txt}.md"

        convert_file "$file" "$output"

    done < <(
        find "$directory" \
            -type f \
            -iname '*.txt' \
            -print0
    )

    if [[ "$found" == false ]]; then

        warning "No se encontraron archivos TXT."

    fi

}

# ------------------------------------------------------------
# Modo interactivo
# ------------------------------------------------------------

interactive_mode() {

    separator
    echo "TXT → MARKDOWN"
    separator

    echo

    read -rp "Archivo TXT: " INPUT_FILE

    INPUT_FILE="${INPUT_FILE/#\~/$HOME}"

    validate_input "$INPUT_FILE" || exit 1

    echo

    local default_output

    default_output="$(get_output_file "$INPUT_FILE")"

    read -rp \
        "Archivo Markdown [$default_output]: " \
        OUTPUT_FILE

    if [[ -z "$OUTPUT_FILE" ]]; then
        OUTPUT_FILE="$default_output"
    fi

    OUTPUT_FILE="${OUTPUT_FILE/#\~/$HOME}"

    echo

    if confirm "¿Mostrar preview antes de convertir?"; then

        PREVIEW=true

        convert_file "$INPUT_FILE" "$OUTPUT_FILE"

        PREVIEW=false

    fi

    echo

    convert_file "$INPUT_FILE" "$OUTPUT_FILE"

}

# ------------------------------------------------------------
# Parsear argumentos
# ------------------------------------------------------------

if [[ "$#" -eq 0 ]]; then

    interactive_mode
    exit 0

fi

POSITIONAL=()

while [[ "$#" -gt 0 ]]; do

    case "$1" in

        -o|--output)

            if [[ "$#" -lt 2 ]]; then

                error "Falta el archivo de salida."

                exit 1

            fi

            OUTPUT_FILE="$2"

            shift 2
            ;;

        -p|--preview)

            PREVIEW=true

            shift
            ;;

        -s|--stdout)

            STDOUT_MODE=true

            shift
            ;;

        -r|--recursive)

            if [[ "$#" -lt 2 ]]; then

                error "Falta el directorio."

                exit 1

            fi

            RECURSIVE=true
            INPUT_FILE="$2"

            shift 2
            ;;

        -f|--force)

            FORCE=true

            shift
            ;;

        -h|--help)

            show_help

            exit 0
            ;;

        -*)

            error "Opción desconocida: $1"

            echo

            show_help

            exit 1
            ;;

        *)

            POSITIONAL+=("$1")

            shift
            ;;

    esac

done

# ------------------------------------------------------------
# Procesar entrada
# ------------------------------------------------------------

if [[ "$RECURSIVE" == true ]]; then

    convert_recursive "$INPUT_FILE"

    exit 0

fi

if [[ "${#POSITIONAL[@]}" -lt 1 ]]; then

    error "No se especificó un archivo TXT."

    echo

    show_help

    exit 1

fi

INPUT_FILE="${POSITIONAL[0]}"
INPUT_FILE="${INPUT_FILE/#\~/$HOME}"

if [[ "${#POSITIONAL[@]}" -ge 2 ]]; then

    OUTPUT_FILE="${POSITIONAL[1]}"
    OUTPUT_FILE="${OUTPUT_FILE/#\~/$HOME}"

fi

validate_input "$INPUT_FILE"

if [[ "$STDOUT_MODE" == false ]]; then

    if [[ -z "$OUTPUT_FILE" ]]; then

        OUTPUT_FILE="$(get_output_file "$INPUT_FILE")"

    fi

fi

convert_file "$INPUT_FILE" "$OUTPUT_FILE"