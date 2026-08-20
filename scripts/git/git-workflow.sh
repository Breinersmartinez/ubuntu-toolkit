#!/usr/bin/env bash

# ============================================================
# Ubuntu Toolkit - Git Workflow
# Version: 0.1.0
#
# Herramienta interactiva para tareas comunes de Git/GitHub.
#
# Funciones:
#   1. Ver estado
#   2. Ver cambios
#   3. Añadir cambios
#   4. Crear commit
#   5. Push
#   6. Crear nueva rama
#   7. Cambiar de rama
#   8. Actualizar rama
#   9. Ver últimos commits
#  10. Configurar/ver identidad Git
#  11. Crear nueva clave SSH para GitHub
#
# Seguridad:
#   - No elimina ramas automáticamente.
#   - No ejecuta git reset --hard.
#   - No ejecuta git clean.
#   - No hace force push.
#   - No sobrescribe claves SSH existentes.
#   - Nunca muestra claves privadas.
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

pause() {
    echo
    read -rp "Presiona ENTER para continuar..."
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
# Verificar Git
# ------------------------------------------------------------

if ! command_exists git; then
    error "Git no está instalado."

    echo
    echo "Puedes instalarlo con:"
    echo
    echo "    sudo apt install git"

    exit 1
fi

# ------------------------------------------------------------
# Verificar repositorio
# ------------------------------------------------------------

check_repository() {

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then

        error "El directorio actual no es un repositorio Git."

        echo
        echo "Repositorio esperado:"
        echo
        echo "    $(pwd)"

        echo
        echo "Puedes inicializar uno con:"
        echo
        echo "    git init"

        return 1
    fi

    return 0
}

# ------------------------------------------------------------
# Obtener rama actual
# ------------------------------------------------------------

current_branch() {

    git branch --show-current 2>/dev/null || true

}

# ------------------------------------------------------------
# 1. Ver estado
# ------------------------------------------------------------

show_status() {

    separator
    echo "1. ESTADO DEL REPOSITORIO"
    separator

    if ! check_repository; then
        return
    fi

    echo
    echo "Repositorio:"
    git rev-parse --show-toplevel

    echo
    echo "Rama actual:"
    current_branch

    echo
    echo "Estado:"
    git status --short --branch

    echo
    echo "Remote:"
    git remote -v 2>/dev/null || true

    pause
}

# ------------------------------------------------------------
# 2. Ver cambios
# ------------------------------------------------------------

show_changes() {

    separator
    echo "2. VER CAMBIOS"
    separator

    if ! check_repository; then
        return
    fi

    echo
    echo "Cambios no staged:"
    git diff

    echo
    echo "Cambios staged:"
    git diff --cached

    pause
}

# ------------------------------------------------------------
# 3. Añadir cambios
# ------------------------------------------------------------

add_changes() {

    separator
    echo "3. AÑADIR CAMBIOS"
    separator

    if ! check_repository; then
        return
    fi

    echo
    git status --short

    echo

    read -rp "¿Qué deseas añadir? [A=todos / archivo específico]: " target

    if [[ -z "$target" ]]; then
        warning "No se especificó ningún archivo."
        pause
        return
    fi

    if [[ "$target" == "A" || "$target" == "a" ]]; then

        if confirm "¿Añadir todos los cambios?"; then

            git add .

            success "Todos los cambios fueron añadidos."

        else

            info "Operación cancelada."

        fi

    else

        if [[ ! -e "$target" ]]; then

            error "El archivo o directorio no existe:"
            echo "$target"

        else

            git add -- "$target"

            success "Añadido:"
            echo "$target"

        fi

    fi

    echo
    echo "Estado después de git add:"
    git status --short

    pause
}

# ------------------------------------------------------------
# 4. Crear commit
# ------------------------------------------------------------

create_commit() {

    separator
    echo "4. CREAR COMMIT"
    separator

    if ! check_repository; then
        return
    fi

    echo
    echo "Cambios staged:"
    git diff --cached --stat

    echo

    if git diff --cached --quiet; then

        warning "No hay cambios preparados para commit."

        echo
        echo "Primero utiliza la opción 3."

        pause
        return

    fi

    echo
    read -rp "Mensaje del commit: " commit_message

    if [[ -z "$commit_message" ]]; then

        error "El mensaje del commit no puede estar vacío."

        pause
        return

    fi

    echo
    echo "Commit:"
    echo "$commit_message"

    echo

    if confirm "¿Crear este commit?"; then

        git commit -m "$commit_message"

        success "Commit creado."

    else

        info "Commit cancelado."

    fi

    pause
}

# ------------------------------------------------------------
# 5. Push
# ------------------------------------------------------------

push_changes() {

    separator
    echo "5. PUSH"
    separator

    if ! check_repository; then
        return
    fi

    local branch
    branch="$(current_branch)"

    if [[ -z "$branch" ]]; then

        error "No se pudo determinar la rama actual."

        pause
        return

    fi

    echo
    echo "Rama actual:"
    echo "$branch"

    echo
    echo "Remote:"
    git remote -v

    echo

    if ! git remote get-url origin >/dev/null 2>&1; then

        error "No existe un remote llamado 'origin'."

        echo
        echo "Puedes agregarlo con:"
        echo
        echo "    git remote add origin <URL>"

        pause
        return

    fi

    if confirm "¿Hacer push de '$branch' a origin?"; then

        git push -u origin "$branch"

        success "Push completado."

    else

        info "Push cancelado."

    fi

    pause
}

# ------------------------------------------------------------
# 6. Crear nueva rama
# ------------------------------------------------------------

create_branch() {

    separator
    echo "6. CREAR NUEVA RAMA"
    separator

    if ! check_repository; then
        return
    fi

    echo
    echo "Rama actual:"
    current_branch

    echo
    read -rp "Nombre de la nueva rama: " branch_name

    if [[ -z "$branch_name" ]]; then

        error "El nombre de la rama no puede estar vacío."

        pause
        return

    fi

    if git show-ref --verify --quiet "refs/heads/$branch_name"; then

        error "La rama ya existe:"
        echo "$branch_name"

        pause
        return

    fi

    git switch -c "$branch_name"

    success "Nueva rama creada:"
    echo "$branch_name"

    pause
}

# ------------------------------------------------------------
# 7. Cambiar de rama
# ------------------------------------------------------------

switch_branch() {

    separator
    echo "7. CAMBIAR DE RAMA"
    separator

    if ! check_repository; then
        return
    fi

    echo
    echo "Ramas disponibles:"
    git branch

    echo
    read -rp "Nombre de la rama: " branch_name

    if [[ -z "$branch_name" ]]; then

        error "No se especificó una rama."

        pause
        return

    fi

    if ! git show-ref --verify --quiet "refs/heads/$branch_name"; then

        error "La rama no existe:"
        echo "$branch_name"

        pause
        return

    fi

    if [[ -n "$(git status --porcelain)" ]]; then

        warning "Hay cambios sin commit."

        echo
        git status --short

        echo

        if ! confirm "¿Intentar cambiar de rama de todas formas?"; then

            info "Operación cancelada."

            pause
            return

        fi

    fi

    git switch "$branch_name"

    success "Ahora estás en:"
    echo "$branch_name"

    pause
}

# ------------------------------------------------------------
# 8. Actualizar rama
# ------------------------------------------------------------

update_branch() {

    separator
    echo "8. ACTUALIZAR RAMA"
    separator

    if ! check_repository; then
        return
    fi

    local branch
    branch="$(current_branch)"

    echo
    echo "Rama:"
    echo "$branch"

    echo
    echo "Se ejecutará:"
    echo
    echo "    git pull --ff-only"

    echo
    info "Se utiliza --ff-only para evitar merges automáticos inesperados."

    if confirm "¿Continuar?"; then

        git pull --ff-only

        success "Rama actualizada."

    else

        info "Operación cancelada."

    fi

    pause
}

# ------------------------------------------------------------
# 9. Últimos commits
# ------------------------------------------------------------

show_commits() {

    separator
    echo "9. ÚLTIMOS COMMITS"
    separator

    if ! check_repository; then
        return
    fi

    echo
    git log \
        --graph \
        --decorate \
        --oneline \
        --all \
        -15

    pause
}

# ------------------------------------------------------------
# 10. Identidad Git
# ------------------------------------------------------------

git_identity() {

    while true; do

        separator
        echo "10. IDENTIDAD GIT"
        separator

        echo
        echo "Configuración global:"
        echo
        echo "Nombre:"
        git config --global user.name 2>/dev/null || true

        echo
        echo "Correo:"
        git config --global user.email 2>/dev/null || true

        echo
        echo "Configuración del repositorio actual:"
        echo
        echo "Nombre:"
        git config --local user.name 2>/dev/null || true

        echo
        echo "Correo:"
        git config --local user.email 2>/dev/null || true

        echo
        echo "1. Configurar identidad global"
        echo "2. Configurar identidad solamente para este repositorio"
        echo "3. Ver configuración completa"
        echo "0. Volver"

        echo
        read -rp "Selecciona una opción: " option

        case "$option" in

            1)
                echo

                read -rp "Nombre completo: " git_name
                read -rp "Correo electrónico: " git_email

                if [[ -z "$git_name" || -z "$git_email" ]]; then

                    error "Nombre y correo son obligatorios."

                else

                    git config --global user.name "$git_name"
                    git config --global user.email "$git_email"

                    success "Identidad global configurada."

                fi

                pause
                ;;

            2)
                if ! check_repository; then
                    pause
                    continue
                fi

                echo

                read -rp "Nombre para este repositorio: " git_name
                read -rp "Correo para este repositorio: " git_email

                if [[ -z "$git_name" || -z "$git_email" ]]; then

                    error "Nombre y correo son obligatorios."

                else

                    git config --local user.name "$git_name"
                    git config --local user.email "$git_email"

                    success "Identidad local configurada."

                fi

                pause
                ;;

            3)
                echo
                git config --list --show-origin

                pause
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
# 11. Crear clave SSH
# ------------------------------------------------------------

create_ssh_key() {

    separator
    echo "11. CREAR NUEVA CLAVE SSH PARA GITHUB"
    separator

    if ! command_exists ssh-keygen; then

        error "ssh-keygen no está instalado."

        echo
        echo "Puedes instalarlo con:"
        echo
        echo "    sudo apt install openssh-client"

        pause
        return

    fi

    local ssh_dir="$HOME/.ssh"
    local email
    local key_name
    local key_path
    local public_key

    mkdir -p "$ssh_dir"

    chmod 700 "$ssh_dir"

    echo
    info "Se generará una clave ED25519."

    echo
    echo "La clave privada permanecerá en:"
    echo
    echo "    $ssh_dir/"
    echo

    echo "La clave pública será la que debes agregar a GitHub."

    echo

    read -rp "Correo electrónico asociado a GitHub: " email

    if [[ -z "$email" ]]; then

        error "El correo electrónico es obligatorio."

        pause
        return

    fi

    echo
    read -rp \
        "Nombre del archivo [id_ed25519_github]: " key_name

    if [[ -z "$key_name" ]]; then
        key_name="id_ed25519_github"
    fi

    key_path="$ssh_dir/$key_name"

    # --------------------------------------------------------
    # Evitar sobrescribir claves
    # --------------------------------------------------------

    if [[ -e "$key_path" || -e "${key_path}.pub" ]]; then

        error "Ya existe una clave con ese nombre:"
        echo
        echo "$key_path"

        echo
        warning "No se sobrescribirá."

        pause
        return

    fi

    echo
    info "Generando clave..."

    ssh-keygen \
        -t ed25519 \
        -C "$email" \
        -f "$key_path"

    chmod 600 "$key_path"
    chmod 644 "${key_path}.pub"

    success "Clave SSH creada."

    # --------------------------------------------------------
    # Información de la clave
    # --------------------------------------------------------

    separator
    echo "INFORMACIÓN DE LA CLAVE"
    separator

    echo
    echo "Tipo:"
    echo "ED25519"

    echo
    echo "Correo:"
    echo "$email"

    echo
    echo "Clave privada:"
    echo "$key_path"

    echo
    echo "Clave pública:"
    echo "${key_path}.pub"

    echo
    echo "Fingerprint:"
    ssh-keygen -lf "${key_path}.pub"

    echo
    echo "Información detallada:"
    ssh-keygen -lvf "${key_path}.pub" || true

    # --------------------------------------------------------
    # Mostrar clave pública
    # --------------------------------------------------------

    separator
    echo "CLAVE PÚBLICA PARA GITHUB"
    separator

    echo

    public_key="$(cat "${key_path}.pub")"

    echo "$public_key"

    echo

    separator
    echo "SIGUIENTE PASO"
    separator

    echo
    echo "1. Copia TODA la línea anterior."
    echo
    echo "2. Entra a GitHub."
    echo
    echo "3. Ve a:"
    echo
    echo "   Settings → SSH and GPG keys"
    echo
    echo "4. Selecciona:"
    echo
    echo "   New SSH key"
    echo
    echo "5. Usa un título como:"
    echo
    echo "   Ubuntu PC"
    echo
    echo "6. Pega la clave pública."
    echo
    echo "7. Guarda la clave."

    # --------------------------------------------------------
    # SSH Agent
    # --------------------------------------------------------

    separator
    echo "SSH AGENT"
    separator

    if command_exists ssh-agent; then

        echo
        echo "Puedes agregar la clave al ssh-agent con:"
        echo
        echo "    ssh-add \"$key_path\""

        echo

        if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then

            success "ssh-agent parece estar disponible."

            if confirm "¿Agregar la clave al ssh-agent ahora?"; then

                if ssh-add "$key_path"; then
                    success "Clave agregada al ssh-agent."
                else
                    warning "No se pudo agregar automáticamente."
                    echo
                    echo "Ejecuta:"
                    echo
                    echo "    ssh-add \"$key_path\""
                fi

            fi

        else

            warning "No se detectó un ssh-agent activo."

            echo
            echo "Puedes iniciar uno con:"
            echo
            echo "    eval \"\$(ssh-agent -s)\""
            echo
            echo "Y después:"
            echo
            echo "    ssh-add \"$key_path\""

        fi

    fi

    # --------------------------------------------------------
    # Prueba de GitHub
    # --------------------------------------------------------

    separator
    echo "PRUEBA DE CONEXIÓN"
    separator

    echo
    echo "Después de agregar la clave a GitHub,"
    echo "puedes comprobar la conexión con:"
    echo
    echo "    ssh -T git@github.com"

    echo
    echo "No compartas nunca:"
    echo
    echo "    $key_path"

    echo
    echo "La clave que debes compartir es únicamente:"
    echo
    echo "    ${key_path}.pub"

    pause
}

# ------------------------------------------------------------
# Menú principal
# ------------------------------------------------------------

show_menu() {

    clear

    separator
    echo "              UBUNTU TOOLKIT"
    echo "              GIT WORKFLOW"
    echo "              v$SCRIPT_VERSION"
    separator

    echo

    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then

        echo "Repositorio:"
        echo "$(basename "$(git rev-parse --show-toplevel)")"

        echo
        echo "Rama:"
        current_branch

    else

        echo "Repositorio: no detectado"

    fi

    echo

    echo "1.  Ver estado"
    echo "2.  Ver cambios"
    echo "3.  Añadir cambios"
    echo "4.  Crear commit"
    echo "5.  Push"
    echo "6.  Crear nueva rama"
    echo "7.  Cambiar de rama"
    echo "8.  Actualizar rama"
    echo "9.  Ver últimos commits"
    echo "10. Ver/configurar identidad Git"
    echo "11. Crear nueva clave SSH para GitHub"
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
            show_status
            ;;

        2)
            show_changes
            ;;

        3)
            add_changes
            ;;

        4)
            create_commit
            ;;

        5)
            push_changes
            ;;

        6)
            create_branch
            ;;

        7)
            switch_branch
            ;;

        8)
            update_branch
            ;;

        9)
            show_commits
            ;;

        10)
            git_identity
            ;;

        11)
            create_ssh_key
            ;;

        0)
            clear
            echo
            success "Git Workflow finalizado."
            echo
            exit 0
            ;;

        *)
            warning "Opción no válida."
            sleep 1
            ;;

    esac

done