# Ubuntu Toolkit

> Colección modular de scripts Bash para automatizar tareas de administración, mantenimiento y desarrollo en Ubuntu.

Ubuntu Toolkit es un conjunto de herramientas personales y reutilizables para simplificar tareas repetitivas en sistemas Ubuntu.

El proyecto está diseñado bajo una filosofía de **Safe by Default**: los scripts deben evitar operaciones destructivas, proteger las configuraciones personales y solicitar confirmación cuando una operación pueda modificar significativamente el sistema.

---

## Características

* Mantenimiento seguro de Ubuntu
* Información y diagnóstico del sistema
* Gestión y limpieza de Docker
* Diagnóstico de red
* Backup de configuraciones
* Automatización de Git
* Generación de claves SSH para GitHub
* Creación automática de proyectos
* Conversión de TXT a Markdown
* Diagnóstico de almacenamiento
* Preparación de entornos de desarrollo
* Instalación e integración de OpenCode (agente de IA para desarrollo)
* Gestión de paquetes
* Herramientas de diagnóstico

---

## Filosofía

Ubuntu Toolkit sigue algunos principios fundamentales.

### Safe by Default

Los scripts deben priorizar la seguridad sobre la automatización agresiva.

Evitar automáticamente:

```text
rm -rf de directorios personales
git reset --hard
git clean -fd
git push --force
apt autoremove
eliminación de perfiles de aplicaciones
eliminación de configuraciones personales
modificación de /etc/fstab
eliminación de claves SSH
eliminación de datos Docker sin confirmación
```

### Reversible

Cuando un script modifica una configuración importante, debe intentar crear un backup antes.

### Transparente

Las operaciones importantes deben informar al usuario qué se va a modificar.

### Modular

Cada herramienta debe tener una responsabilidad clara y poder ejecutarse independientemente.

### Reutilizable

Los scripts no deben depender de rutas, nombres de usuario o configuraciones específicas de una máquina.

---

## Estructura del proyecto

```text
ubuntu-toolkit/
│
├── README.md
├── LICENSE
├── CONTRIBUTING.md
├── CHANGELOG.md
├── install.sh
│
├── bin/
│   └── ubuntu-toolkit
│
├── scripts/
│   │
│   ├── system/
│   │   ├── maintenance.sh
│   │   ├── system-info.sh
│   │   └── disk-check.sh
│   │
│   ├── docker/
│   │   ├── cleanup.sh
│   │   └── info.sh
│   │
│   ├── network/
│   │   └── network-check.sh
│   │
│   ├── backup/
│   │   └── backup-config.sh
│   │
│   ├── development/
│   │   ├── install-opencode.sh
│   │   ├── new-project.sh
│   │   └── dev-setup.sh
│   │
│   ├── git/
│   │   └── git-workflow.sh
│   │
│   └── utilities/
│       ├── txt2md.sh
│       └── downloads-cleanup.sh
│
├── lib/
│   ├── common.sh
│   ├── logging.sh
│   ├── apt.sh
│   └── backup.sh
│
├── config/
│   └── default.conf
│
├── tests/
│
└── docs/
    ├── installation.md
    ├── usage.md
    └── scripts.md
```

---

## Requisitos

Actualmente el proyecto está orientado principalmente a:

* Ubuntu 24.04 LTS
* Bash 5+
* Git

Algunas herramientas requieren dependencias adicionales dependiendo del script utilizado.

Por ejemplo:

```text
git
docker
python3
node
npm
java
curl
ssh-keygen
```

No todas las herramientas son necesarias para utilizar todo el proyecto.

---

## Instalación

Clonar el repositorio:

```bash
git clone https://github.com/USERNAME/ubuntu-toolkit.git
```

Entrar al proyecto:

```bash
cd ubuntu-toolkit
```

Dar permisos de ejecución:

```bash
chmod +x scripts/**/*.sh
```

También se puede ejecutar cada script directamente utilizando Bash:

```bash
bash scripts/system/maintenance.sh
```

---

## Mantenimiento de Ubuntu

Ejecutar:

```bash
sudo ./scripts/system/maintenance.sh
```

Los scripts de mantenimiento deben priorizar:

* Preservar configuraciones personales.
* No eliminar perfiles de aplicaciones.
* No modificar `/etc/fstab`.
* No modificar SSH.
* No eliminar Docker.
* No ejecutar `apt autoremove` automáticamente.
* Crear backups antes de modificar configuraciones importantes.
* Registrar las operaciones realizadas.

Cuando esté disponible, se recomienda utilizar un modo de simulación:

```bash
sudo ./scripts/system/maintenance.sh --dry-run
```

---

## Git Workflow

Entrar al repositorio donde se desea trabajar:

```bash
cd ~/Projects/mi-proyecto
```

Ejecutar:

```bash
~/ubuntu-toolkit/scripts/git/git-workflow.sh
```

El menú permite:

```text
1. Ver estado
2. Ver cambios
3. Añadir cambios
4. Crear commit
5. Push
6. Crear nueva rama
7. Cambiar de rama
8. Actualizar rama
9. Ver últimos commits
10. Ver/configurar identidad Git
11. Crear nueva clave SSH para GitHub
0. Salir
```

La herramienta evita operaciones potencialmente destructivas como:

```text
git reset --hard
git clean -fd
git push --force
git branch -D
```

---

## Generación de claves SSH

Desde `git-workflow.sh`:

```text
11. Crear nueva clave SSH para GitHub
```

El script solicita:

```text
Correo electrónico asociado a GitHub:
Nombre del archivo [id_ed25519_github]:
```

Utiliza el algoritmo ED25519.

Por ejemplo:

```text
~/.ssh/id_ed25519_github
~/.ssh/id_ed25519_github.pub
```

La clave privada:

```text
id_ed25519_github
```

nunca debe compartirse.

La clave pública:

```text
id_ed25519_github.pub
```

es la que debe agregarse a GitHub.

Para comprobar la conexión:

```bash
ssh -T git@github.com
```

---

## Creación de proyectos

Ejecutar:

```bash
./scripts/development/new-project.sh
```

El generador permite crear:

```text
1. Spring Boot
2. Python
3. Node.js
4. React + Vite + Tailwind
5. Angular + TypeScript
0. Salir
```

El objetivo es solicitar únicamente la información relevante para cada stack.

---

## Spring Boot

El generador permite configurar:

* Maven o Gradle
* Java o Kotlin
* Group ID
* Artifact ID
* Descripción
* Dependencias iniciales

Ejemplo:

```text
Spring Boot
├── Java
├── Maven
├── Spring Web
├── Spring Data JPA
├── PostgreSQL
└── Lombok
```

---

## Python

Permite configurar:

* Versión de Python
* Tipo de proyecto
* Entorno virtual
* Dependencias iniciales
* `requirements.txt`
* Directorio `src`
* Directorio `tests`
* `.gitignore`

Ejemplo:

```text
mi-proyecto/
├── .venv/
├── src/
│   └── main.py
├── tests/
├── requirements.txt
├── .gitignore
└── README.md
```

---

## Node.js

Permite seleccionar:

* JavaScript
* TypeScript
* npm
* pnpm
* yarn
* Dependencias iniciales

Ejemplo:

```text
mi-node-app/
├── src/
│   └── index.ts
├── package.json
├── .gitignore
└── README.md
```

---

## React + Vite + Tailwind

El generador utiliza Vite para crear el proyecto.

Permite seleccionar:

* JavaScript
* TypeScript

La configuración incluye:

```text
React
Vite
Tailwind CSS
```

Ejemplo:

```text
mi-dashboard/
├── public/
├── src/
├── package.json
├── vite.config.ts
├── .gitignore
└── README.md
```

---

## Angular + TypeScript

Permite configurar:

* Angular CLI
* TypeScript
* Routing
* CSS o SCSS

Ejemplo:

```text
mi-angular-app/
├── src/
├── angular.json
├── package.json
├── tsconfig.json
├── .gitignore
└── README.md
```

---

## OpenCode

OpenCode es un agente de IA interactivo para terminal enfocado en desarrollo de software y asistencia técnica.

### Ubicación del script

```text
scripts/development/install-opencode.sh
```

### Características del instalador

* Compatible con **Ubuntu 24.04 LTS**.
* Instalación a nivel de usuario en `~/.local/bin` (no requiere `sudo` para instalar el binario).
* Preserva configuraciones y no almacena credenciales ni API keys.
* Safe by default: no inicia automáticamente la herramienta tras la instalación.

### Cómo instalarlo desde Ubuntu Toolkit

Desde el menú interactivo:

```bash
./bin/ubuntu-toolkit
```

1. Seleccionar la opción **8) OpenCode**.
2. Elegir **1) Instalar OpenCode**.

O mediante comando directo:

```bash
./bin/ubuntu-toolkit opencode-install
```

### Cómo verificar la instalación

Desde el submenú de OpenCode:

1. Seleccionar **2) Verificar instalación** para comprobar existencia, versión, ubicación y estado en PATH.
2. Seleccionar **3) Mostrar versión** para ejecutar `opencode --version`.
3. Seleccionar **4) Ver ubicación** para ejecutar `command -v opencode`.

O directamente desde la CLI:

```bash
./bin/ubuntu-toolkit opencode-check
./bin/ubuntu-toolkit opencode-version
./bin/ubuntu-toolkit opencode-location
```

---

## Docker

Las herramientas Docker están orientadas a ayudar a controlar el almacenamiento y los recursos utilizados por Docker.

Ejemplo:

```bash
./scripts/docker/cleanup.sh
```

Antes de eliminar recursos, el script debe mostrar qué se va a eliminar y solicitar confirmación.

Se busca evitar eliminar accidentalmente:

```text
Contenedores en ejecución
Volúmenes utilizados
Imágenes necesarias
```

---

## Diagnóstico de almacenamiento

Las herramientas de almacenamiento permiten identificar qué está consumiendo espacio.

Ejemplo:

```bash
./scripts/system/disk-check.sh
```

El análisis puede incluir:

```text
/
├── /home
├── /var
├── /var/lib/docker
├── /var/log
└── otros directorios
```

---

## Diagnóstico de red

Ejecutar:

```bash
./scripts/network/network-check.sh
```

La herramienta puede comprobar:

```text
Interfaz de red
Dirección IP
Gateway
DNS
Conectividad IPv4
Conectividad IPv6
Resolución DNS
Latencia
```

---

## Backups

Las herramientas que modifican configuraciones importantes deben crear backups antes de realizar cambios.

Los backups deben almacenarse fuera del repositorio.

Ejemplo:

```text
~/ubuntu-toolkit-backups/
```

Nunca se deben subir backups personales al repositorio.

---

## Seguridad

Ubuntu Toolkit no está diseñado para reemplazar herramientas profesionales de administración de sistemas.

Antes de ejecutar cualquier script que modifique el sistema:

1. Leer la documentación.
2. Revisar el código.
3. Ejecutar `--dry-run` cuando esté disponible.
4. Mantener backups importantes.
5. Confirmar las operaciones destructivas.

Nunca ejecutes scripts obtenidos de Internet con `sudo` sin revisar primero su contenido.

---

## Testing

Antes de ejecutar un script:

```bash
bash -n script.sh
```

Esto permite detectar errores básicos de sintaxis.

Si ShellCheck está instalado:

```bash
shellcheck script.sh
```

Ejemplo:

```bash
shellcheck scripts/system/maintenance.sh
```

Para ejecutar todos los análisis:

```bash
find scripts -type f -name "*.sh" -print0 | xargs -0 -n1 shellcheck
```

---

## Estado del proyecto

| Herramienta         | Estado        |
| ------------------- | ------------- |
| Safe Maintenance    | En desarrollo |
| Git Workflow        | En desarrollo |
| SSH Key Generator   | En desarrollo |
| New Project         | En desarrollo |
| OpenCode Installer  | Disponible    |
| Docker Cleanup      | Planeado      |
| Docker Info         | Planeado      |
| System Info         | Planeado      |
| Disk Check          | Planeado      |
| Network Check       | Planeado      |
| Config Backup       | Planeado      |
| Dev Setup           | Planeado      |
| TXT → Markdown      | Planeado      |
| Downloads Cleanup   | Planeado      |
| CLI principal       | En desarrollo |
| Tests automatizados | Planeado      |

---

## Roadmap

### v0.1.x — Foundation

* [x] Safe Maintenance
* [x] Git Workflow
* [x] SSH Key Generator
* [x] New Project
* [ ] Common library
* [ ] Logging library
* [ ] ShellCheck
* [ ] `.gitignore`
* [ ] Documentación inicial

### v0.2.x — System Tools

* [ ] System Info
* [ ] Disk Check
* [ ] Network Check
* [ ] Package Manager
* [ ] Backup Manager

### v0.3.x — Development

* [ ] Dev Setup
* [ ] Project Templates
* [ ] Python templates
* [ ] Node.js templates
* [ ] Spring Boot templates
* [ ] React templates
* [ ] Angular templates

### v0.4.x — Docker

* [ ] Docker Info
* [ ] Docker Cleanup
* [ ] Docker Disk Analysis
* [ ] Docker backup utilities

### v1.0.0 — CLI

Objetivo:

```bash
ubuntu-toolkit
```

Con un menú centralizado:

```text
+--------------------------------------+
|            UBUNTU TOOLKIT            |
+--------------------------------------+
| 1. System                            |
| 2. Docker                            |
| 3. Network                           |
| 4. Backup                            |
| 5. Development                       |
| 6. Git                               |
| 7. Utilities                         |
| 8. OpenCode                          |
| 0. Exit                              |
+--------------------------------------+
```

---

## Contribuciones

Las contribuciones son bienvenidas.

Antes de enviar un Pull Request:

```bash
bash -n script.sh
shellcheck script.sh
```

Además:

* Evita operaciones destructivas por defecto.
* No incluyas información personal.
* No incluyas contraseñas.
* No incluyas tokens.
* No incluyas claves privadas.
* Documenta nuevas opciones.
* Mantén los scripts modulares.
* Utiliza nombres descriptivos.
* Añade validaciones para comandos requeridos.

---

## Licencia

Este proyecto está distribuido bajo la licencia MIT.

Consulta [`LICENSE`](LICENSE) para más información.

---

## Autor

**Breiner**

Proyecto personal de herramientas Bash para Ubuntu, automatización Linux y desarrollo de software.

---

## Disclaimer

Este proyecto se proporciona "as is", sin garantías.

Aunque los scripts están diseñados siguiendo una filosofía de seguridad y prevención de operaciones destructivas, siempre debes revisar el código antes de ejecutar herramientas con privilegios de administrador.

Especialmente:

```bash
sudo ./script.sh
```

debe utilizarse únicamente después de entender qué operaciones realizará el script.
