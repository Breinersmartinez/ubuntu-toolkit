# Changelog

Todos los cambios importantes de este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), y este proyecto sigue [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Added

* Próximas herramientas y funcionalidades del Ubuntu Toolkit.
* Mejoras en la integración entre los diferentes scripts.
* Nuevas opciones de automatización para Ubuntu y herramientas de desarrollo.

### Changed

* Mejoras de arquitectura y modularización.
* Mejoras en validaciones y manejo de errores.
* Mejoras en la experiencia de usuario de los menús interactivos.

### Security

* Revisión continua de operaciones potencialmente destructivas.
* Mantener las herramientas seguras por defecto.

---

## [0.1.0] - 2026-08-20

### Added

#### System Maintenance

* Añadido `maintenance.sh`.
* Diagnóstico básico del sistema.
* Información de Ubuntu, kernel, CPU, RAM y almacenamiento.
* Detección de procesos y locks de APT/Dpkg.
* Limpieza conservadora mediante `apt autoclean`.
* Verificación de paquetes mediante `dpkg --audit`.
* Configuración opcional de ajustes conservadores de memoria mediante `sysctl`.
* Verificación y habilitación de `fstrim.timer`.
* Verificación de ZRAM.
* Limpieza de archivos temporales mediante `systemd-tmpfiles`.
* Generación de logs de ejecución.
* Creación de backups antes de modificar configuraciones.
* Modo `--dry-run`.
* Confirmaciones para operaciones que modifican el sistema.

#### Git Workflow

* Añadido `git-workflow.sh`.
* Menú interactivo para tareas frecuentes de Git.
* Consulta del estado del repositorio.
* Visualización de cambios staged y unstaged.
* Añadir archivos al staging area.
* Creación de commits.
* Push hacia `origin`.
* Creación de nuevas ramas.
* Cambio entre ramas existentes.
* Actualización de ramas mediante `git pull --ff-only`.
* Visualización del historial reciente de commits.
* Consulta y configuración de identidad Git global.
* Consulta y configuración de identidad Git específica del repositorio.

#### SSH / GitHub

* Añadida generación de claves SSH ED25519.
* Solicitud interactiva del correo asociado a GitHub.
* Permite definir el nombre del archivo de la clave.
* Protección contra sobrescritura de claves SSH existentes.
* Configuración segura de permisos para claves privadas y públicas.
* Visualización del fingerprint de la clave.
* Visualización de información de la clave pública.
* Presentación de la clave pública lista para agregar a GitHub.
* Detección de `ssh-agent`.
* Opción para agregar la nueva clave al `ssh-agent`.
* Instrucciones para probar la conexión mediante `ssh -T git@github.com`.
* Nunca se muestra la clave privada en pantalla.

#### Project Generator

* Añadido `new-project.sh`.
* Generador interactivo de proyectos.
* Soporte inicial para Spring Boot.
* Soporte inicial para Python.
* Soporte inicial para Node.js.
* Soporte inicial para React.
* Soporte inicial para Vite.
* Soporte inicial para Tailwind CSS.
* Soporte inicial para Angular.
* Soporte para TypeScript.
* Selección interactiva de herramientas y propiedades según el stack.
* Creación automática de estructuras de proyecto.
* Creación automática de `.gitignore`.
* Creación automática de `README.md`.
* Inicialización opcional de repositorios Git.
* Detección de herramientas requeridas antes de generar proyectos.
* No sobrescribe proyectos existentes.
* Opción para abrir proyectos automáticamente con VS Code cuando está disponible.

### Security

* No se incluyen credenciales, tokens o claves privadas.
* Los scripts evitan operaciones destructivas por defecto.
* `maintenance.sh` no ejecuta `apt autoremove` automáticamente.
* `maintenance.sh` no modifica `/etc/fstab`.
* `maintenance.sh` no elimina configuraciones personales.
* `maintenance.sh` no elimina perfiles de aplicaciones.
* `git-workflow.sh` no ejecuta `git push --force`.
* `git-workflow.sh` no ejecuta `git reset --hard`.
* `git-workflow.sh` no ejecuta `git clean`.
* La generación de claves SSH no sobrescribe claves existentes.

### Documentation

* Añadida documentación inicial del proyecto.
* Definida la filosofía de seguridad del toolkit.
* Preparación del proyecto para futuras herramientas de administración y desarrollo.

---

## Versioning

### Major

Se incrementará la versión mayor cuando existan cambios incompatibles con versiones anteriores.

Ejemplo:

```text
1.x.x → 2.0.0
```

### Minor

Se incrementará la versión menor cuando se agreguen nuevas funcionalidades compatibles.

Ejemplo:

```text
0.1.0 → 0.2.0
```

### Patch

Se incrementará la versión de parche cuando se corrijan errores o se realicen mejoras pequeñas sin añadir funcionalidades importantes.

Ejemplo:

```text
0.2.0 → 0.2.1
```

---

## Changelog Categories

Las siguientes categorías se utilizarán cuando corresponda:

* **Added** — Nuevas funcionalidades.
* **Changed** — Cambios en funcionalidades existentes.
* **Deprecated** — Funcionalidades que serán eliminadas próximamente.
* **Removed** — Funcionalidades eliminadas.
* **Fixed** — Correcciones de errores.
* **Security** — Cambios relacionados con seguridad.
* **Documentation** — Cambios exclusivamente documentales.

---

## [Unreleased]: https://github.com/USERNAME/ubuntu-toolkit/compare/v0.1.0...HEAD

## [0.1.0]: https://github.com/USERNAME/ubuntu-toolkit/releases/tag/v0.1.0
