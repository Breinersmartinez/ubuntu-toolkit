#!/usr/bin/env bash

# ============================================================
# Ubuntu Toolkit - New Project
# Version: 0.1.0
#
# Generador interactivo de proyectos.
#
# Soporta:
#   - Spring Boot
#   - Python
#   - Node.js
#   - React + Vite + Tailwind
#   - Angular + TypeScript
#
# Características:
#   - Preguntas específicas según el stack
#   - Validación de herramientas
#   - Creación de README
#   - Creación de .gitignore
#   - Inicialización opcional de Git
#   - No sobrescribe proyectos existentes
#   - No instala herramientas automáticamente
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
# Error handler
# ------------------------------------------------------------

on_error() {

    local exit_code=$?
    local line_number=$1

    echo
    error "El script encontró un error."
    error "Línea: $line_number"
    error "Código: $exit_code"

    exit "$exit_code"
}

trap 'on_error $LINENO' ERR

# ------------------------------------------------------------
# Validaciones
# ------------------------------------------------------------

validate_project_name() {

    local name="$1"

    if [[ -z "$name" ]]; then
        return 1
    fi

    if [[ ! "$name" =~ ^[a-zA-Z0-9._-]+$ ]]; then

        error "Nombre de proyecto inválido:"
        echo "$name"

        echo
        echo "Usa solamente:"
        echo "  letras"
        echo "  números"
        echo "  -"
        echo "  _"
        echo "  ."

        return 1
    fi

    return 0
}

# ------------------------------------------------------------
# Directorio del proyecto
# ------------------------------------------------------------

ask_project_location() {

    local default_dir="$HOME/Projects"

    echo
    read -rp \
        "Directorio base [$default_dir]: " PROJECT_BASE

    if [[ -z "$PROJECT_BASE" ]]; then
        PROJECT_BASE="$default_dir"
    fi

    PROJECT_BASE="${PROJECT_BASE/#\~/$HOME}"

    mkdir -p "$PROJECT_BASE"

}

# ------------------------------------------------------------
# Nombre del proyecto
# ------------------------------------------------------------

ask_project_name() {

    while true; do

        echo
        read -rp "Nombre del proyecto: " PROJECT_NAME

        if validate_project_name "$PROJECT_NAME"; then
            break
        fi

    done

    PROJECT_DIR="$PROJECT_BASE/$PROJECT_NAME"

    if [[ -e "$PROJECT_DIR" ]]; then

        error "El proyecto ya existe:"
        echo
        echo "$PROJECT_DIR"

        echo

        if ! confirm "¿Deseas elegir otro nombre?"; then
            exit 1
        fi

        ask_project_name
    fi
}

# ------------------------------------------------------------
# Git
# ------------------------------------------------------------

initialize_git() {

    if ! command_exists git; then

        warning "Git no está instalado."

        return

    fi

    if confirm "¿Inicializar repositorio Git?"; then

        git -C "$PROJECT_DIR" init

        success "Repositorio Git inicializado."

    fi
}

# ------------------------------------------------------------
# README
# ------------------------------------------------------------

create_readme() {

    local stack="$1"

    cat > "$PROJECT_DIR/README.md" <<EOF
# $PROJECT_NAME

Proyecto generado con **Ubuntu Toolkit - New Project**.

## Stack

$stack

## Instalación

Consulta la documentación del stack para instalar las dependencias.

## Ejecución

Agrega aquí las instrucciones necesarias para ejecutar el proyecto.

## Autor

$USER
EOF

}

# ------------------------------------------------------------
# Python
# ------------------------------------------------------------

create_python_project() {

    separator
    echo "PYTHON"
    separator

    if ! command_exists python3; then

        error "Python 3 no está instalado."

        echo
        echo "Instalación:"
        echo
        echo "sudo apt install python3 python3-venv python3-pip"

        return 1

    fi

    echo
    python3 --version

    echo
    read -rp "Versión mínima de Python [3.12]: " PYTHON_VERSION

    if [[ -z "$PYTHON_VERSION" ]]; then
        PYTHON_VERSION="3.12"
    fi

    echo
    echo "Tipo de proyecto:"
    echo
    echo "1. Aplicación"
    echo "2. API"
    echo "3. CLI"
    echo "4. Script"

    echo
    read -rp "Selecciona: " PYTHON_TYPE

    echo
    read -rp \
        "Dependencias iniciales (separadas por espacio, opcional): " \
        PYTHON_DEPS

    mkdir -p "$PROJECT_DIR"

    python3 -m venv "$PROJECT_DIR/.venv"

    touch "$PROJECT_DIR/requirements.txt"

    if [[ -n "$PYTHON_DEPS" ]]; then

        "$PROJECT_DIR/.venv/bin/pip" install $PYTHON_DEPS

        "$PROJECT_DIR/.venv/bin/pip" freeze \
            > "$PROJECT_DIR/requirements.txt"

    fi

    mkdir -p "$PROJECT_DIR/src"
    mkdir -p "$PROJECT_DIR/tests"

    cat > "$PROJECT_DIR/src/main.py" <<EOF
def main():
    print("Hello from $PROJECT_NAME")


if __name__ == "__main__":
    main()
EOF

    cat > "$PROJECT_DIR/.gitignore" <<'EOF'
.venv/
__pycache__/
*.py[cod]
.pytest_cache/
.mypy_cache/
.ruff_cache/
.coverage
htmlcov/
.env
.env.*
.idea/
.vscode/
EOF

    create_readme "Python $PYTHON_VERSION"

    success "Proyecto Python creado."

}

# ------------------------------------------------------------
# Node.js
# ------------------------------------------------------------

create_node_project() {

    separator
    echo "NODE.JS"
    separator

    if ! command_exists node; then

        error "Node.js no está instalado."

        echo
        echo "Se recomienda instalar Node.js mediante:"
        echo "nvm"

        return 1

    fi

    if ! command_exists npm; then

        error "npm no está instalado."

        return 1

    fi

    echo
    node --version
    npm --version

    echo
    echo "Gestor de paquetes:"
    echo
    echo "1. npm"
    echo "2. pnpm"
    echo "3. yarn"

    echo
    read -rp "Selecciona [1]: " NODE_MANAGER

    case "$NODE_MANAGER" in

        2)
            if ! command_exists pnpm; then
                error "pnpm no está instalado."
                return 1
            fi
            PACKAGE_MANAGER="pnpm"
            ;;

        3)
            if ! command_exists yarn; then
                error "yarn no está instalado."
                return 1
            fi
            PACKAGE_MANAGER="yarn"
            ;;

        *)
            PACKAGE_MANAGER="npm"
            ;;

    esac

    echo
    echo "Tipo de proyecto:"
    echo
    echo "1. JavaScript"
    echo "2. TypeScript"

    echo
    read -rp "Selecciona [1]: " NODE_LANGUAGE

    case "$NODE_LANGUAGE" in

        2)
            LANGUAGE="TypeScript"
            ;;

        *)
            LANGUAGE="JavaScript"
            ;;

    esac

    echo
    read -rp \
        "Dependencias iniciales (opcional): " \
        NODE_DEPS

    mkdir -p "$PROJECT_DIR"

    cd "$PROJECT_DIR"

    case "$PACKAGE_MANAGER" in

        npm)
            npm init -y
            ;;

        pnpm)
            pnpm init
            ;;

        yarn)
            yarn init -y
            ;;

    esac

    mkdir -p src

    if [[ "$LANGUAGE" == "TypeScript" ]]; then

        if [[ "$PACKAGE_MANAGER" == "npm" ]]; then
            npm install -D typescript tsx @types/node
        fi

        touch tsconfig.json

        cat > src/index.ts <<EOF
console.log("Hello from $PROJECT_NAME");
EOF

    else

        cat > src/index.js <<EOF
console.log("Hello from $PROJECT_NAME");
EOF

    fi

    if [[ -n "$NODE_DEPS" ]]; then

        case "$PACKAGE_MANAGER" in

            npm)
                npm install $NODE_DEPS
                ;;

            pnpm)
                pnpm add $NODE_DEPS
                ;;

            yarn)
                yarn add $NODE_DEPS
                ;;

        esac

    fi

    cat > .gitignore <<'EOF'
node_modules/
dist/
build/
coverage/
.env
.env.*
.vscode/
.idea/
.DS_Store
EOF

    create_readme "Node.js / $LANGUAGE"

    success "Proyecto Node.js creado."

}

# ------------------------------------------------------------
# React + Vite + Tailwind
# ------------------------------------------------------------

create_react_project() {

    separator
    echo "REACT + VITE + TAILWIND"
    separator

    if ! command_exists node; then

        error "Node.js no está instalado."
        return 1

    fi

    if ! command_exists npm; then

        error "npm no está instalado."
        return 1

    fi

    echo
    node --version
    npm --version

    echo
    echo "Lenguaje:"
    echo
    echo "1. JavaScript"
    echo "2. TypeScript"

    echo
    read -rp "Selecciona [2]: " REACT_LANGUAGE

    if [[ "$REACT_LANGUAGE" == "1" ]]; then

        TEMPLATE="react"

    else

        TEMPLATE="react-ts"

    fi

    echo
    info "Creando React + Vite..."

    npm create vite@latest \
        "$PROJECT_DIR" \
        -- \
        --template "$TEMPLATE"

    cd "$PROJECT_DIR"

    npm install

    echo
    info "Configurando Tailwind CSS..."

    npm install tailwindcss @tailwindcss/vite

    cat > vite.config.ts <<'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
  ],
})
EOF

    if [[ -f src/index.css ]]; then

        cat > src/index.css <<'EOF'
@import "tailwindcss";
EOF

    fi

    if [[ -f src/index.css ]]; then

        cat >> src/index.css <<'EOF'

/* Project styles */
EOF

    fi

    create_readme "React + Vite + Tailwind CSS"

    success "Proyecto React creado."

}

# ------------------------------------------------------------
# Angular
# ------------------------------------------------------------

create_angular_project() {

    separator
    echo "ANGULAR + TYPESCRIPT"
    separator

    if ! command_exists node; then

        error "Node.js no está instalado."
        return 1

    fi

    if ! command_exists npm; then

        error "npm no está instalado."
        return 1

    fi

    echo
    node --version
    npm --version

    echo

    if ! command_exists ng; then

        warning "Angular CLI no está instalado."

        echo
        echo "Puedes instalarlo con:"
        echo
        echo "npm install -g @angular/cli"

        if ! confirm "¿Deseas continuar sin Angular CLI?"; then
            return 1
        fi

        return 1

    fi

    echo
    ng version

    echo
    echo "Opciones iniciales:"
    echo

    read -rp \
        "¿Usar routing? [Y/n]: " ANGULAR_ROUTING

    read -rp \
        "¿Usar SCSS? [Y/n]: " ANGULAR_SCSS

    ANGULAR_ROUTING_FLAG=""

    if [[ ! "$ANGULAR_ROUTING" =~ ^[Nn]$ ]]; then
        ANGULAR_ROUTING_FLAG="--routing"
    fi

    if [[ "$ANGULAR_SCSS" =~ ^[Nn]$ ]]; then
        STYLE="css"
    else
        STYLE="scss"
    fi

    echo
    info "Creando proyecto Angular..."

    ng new "$PROJECT_NAME" \
        --directory "$PROJECT_DIR" \
        --style "$STYLE" \
        $ANGULAR_ROUTING_FLAG \
        --skip-git

    create_readme "Angular + TypeScript"

    success "Proyecto Angular creado."

}

# ------------------------------------------------------------
# Spring Boot
# ------------------------------------------------------------

create_springboot_project() {

    separator
    echo "SPRING BOOT"
    separator

    if ! command_exists java; then

        error "Java no está instalado."

        echo
        echo "Ejemplo:"
        echo
        echo "sudo apt install openjdk-21-jdk"

        return 1

    fi

    echo
    java -version

    echo
    echo "Build tool:"
    echo
    echo "1. Maven"
    echo "2. Gradle"

    echo
    read -rp "Selecciona [1]: " BUILD_TOOL

    case "$BUILD_TOOL" in

        2)
            SPRING_BUILD="gradle-project"
            ;;

        *)
            SPRING_BUILD="maven-project"
            ;;

    esac

    echo
    echo "Lenguaje:"
    echo
    echo "1. Java"
    echo "2. Kotlin"

    echo
    read -rp "Selecciona [1]: " SPRING_LANGUAGE

    case "$SPRING_LANGUAGE" in

        2)
            SPRING_LANG="kotlin"
            ;;

        *)
            SPRING_LANG="java"
            ;;

    esac

    echo
    read -rp \
        "Group ID [com.example]: " \
        SPRING_GROUP

    if [[ -z "$SPRING_GROUP" ]]; then
        SPRING_GROUP="com.example"
    fi

    echo
    read -rp \
        "Artifact ID [$PROJECT_NAME]: " \
        SPRING_ARTIFACT

    if [[ -z "$SPRING_ARTIFACT" ]]; then
        SPRING_ARTIFACT="$PROJECT_NAME"
    fi

    echo
    read -rp \
        "Descripción [Spring Boot application]: " \
        SPRING_DESCRIPTION

    if [[ -z "$SPRING_DESCRIPTION" ]]; then
        SPRING_DESCRIPTION="Spring Boot application"
    fi

    echo
    echo "Dependencias iniciales."
    echo
    echo "Ejemplos:"
    echo
    echo "web,data-jpa,postgresql,lombok"
    echo

    read -rp \
        "Dependencias (opcional): " \
        SPRING_DEPS

    if ! command_exists curl; then

        error "curl no está instalado."

        echo
        echo "Instalación:"
        echo
        echo "sudo apt install curl"

        return 1

    fi

    mkdir -p "$PROJECT_DIR"

    local start_url

    start_url="https://start.spring.io/starter.zip"

    info "Generando proyecto Spring Boot..."

    local -a curl_args

    curl_args=(
        -fsSL
        -o "$PROJECT_DIR/springboot.zip"
        "$start_url"
        "?type=$SPRING_BUILD"
        "&language=$SPRING_LANG"
        "&groupId=$SPRING_GROUP"
        "&artifactId=$SPRING_ARTIFACT"
        "&name=$SPRING_ARTIFACT"
        "&description=$SPRING_DESCRIPTION"
    )

    if [[ -n "$SPRING_DEPS" ]]; then
        curl_args+=("&dependencies=$SPRING_DEPS")
    fi

    curl "${curl_args[@]}"

    if ! command_exists unzip; then

        error "unzip no está instalado."

        echo
        echo "Instalación:"
        echo
        echo "sudo apt install unzip"

        rm -f "$PROJECT_DIR/springboot.zip"

        return 1

    fi

    unzip -q \
        "$PROJECT_DIR/springboot.zip" \
        -d "$PROJECT_DIR"

    rm -f "$PROJECT_DIR/springboot.zip"

    create_readme "Spring Boot / $SPRING_LANG / $SPRING_BUILD"

    success "Proyecto Spring Boot creado."

}

# ------------------------------------------------------------
# Finalizar proyecto
# ------------------------------------------------------------

finish_project() {

    separator
    echo "CONFIGURACIÓN FINAL"
    separator

    echo
    echo "Proyecto:"
    echo "$PROJECT_DIR"

    echo
    echo "¿Inicializar Git?"

    if confirm "Inicializar Git ahora?"; then

        initialize_git

    fi

    echo
    echo "Proyecto generado correctamente."

    echo
    echo "Ruta:"
    echo
    echo "    $PROJECT_DIR"

    echo

    if command_exists code; then

        if confirm "¿Abrir proyecto en VS Code?"; then

            code "$PROJECT_DIR"

        fi

    fi

}

# ------------------------------------------------------------
# Menú principal
# ------------------------------------------------------------

show_menu() {

    clear

    separator
    echo "             UBUNTU TOOLKIT"
    echo "             NEW PROJECT"
    echo "             v$SCRIPT_VERSION"
    separator

    echo
    echo "1. Spring Boot"
    echo "2. Python"
    echo "3. Node.js"
    echo "4. React + Vite + Tailwind"
    echo "5. Angular + TypeScript"
    echo "0. Salir"

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

            ask_project_location
            ask_project_name

            if create_springboot_project; then
                finish_project
            fi

            pause
            ;;

        2)

            ask_project_location
            ask_project_name

            if create_python_project; then
                finish_project
            fi

            pause
            ;;

        3)

            ask_project_location
            ask_project_name

            if create_node_project; then
                finish_project
            fi

            pause
            ;;

        4)

            ask_project_location
            ask_project_name

            if create_react_project; then
                finish_project
            fi

            pause
            ;;

        5)

            ask_project_location
            ask_project_name

            if create_angular_project; then
                finish_project
            fi

            pause
            ;;

        0)

            clear
            echo
            success "New Project finalizado."
            echo

            exit 0
            ;;

        *)

            warning "Opción no válida."
            sleep 1
            ;;

    esac

done