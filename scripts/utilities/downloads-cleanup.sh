#!/usr/bin/env bash

# ============================================================
# Ubuntu Toolkit - Downloads Cleanup
# Version: 0.1.0
#
# Herramienta segura para analizar y limpiar ~/Downloads.
#
# Filosofía:
#   - Safe by default
#   - No eliminar automáticamente
#   - Nunca salir de ~/Downloads
#   - Confirmar operaciones destructivas
#   - Permitir dry-run
#   - Preferir cuarentena sobre eliminación
#   - Soportar nombres con espacios
#   - No tocar archivos ocultos automáticamente
#
# Funciones:
#   1. Analizar Downloads
#   2. Ver archivos grandes
#   3. Ver archivos antiguos
#   4. Ver archivos por categoría
#   5. Limpiar instaladores
#   6. Limpiar archivos comprimidos
#   7. Limpiar documentos
#   8. Mover archivos a cuarentena
#   9. Eliminar archivos seleccionados
#  10. Mostrar uso de espacio
#
# Uso:
#
#   ./downloads-cleanup.sh
#   ./downloads-cleanup.sh --dry-run
#   ./downloads-cleanup.sh --help
#
# ============================================================

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="0.1.0"

# ------------------------------------------------------------
# Configuración
# ------------------------------------------------------------

DOWNLOADS_DIR="${DOWNLOADS_DIR:-$HOME/Downloads}"

TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"

QUARANTINE_DIR="$DOWNLOADS_DIR/.ubuntu-toolkit-quarantine"
LOG_FILE="$HOME/downloads-cleanup-$TIMESTAMP.log"

DRY_RUN=false

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

# ------------------------------------------------------------
# Manejo de errores
# ------------------------------------------------------------

on_error() {

    local exit_code=$?
    local line_number="$1"

    echo

    error "Se produjo un error."
    error "Línea: $line_number"
    error "Código: $exit_code"

    echo
    error "Log:"
    echo "$LOG_FILE"

    exit "$exit_code"
}

trap 'on_error $LINENO' ERR

# ------------------------------------------------------------
# Ayuda
# ------------------------------------------------------------

show_help() {

    cat <<EOF

Ubuntu Toolkit - Downloads Cleanup

Versión: $SCRIPT_VERSION

Uso:

    ./$SCRIPT_NAME
    ./$SCRIPT_NAME --dry-run
    ./$SCRIPT_NAME --help

Opciones:

    --dry-run     Analiza y muestra acciones sin modificar archivos.
    --help        Mostrar esta ayuda.

Directorio analizado:

    $DOWNLOADS_DIR

Características:

    - Analizar archivos
    - Detectar archivos grandes
    - Detectar archivos antiguos
    - Clasificar archivos
    - Mover archivos a cuarentena
    - Eliminar archivos seleccionados
    - No tocar archivos fuera de Downloads
    - No tocar archivos ocultos automáticamente

EOF
}

# ------------------------------------------------------------
# Argumentos
# ------------------------------------------------------------

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

# ------------------------------------------------------------
# Verificar Downloads
# ------------------------------------------------------------

if [[ ! -d "$DOWNLOADS_DIR" ]]; then

    warning "La carpeta Downloads no existe:"
    echo
    echo "$DOWNLOADS_DIR"

    echo

    if confirm "¿Deseas crearla?"; then

        mkdir -p "$DOWNLOADS_DIR"

        success "Directorio creado."

    else

        exit 0

    fi

fi

# ------------------------------------------------------------
# Log
# ------------------------------------------------------------

if [[ "$DRY_RUN" == false ]]; then

    touch "$LOG_FILE"

    exec > >(tee -a "$LOG_FILE") 2>&1

fi

# ------------------------------------------------------------
# Seguridad
# ------------------------------------------------------------

is_inside_downloads() {

    local target="$1"

    local downloads_real
    local target_real

    downloads_real="$(realpath -e "$DOWNLOADS_DIR")" || return 1

    target_real="$(realpath -e "$target")" || return 1

    [[ "$target_real" == "$downloads_real"/* ]]

}

safe_file() {

    local target="$1"

    if [[ ! -e "$target" ]]; then
        return 1
    fi

    if ! is_inside_downloads "$target"; then

        error "Operación bloqueada fuera de Downloads:"
        echo "$target"

        return 1

    fi

    return 0

}

# ------------------------------------------------------------
# Crear cuarentena
# ------------------------------------------------------------

create_quarantine() {

    if [[ "$DRY_RUN" == true ]]; then

        echo "[DRY-RUN] mkdir -p \"$QUARANTINE_DIR\""

        return

    fi

    mkdir -p "$QUARANTINE_DIR"

}

# ------------------------------------------------------------
# Tamaño del directorio
# ------------------------------------------------------------

get_downloads_size() {

    du -sh "$DOWNLOADS_DIR" 2>/dev/null |
        awk '{print $1}'

}

# ------------------------------------------------------------
# 1. Analizar Downloads
# ------------------------------------------------------------

analyze_downloads() {

    separator
    echo "1. ANÁLISIS DE DOWNLOADS"
    separator

    local total_files
    local total_dirs

    total_files="$(
        find "$DOWNLOADS_DIR" \
            -mindepth 1 \
            -maxdepth 1 \
            ! -name '.ubuntu-toolkit-quarantine' \
            -type f \
            | wc -l
    )"

    total_dirs="$(
        find "$DOWNLOADS_DIR" \
            -mindepth 1 \
            -maxdepth 1 \
            ! -name '.ubuntu-toolkit-quarantine' \
            -type d \
            | wc -l
    )"

    echo
    echo "Directorio:"
    echo "$DOWNLOADS_DIR"

    echo
    echo "Tamaño:"
    get_downloads_size

    echo
    echo "Archivos:"
    echo "$total_files"

    echo
    echo "Directorios:"
    echo "$total_dirs"

    echo
    echo "Principales elementos:"

    du -sh "$DOWNLOADS_DIR"/* \
        2>/dev/null |
        sort -hr |
        head -20 || true

    pause
}

# ------------------------------------------------------------
# 2. Archivos grandes
# ------------------------------------------------------------

large_files() {

    separator
    echo "2. ARCHIVOS GRANDES"
    separator

    echo
    echo "Se mostrarán archivos mayores a 500 MB."

    echo

    find "$DOWNLOADS_DIR" \
        -mindepth 1 \
        -maxdepth 1 \
        -type f \
        -size +500M \
        -printf '%s\t%p\n' \
        2>/dev/null |
        sort -nr |
        while IFS=$'\t' read -r size path; do

            printf "%10s  %s\n" \
                "$(numfmt --to=iec "$size")" \
                "$path"

        done || true

    pause
}

# ------------------------------------------------------------
# 3. Archivos antiguos
# ------------------------------------------------------------

old_files() {

    separator
    echo "3. ARCHIVOS ANTIGUOS"
    separator

    local days

    echo
    read -rp "¿Archivos con más de cuántos días? [30]: " days

    if [[ -z "$days" ]]; then
        days=30
    fi

    if ! [[ "$days" =~ ^[0-9]+$ ]]; then

        error "Número de días inválido."

        pause
        return

    fi

    echo
    echo "Archivos con más de $days días:"
    echo

    find "$DOWNLOADS_DIR" \
        -mindepth 1 \
        -maxdepth 1 \
        -type f \
        -mtime +"$days" \
        -printf '%TY-%Tm-%Td  %s bytes  %p\n' \
        2>/dev/null |
        sort || true

    pause
}

# ------------------------------------------------------------
# Clasificación por extensión
# ------------------------------------------------------------

show_category() {

    local category="$1"
    shift

    local extensions=("$@")

    separator
    echo "CATEGORÍA: $category"
    separator

    echo

    local found=false

    while IFS= read -r -d '' file; do

        found=true

        printf "%s\n" "$file"

    done < <(

        find "$DOWNLOADS_DIR" \
            -mindepth 1 \
            -maxdepth 1 \
            -type f \
            -print0 |
            while IFS= read -r -d '' file; do

                filename="${file##*/}"

                if [[ "$filename" == .* ]]; then
                    continue
                fi

                extension="${filename##*.}"

                extension="${extension,,}"

                for allowed in "${extensions[@]}"; do

                    if [[ "$extension" == "$allowed" ]]; then

                        printf '%s\0' "$file"

                        break

                    fi

                done

            done

    )

    if [[ "$found" == false ]]; then
        echo "No se encontraron archivos."
    fi

    pause
}

# ------------------------------------------------------------
# 4. Categorías
# ------------------------------------------------------------

categories_menu() {

    while true; do

        separator
        echo "4. ARCHIVOS POR CATEGORÍA"
        separator

        echo
        echo "1. Instaladores"
        echo "2. Comprimidos"
        echo "3. Documentos"
        echo "4. Imágenes"
        echo "5. Videos"
        echo "6. Audio"
        echo "7. Código"
        echo "0. Volver"

        echo

        read -rp "Selecciona: " option

        case "$option" in

            1)
                show_category \
                    "Instaladores" \
                    deb rpm appimage run exe msi
                ;;

            2)
                show_category \
                    "Comprimidos" \
                    zip tar gz bz2 xz 7z rar tgz
                ;;

            3)
                show_category \
                    "Documentos" \
                    pdf doc docx xls xlsx ppt pptx txt md csv
                ;;

            4)
                show_category \
                    "Imágenes" \
                    jpg jpeg png gif webp svg bmp
                ;;

            5)
                show_category \
                    "Videos" \
                    mp4 mkv avi mov webm m4v
                ;;

            6)
                show_category \
                    "Audio" \
                    mp3 wav flac ogg m4a aac
                ;;

            7)
                show_category \
                    "Código" \
                    js ts jsx tsx py java kt go rs c cpp h hpp sh bash css html json xml yaml yml sql
                ;;

            0)
                return
                ;;

            *)
                warning "Opción no válida."
                ;;

        esac

    done
}

# ------------------------------------------------------------
# Buscar archivos por extensión
# ------------------------------------------------------------

find_extension_files() {

    local extension="$1"

    find "$DOWNLOADS_DIR" \
        -mindepth 1 \
        -maxdepth 1 \
        -type f \
        -iname "*.${extension}" \
        -print0

}

# ------------------------------------------------------------
# Obtener lista de archivos
# ------------------------------------------------------------

get_files_for_extensions() {

    local extensions=("$@")

    local extension

    for extension in "${extensions[@]}"; do

        find_extension_files "$extension"

    done

}

# ------------------------------------------------------------
# 5. Limpiar instaladores
# ------------------------------------------------------------

cleanup_installers() {

    separator
    echo "5. LIMPIAR INSTALADORES"
    separator

    echo
    echo "Instaladores encontrados:"
    echo

    mapfile -d '' files < <(
        get_files_for_extensions \
            deb rpm appimage run
    )

    if [[ "${#files[@]}" -eq 0 ]]; then

        echo "No se encontraron instaladores."

        pause
        return

    fi

    local i=1
    local file

    for file in "${files[@]}"; do

        printf "%3d. %s\n" "$i" "$file"

        ((i++))

    done

    echo
    warning "No se eliminarán automáticamente."

    echo
    echo "1. Mover a cuarentena"
    echo "2. Eliminar seleccionados"
    echo "0. Cancelar"

    echo

    read -rp "Selecciona: " action

    case "$action" in

        1)
            move_selected_to_quarantine files
            ;;

        2)
            delete_selected files
            ;;

        0)
            info "Operación cancelada."
            ;;

        *)
            warning "Opción no válida."
            ;;

    esac

    pause
}

# ------------------------------------------------------------
# 6. Limpiar comprimidos
# ------------------------------------------------------------

cleanup_archives() {

    separator
    echo "6. LIMPIAR ARCHIVOS COMPRIMIDOS"
    separator

    echo
    echo "Archivos comprimidos encontrados:"
    echo

    mapfile -d '' files < <(
        get_files_for_extensions \
            zip tar gz bz2 xz 7z rar tgz
    )

    if [[ "${#files[@]}" -eq 0 ]]; then

        echo "No se encontraron archivos comprimidos."

        pause
        return

    fi

    local i=1
    local file

    for file in "${files[@]}"; do

        printf "%3d. %s\n" "$i" "$file"

        ((i++))

    done

    echo
    echo "1. Mover a cuarentena"
    echo "2. Eliminar seleccionados"
    echo "0. Cancelar"

    echo

    read -rp "Selecciona: " action

    case "$action" in

        1)
            move_selected_to_quarantine files
            ;;

        2)
            delete_selected files
            ;;

        0)
            info "Operación cancelada."
            ;;

        *)
            warning "Opción no válida."
            ;;

    esac

    pause
}

# ------------------------------------------------------------
# Selección de archivos
# ------------------------------------------------------------

parse_selection() {

    local selection="$1"
    local total="$2"

    local number

    IFS=',' read -ra selected <<< "$selection"

    for number in "${selected[@]}"; do

        number="${number// /}"

        if [[ "$number" =~ ^[0-9]+$ ]] &&
            (( number >= 1 && number <= total )); then

            echo "$number"

        else

            warning "Selección ignorada: $number"

        fi

    done

}

# ------------------------------------------------------------
# Mover archivos a cuarentena
# ------------------------------------------------------------

move_selected_to_quarantine() {

    local -n files_ref=$1

    local total="${#files_ref[@]}"

    echo
    echo "Ejemplo:"
    echo
    echo "1,3,5"
    echo

    read -rp \
        "Números a mover a cuarentena: " \
        selection

    if [[ -z "$selection" ]]; then

        info "No se seleccionaron archivos."

        return

    fi

    create_quarantine

    local number
    local file
    local destination

    while read -r number; do

        file="${files_ref[$((number - 1))]}"

        if ! safe_file "$file"; then
            continue
        fi

        destination="$QUARANTINE_DIR/$(basename "$file")"

        if [[ "$DRY_RUN" == true ]]; then

            echo "[DRY-RUN] Mover:"
            echo "$file"
            echo "→"
            echo "$destination"

        else

            if [[ -e "$destination" ]]; then

                destination="$QUARANTINE_DIR/${TIMESTAMP}_$(basename "$file")"

            fi

            mv -- "$file" "$destination"

            success "Movido a cuarentena:"
            echo "$file"

        fi

    done < <(
        parse_selection "$selection" "$total"
    )

}

# ------------------------------------------------------------
# Eliminar archivos seleccionados
# ------------------------------------------------------------

delete_selected() {

    local -n files_ref=$1

    local total="${#files_ref[@]}"

    echo
    echo "Ejemplo:"
    echo
    echo "1,3,5"
    echo

    read -rp \
        "Números a eliminar: " \
        selection

    if [[ -z "$selection" ]]; then

        info "No se seleccionaron archivos."

        return

    fi

    echo
    warning "ATENCIÓN"
    echo "Los archivos seleccionados serán eliminados."

    echo

    if ! confirm "¿Confirmas la eliminación?"; then

        info "Operación cancelada."

        return

    fi

    local number
    local file

    while read -r number; do

        file="${files_ref[$((number - 1))]}"

        if ! safe_file "$file"; then
            continue
        fi

        if [[ "$DRY_RUN" == true ]]; then

            echo "[DRY-RUN] Eliminar:"
            echo "$file"

        else

            rm -- "$file"

            success "Eliminado:"
            echo "$file"

        fi

    done < <(
        parse_selection "$selection" "$total"
    )

}

# ------------------------------------------------------------
# 7. Documentos
# ------------------------------------------------------------

cleanup_documents() {

    separator
    echo "7. LIMPIAR DOCUMENTOS"
    separator

    mapfile -d '' files < <(
        get_files_for_extensions \
            pdf doc docx xls xlsx ppt pptx txt md csv
    )

    if [[ "${#files[@]}" -eq 0 ]]; then

        echo
        echo "No se encontraron documentos."

        pause
        return

    fi

    echo

    local i=1
    local file

    for file in "${files[@]}"; do

        printf "%3d. %s\n" "$i" "$file"

        ((i++))

    done

    echo
    echo "1. Mover a cuarentena"
    echo "2. Eliminar seleccionados"
    echo "0. Cancelar"

    echo

    read -rp "Selecciona: " action

    case "$action" in

        1)
            move_selected_to_quarantine files
            ;;

        2)
            delete_selected files
            ;;

        0)
            info "Operación cancelada."
            ;;

        *)
            warning "Opción no válida."
            ;;

    esac

    pause
}

# ------------------------------------------------------------
# 8. Ver cuarentena
# ------------------------------------------------------------

show_quarantine() {

    separator
    echo "8. CUARENTENA"
    separator

    if [[ ! -d "$QUARANTINE_DIR" ]]; then

        echo
        echo "La cuarentena está vacía."

        pause
        return

    fi

    echo
    echo "Directorio:"
    echo "$QUARANTINE_DIR"

    echo
    echo "Contenido:"

    find "$QUARANTINE_DIR" \
        -mindepth 1 \
        -maxdepth 1 \
        -printf '%TY-%Tm-%Td  %p\n' \
        2>/dev/null || true

    echo
    echo "Tamaño:"

    du -sh "$QUARANTINE_DIR" 2>/dev/null || true

    echo
    echo "Opciones:"
    echo
    echo "1. Restaurar archivo"
    echo "2. Vaciar cuarentena"
    echo "0. Volver"

    echo

    read -rp "Selecciona: " option

    case "$option" in

        1)
            restore_quarantine
            ;;

        2)
            empty_quarantine
            ;;

        0)
            return
            ;;

        *)
            warning "Opción no válida."
            ;;

    esac

    pause
}

# ------------------------------------------------------------
# Restaurar cuarentena
# ------------------------------------------------------------

restore_quarantine() {

    if [[ ! -d "$QUARANTINE_DIR" ]]; then

        warning "No existe la cuarentena."

        return

    fi

    mapfile -d '' files < <(
        find "$QUARANTINE_DIR" \
            -mindepth 1 \
            -maxdepth 1 \
            -type f \
            -print0
    )

    if [[ "${#files[@]}" -eq 0 ]]; then

        echo "No hay archivos para restaurar."

        return

    fi

    echo

    local i=1
    local file

    for file in "${files[@]}"; do

        printf "%3d. %s\n" "$i" "$(basename "$file")"

        ((i++))

    done

    echo

    read -rp "Número del archivo a restaurar: " number

    if ! [[ "$number" =~ ^[0-9]+$ ]] ||
        (( number < 1 || number > ${#files[@]} )); then

        error "Selección inválida."

        return

    fi

    file="${files[$((number - 1))]}"

    local destination="$DOWNLOADS_DIR/$(basename "$file")"

    if [[ -e "$destination" ]]; then

        warning "Ya existe un archivo con ese nombre."

        destination="$DOWNLOADS_DIR/restored_$(basename "$file")"

    fi

    if [[ "$DRY_RUN" == true ]]; then

        echo "[DRY-RUN] Restaurar:"
        echo "$file"
        echo "→"
        echo "$destination"

    else

        mv -- "$file" "$destination"

        success "Archivo restaurado:"
        echo "$destination"

    fi

}

# ------------------------------------------------------------
# Vaciar cuarentena
# ------------------------------------------------------------

empty_quarantine() {

    if [[ ! -d "$QUARANTINE_DIR" ]]; then

        warning "No existe la cuarentena."

        return

    fi

    echo
    warning "Esta acción eliminará permanentemente"
    echo "los archivos almacenados en cuarentena."

    echo

    if ! confirm "¿Continuar?"; then

        info "Operación cancelada."

        return

    fi

    if [[ "$DRY_RUN" == true ]]; then

        echo "[DRY-RUN] Vaciar cuarentena."

    else

        find "$QUARANTINE_DIR" \
            -mindepth 1 \
            -maxdepth 1 \
            -type f \
            -delete

        success "Cuarentena vaciada."

    fi

}

# ------------------------------------------------------------
# Menú principal
# ------------------------------------------------------------

show_menu() {

    clear

    separator
    echo "          UBUNTU TOOLKIT"
    echo "          DOWNLOADS CLEANUP"
    echo "          v$SCRIPT_VERSION"
    separator

    echo
    echo "Directorio:"
    echo "$DOWNLOADS_DIR"

    echo
    echo "Tamaño:"
    get_downloads_size

    if [[ "$DRY_RUN" == true ]]; then

        echo
        warning "MODO DRY-RUN"

    fi

    echo

    echo "1.  Analizar Downloads"
    echo "2.  Ver archivos grandes"
    echo "3.  Ver archivos antiguos"
    echo "4.  Ver archivos por categoría"
    echo "5.  Limpiar instaladores"
    echo "6.  Limpiar comprimidos"
    echo "7.  Limpiar documentos"
    echo "8.  Ver / administrar cuarentena"
    echo "0.  Salir"

    echo

}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

while true; do

    show_menu

    read -rp "Selecciona una opción: " option

    case "$option" in

        1)
            analyze_downloads
            ;;

        2)
            large_files
            ;;

        3)
            old_files
            ;;

        4)
            categories_menu
            ;;

        5)
            cleanup_installers
            ;;

        6)
            cleanup_archives
            ;;

        7)
            cleanup_documents
            ;;

        8)
            show_quarantine
            ;;

        0)

            clear

            echo
            success "Downloads Cleanup finalizado."
            echo

            if [[ "$DRY_RUN" == false ]]; then

                echo "Log:"
                echo "$LOG_FILE"

            fi

            echo

            exit 0
            ;;

        *)

            warning "Opción no válida."
            sleep 1
            ;;

    esac

done